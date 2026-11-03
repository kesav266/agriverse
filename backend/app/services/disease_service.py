from datetime import datetime, timezone
from functools import lru_cache
from io import BytesIO
from pathlib import Path
import threading
import uuid

from PIL import Image, UnidentifiedImageError

from app.core.config import settings
from app.core.exceptions import AgriVerseException
from app.core.logging import logger
from app.models.schemas import DiagnosisResponse, DiseasePrediction

_MODEL_LOCK = threading.Lock()
_CAUTION_EN = (
    "This model output is a screening aid, not a confirmed diagnosis. Ask a local agricultural "
    "officer to inspect uncertain or serious symptoms. Do not apply chemicals based on this result "
    "alone; follow the registered product label."
)
_CAUTION_TE = (
    "ఈ మోడల్ ఫలితం ప్రాథమిక పరిశీలన మాత్రమే; నిర్ధారిత రోగ నిర్ధారణ కాదు. అనిశ్చిత లేదా "
    "తీవ్రమైన లక్షణాలుంటే స్థానిక వ్యవసాయ అధికారిని సంప్రదించండి. ఈ ఫలితం ఆధారంగా మాత్రమే "
    "రసాయనాలు వాడకండి; అనుమతించిన ఉత్పత్తి లేబుల్‌ను అనుసరించండి."
)


def disease_model_configured() -> bool:
    """Report whether configured weights and an explicit label allow-list are present."""
    model_path = settings.DISEASE_MODEL_PATH
    return bool(
        model_path
        and Path(model_path).is_file()
        and any(label.strip() for label in settings.DISEASE_ALLOWED_LABELS)
    )


def preload_disease_model() -> bool:
    """Load a configured model during startup without disabling unrelated API features."""
    if not disease_model_configured():
        return False

    try:
        _load_model(str(Path(settings.DISEASE_MODEL_PATH).resolve()))
        return True
    except ImportError:
        logger.warning("Crop-disease model is configured but the YOLO runtime is unavailable")
    except Exception as exc:
        logger.error("Crop-disease model preload failed; exception_type=%s", type(exc).__name__)
    return False


def validate_crop_image(data: bytes, content_type: str | None) -> Image.Image:
    if not data:
        raise AgriVerseException("Select a crop image to continue.", 422, "IMAGE_REQUIRED")
    if len(data) > settings.MAX_UPLOAD_BYTES:
        raise AgriVerseException("Image exceeds the configured upload limit.", 413, "IMAGE_TOO_LARGE")

    signatures = {
        "image/jpeg": data.startswith(b"\xff\xd8\xff"),
        "image/png": data.startswith(b"\x89PNG\r\n\x1a\n"),
        "image/webp": data.startswith(b"RIFF") and data[8:12] == b"WEBP",
    }
    if content_type not in signatures or not signatures[content_type]:
        raise AgriVerseException(
            "Upload a valid JPEG, PNG, or WebP image.",
            status_code=415,
            error_code="UNSUPPORTED_IMAGE",
        )

    try:
        image = Image.open(BytesIO(data))
        image.verify()
        image = Image.open(BytesIO(data))
        if image.width < 32 or image.height < 32 or image.width * image.height > 40_000_000:
            raise AgriVerseException(
                "Image dimensions are outside the supported range.",
                status_code=422,
                error_code="INVALID_IMAGE_DIMENSIONS",
            )
        image.load()
        return image.convert("RGB")
    except AgriVerseException:
        raise
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError):
        raise AgriVerseException(
            "The uploaded file is not a readable image.",
            status_code=415,
            error_code="INVALID_IMAGE",
        )


@lru_cache(maxsize=1)
def _load_model(model_path: str):
    from ultralytics import YOLO

    return YOLO(model_path)


def _tensor_values(value) -> list:
    if value is None:
        return []
    for method_name in ("detach", "cpu"):
        method = getattr(value, method_name, None)
        if callable(method):
            value = method()
    tolist = getattr(value, "tolist", None)
    if callable(tolist):
        value = tolist()
    return list(value) if isinstance(value, (list, tuple)) else [value]


def _class_name(names, class_id: int) -> str:
    return str(names[class_id])


def _configured_labels() -> set[str]:
    return {
        label.strip().casefold()
        for label in settings.DISEASE_ALLOWED_LABELS
        if label.strip()
    }


def _classification_predictions(result) -> list[DiseasePrediction]:
    probabilities = getattr(result, "probs", None)
    if probabilities is None:
        return []

    class_ids = [int(value) for value in _tensor_values(getattr(probabilities, "top5", None))]
    confidences = [float(value) for value in _tensor_values(getattr(probabilities, "top5conf", None))]
    if not class_ids or len(class_ids) != len(confidences):
        raise ValueError("Classification result does not contain aligned top predictions")

    return [
        DiseasePrediction(label=_class_name(result.names, class_id), confidence=confidence)
        for class_id, confidence in zip(class_ids, confidences)
    ]


