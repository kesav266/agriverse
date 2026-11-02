from functools import lru_cache
from datetime import datetime, timezone
from io import BytesIO
from pathlib import Path
import threading
import uuid

from PIL import Image, UnidentifiedImageError

from app.core.config import settings
from app.core.exceptions import AgriVerseException
from app.models.schemas import DiagnosisResponse

_MODEL_LOCK = threading.Lock()


def disease_model_configured() -> bool:
    """Report model readiness only when weights and an explicit label allow-list exist."""
    model_path = settings.DISEASE_MODEL_PATH
    return bool(
        model_path
        and Path(model_path).is_file()
        and any(label.strip() for label in settings.DISEASE_ALLOWED_LABELS)
    )


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
            name, confidence = "Uncertain — no supported disease detected", None
        else:
            result = predictions[0]
            boxes = result.boxes
            if boxes is None or len(boxes) == 0:
                name, confidence = "Uncertain — no supported disease detected", None
            else:
                scores = boxes.conf.detach().cpu().tolist()
                classes = boxes.cls.detach().cpu().tolist()
                index = max(range(len(scores)), key=scores.__getitem__)
                confidence = float(scores[index])
                if confidence < settings.DISEASE_MODEL_CONFIDENCE:
                    name = "Uncertain — model confidence below the configured threshold"
                    confidence = None
                else:
                    class_id = int(classes[index])
                    names = result.names
                    name = str(names[class_id] if isinstance(names, dict) else names[class_id])
    except ImportError:
        raise AgriVerseException(
            "The YOLO runtime is missing. Install backend/requirements-ml.txt to enable diagnosis.",
            status_code=503,
            error_code="DISEASE_RUNTIME_NOT_INSTALLED",
        )
    except AgriVerseException:
        raise
    except Exception as exc:
        # Do not echo model paths, image bytes, or provider internals to the client.
        from app.core.logging import logger
        logger.error("Crop-disease model inference failed; exception_type=%s", type(exc).__name__)
        raise AgriVerseException(
            "Crop diagnosis failed. No disease result was produced.",
            status_code=503,
            error_code="DISEASE_INFERENCE_FAILED",
        )

    allowed_labels = {label.strip().casefold() for label in settings.DISEASE_ALLOWED_LABELS if label.strip()}
    if not name.startswith("Uncertain") and name.casefold() not in allowed_labels:
        name = "Uncertain — model class is not in the configured label allow-list"
        confidence = None

    caution_en = "This model output is a screening aid, not a confirmed diagnosis. Ask a local agricultural officer to inspect uncertain or serious symptoms. Do not apply chemicals based on this result alone; follow the registered product label."
    caution_te = "ఈ మోడల్ ఫలితం ప్రాథమిక పరిశీలన మాత్రమే; నిర్ధారిత రోగ నిర్ధారణ కాదు. అనిశ్చితి లేదా తీవ్రమైన లక్షణాలుంటే స్థానిక వ్యవసాయ అధికారిని సంప్రదించండి. ఈ ఫలితం ఆధారంగా మాత్రమే రసాయనాలు వాడకండి; అనుమతించిన ఉత్పత్తి లేబుల్‌ను అనుసరించండి."
    return DiagnosisResponse(
        id=str(uuid.uuid4()),
        farmer_id=farmer_id,
        crop_name=crop_name,
        detected_disease=name,
        severity="Uncertain",
        confidence_score=confidence,
        recommended_treatment_en=caution_en,
        recommended_treatment_te=caution_te,
        inference_engine="YOLO",
        diagnosed_at=datetime.now(timezone.utc),
        needs_expert_review=True,
    )
