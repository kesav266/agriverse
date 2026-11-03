"""Train a PlantVillage YOLO classification model and emit verified runtime configuration."""

import argparse
import json
from pathlib import Path
from shutil import copy2

BACKEND_ROOT = Path(__file__).resolve().parent
DEFAULT_DATASET = BACKEND_ROOT / "datasets" / "PlantVillage" / "classification"
MODELS_ROOT = BACKEND_ROOT / "models"
MODEL_PATH = MODELS_ROOT / "crop_disease.pt"
LABELS_PATH = MODELS_ROOT / "crop_disease_labels.json"
ENV_SNIPPET_PATH = MODELS_ROOT / "crop_disease.env"


def choose_hardware() -> tuple[str, int]:
    import torch

    if torch.cuda.is_available():
        return "0", -1
    if getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
        return "mps", 8
    return "cpu", 8


def model_labels(model) -> list[str]:
    names = model.names
    ordered_names = names.values() if isinstance(names, dict) else names
    labels = [str(label) for label in ordered_names]
    if not labels or any(not label.strip() for label in labels):
        raise RuntimeError("Trained model does not expose valid class names.")
    return labels


def write_env_configuration(model_path: Path, labels: list[str], env_path: Path) -> None:
    path_value = model_path.resolve().as_posix()
    configuration = (
        f"DISEASE_MODEL_PATH={path_value}\n"
        f"DISEASE_ALLOWED_LABELS={json.dumps(labels)}\n"
    )
    ENV_SNIPPET_PATH.write_text(configuration, encoding="utf-8")
    if not env_path.exists():
        raise RuntimeError(f"Requested environment file does not exist: {env_path}")

    existing_lines = env_path.read_text(encoding="utf-8").splitlines()
    replacements = {
        "DISEASE_MODEL_PATH": f"DISEASE_MODEL_PATH={path_value}",
        "DISEASE_ALLOWED_LABELS": f"DISEASE_ALLOWED_LABELS={json.dumps(labels)}",
    }
    updated_lines: list[str] = []
    seen_keys: set[str] = set()
    for line in existing_lines:
        key = line.split("=", 1)[0].strip()
        if key in replacements:
            updated_lines.append(replacements[key])
            seen_keys.add(key)
        else:
            updated_lines.append(line)
    updated_lines.extend(replacements[key] for key in replacements if key not in seen_keys)
    env_path.write_text("\n".join(updated_lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, default=DEFAULT_DATASET)
    parser.add_argument("--epochs", type=int, default=30)
    parser.add_argument("--imgsz", type=int, default=224)
    parser.add_argument("--batch", default="auto", help="auto, -1, or a positive batch size")
    parser.add_argument("--configure-env", type=Path, help="Explicitly update this .env after training")
    parser.add_argument(
        "--configure-existing",
        action="store_true",
        help="Generate labels/configuration from an existing reviewed crop_disease.pt without training",
    )
    parser.add_argument("--overwrite", action="store_true", help="Replace backend/models/crop_disease.pt")
    args = parser.parse_args()

    try:
        from ultralytics import YOLO
    except ImportError as exc:
        raise RuntimeError("Install backend/requirements.txt before training.") from exc

    if args.configure_existing:
        if not MODEL_PATH.is_file():
            parser.error(f"No trained model found at {MODEL_PATH}.")
        if not args.configure_env:
            parser.error("--configure-existing requires --configure-env <path-to-.env>.")
        labels = model_labels(YOLO(str(MODEL_PATH)))
        LABELS_PATH.write_text(json.dumps(labels, indent=2), encoding="utf-8")
        write_env_configuration(MODEL_PATH, labels, args.configure_env)
        print(f"Verified labels: {LABELS_PATH}")
        print(f"Updated runtime configuration: {args.configure_env}")
        return

    if not (args.data / "train").is_dir() or not (args.data / "val").is_dir():
        parser.error("Prepared classification data must contain train/ and val/ class directories.")
    if args.epochs != 30 or args.imgsz != 224:
        parser.error("This project requires --epochs 30 and --imgsz 224 for the PlantVillage baseline.")
    if MODEL_PATH.exists() and not args.overwrite:
        parser.error(f"{MODEL_PATH} already exists; use --overwrite only after reviewing the new model.")

    device, automatic_batch = choose_hardware()
    batch = automatic_batch if args.batch == "auto" else int(args.batch)
    if batch == 0 or batch < -1:
        parser.error("--batch must be auto, -1, or a positive integer.")

    MODELS_ROOT.mkdir(parents=True, exist_ok=True)
    model = YOLO("yolo26n-cls.pt")
    model.train(
        data=str(args.data),
        epochs=30,
        imgsz=224,
        batch=batch,
        device=device,
        project=str(MODELS_ROOT),
        name="crop_disease_training",
        exist_ok=True,
    )
    best_weights = MODELS_ROOT / "crop_disease_training" / "weights" / "best.pt"
    if not best_weights.is_file():
        raise RuntimeError(f"Training completed without best weights at {best_weights}")

    copy2(best_weights, MODEL_PATH)
    trained_model = YOLO(str(MODEL_PATH))
    labels = model_labels(trained_model)
    LABELS_PATH.write_text(json.dumps(labels, indent=2), encoding="utf-8")
    ENV_SNIPPET_PATH.write_text(
        f"DISEASE_MODEL_PATH={MODEL_PATH.resolve().as_posix()}\n"
        f"DISEASE_ALLOWED_LABELS={json.dumps(labels)}\n",
        encoding="utf-8",
    )
    if args.configure_env:
        write_env_configuration(MODEL_PATH, labels, args.configure_env)

    print(f"Best model: {MODEL_PATH}")
    print(f"Verified labels: {LABELS_PATH}")
    print(f"Runtime configuration snippet: {ENV_SNIPPET_PATH}")


if __name__ == "__main__":
    main()