def _response(
    *,
    crop_name: str,
    farmer_id: str,
    name: str,
    confidence: float | None,
    top_predictions: list[DiseasePrediction],
    inference_engine: str,
) -> DiagnosisResponse:
    return DiagnosisResponse(
        id=str(uuid.uuid4()),
        farmer_id=farmer_id,
        crop_name=crop_name,
        detected_disease=name,
        severity="Uncertain",
        confidence_score=confidence,
        top_predictions=top_predictions,
        recommended_treatment_en=_CAUTION_EN,
        recommended_treatment_te=_CAUTION_TE,
        inference_engine=inference_engine,
        diagnosed_at=datetime.now(timezone.utc),
        needs_expert_review=True,
    )


def _classification_response(result, crop_name: str, farmer_id: str) -> DiagnosisResponse:
    predictions = _classification_predictions(result)
    if not predictions:
        return _response(
            crop_name=crop_name,
            farmer_id=farmer_id,
            name="Uncertain — no supported disease detected",
            confidence=None,
            top_predictions=[],
            inference_engine="YOLO classification",
        )

    allowed_labels = _configured_labels()
    predicted = predictions[0]
    allowed_predictions = [
        prediction for prediction in predictions if prediction.label.casefold() in allowed_labels
    ]
    if predicted.label.casefold() not in allowed_labels:
        return _response(
            crop_name=crop_name,
            farmer_id=farmer_id,
            name="Uncertain — model class is not in the configured label allow-list",
            confidence=None,
            top_predictions=[],
            inference_engine="YOLO classification",
        )
    if predicted.confidence < settings.DISEASE_MODEL_CONFIDENCE:
        return _response(
            crop_name=crop_name,
            farmer_id=farmer_id,
            name="Uncertain — model confidence below the configured threshold",
            confidence=None,
            top_predictions=allowed_predictions,
            inference_engine="YOLO classification",
        )
    return _response(
        crop_name=crop_name,
        farmer_id=farmer_id,
        name=predicted.label,
        confidence=predicted.confidence,
        top_predictions=allowed_predictions,
        inference_engine="YOLO classification",
    )


def _detection_response(result, crop_name: str, farmer_id: str) -> DiagnosisResponse:
    boxes = getattr(result, "boxes", None)
    if boxes is None or len(boxes) == 0:
        return _response(
            crop_name=crop_name,
            farmer_id=farmer_id,
            name="Uncertain — no supported disease detected",
            confidence=None,
            top_predictions=[],
            inference_engine="YOLO detection",
        )

    scores = boxes.conf.detach().cpu().tolist()
    classes = boxes.cls.detach().cpu().tolist()
    index = max(range(len(scores)), key=scores.__getitem__)
    confidence = float(scores[index])
    name = _class_name(result.names, int(classes[index]))
    if name.casefold() not in _configured_labels():
        name, confidence = "Uncertain — model class is not in the configured label allow-list", None
    elif confidence < settings.DISEASE_MODEL_CONFIDENCE:
        name, confidence = "Uncertain — model confidence below the configured threshold", None
    return _response(
        crop_name=crop_name,
        farmer_id=farmer_id,
        name=name,
        confidence=confidence,
        top_predictions=[],
        inference_engine="YOLO detection",
    )


def diagnose_image(data: bytes, content_type: str | None, crop_name: str, farmer_id: str) -> DiagnosisResponse:
    image = validate_crop_image(data, content_type)
    model_path = settings.DISEASE_MODEL_PATH
    if not model_path:
        raise AgriVerseException(
            "Crop diagnosis is unavailable until DISEASE_MODEL_PATH points to a trained YOLO model.",
            status_code=503,
            error_code="DISEASE_MODEL_NOT_CONFIGURED",
        )
    if not Path(model_path).is_file():
        raise AgriVerseException(
            "The configured crop-disease model file could not be found.",
            status_code=503,
            error_code="DISEASE_MODEL_NOT_FOUND",
        )

    try:
        with _MODEL_LOCK:
            model = _load_model(str(Path(model_path).resolve()))
            predictions = model.predict(source=image, verbose=False)
        if not predictions:
            return _response(
                crop_name=crop_name,
                farmer_id=farmer_id,
                name="Uncertain — no supported disease detected",
                confidence=None,
                top_predictions=[],
                inference_engine="YOLO",
            )
        result = predictions[0]
        if getattr(result, "probs", None) is not None:
            return _classification_response(result, crop_name, farmer_id)
        return _detection_response(result, crop_name, farmer_id)
    except ImportError:
        raise AgriVerseException(
            "The YOLO runtime is missing. Install backend/requirements-ml.txt to enable diagnosis.",
            status_code=503,
            error_code="DISEASE_RUNTIME_NOT_INSTALLED",
        )
    except AgriVerseException:
        raise
    except Exception as exc:
        logger.error("Crop-disease model inference failed; exception_type=%s", type(exc).__name__)
        raise AgriVerseException(
            "Crop diagnosis failed. No disease result was produced.",
            status_code=503,
            error_code="DISEASE_INFERENCE_FAILED",
        )
