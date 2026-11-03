"""Download PlantVillage once and prepare a leakage-safe YOLO classification split."""

import argparse
import hashlib
import json
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from random import Random
from shutil import copy2, copytree

DATASET_HANDLE = "emmarex/plantdisease"
IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
BACKEND_ROOT = Path(__file__).resolve().parent
DATASET_ROOT = BACKEND_ROOT / "datasets" / "PlantVillage"
SOURCE_ROOT = DATASET_ROOT / "source"
CLASSIFICATION_ROOT = DATASET_ROOT / "classification"
MANIFEST_PATH = DATASET_ROOT / "manifest.json"


def is_image(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES


def image_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as image_file:
        for chunk in iter(lambda: image_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_source() -> Path:
    if SOURCE_ROOT.exists() and any(SOURCE_ROOT.iterdir()):
        try:
            find_class_root(SOURCE_ROOT)
            return SOURCE_ROOT
        except RuntimeError:
            pass

    try:
        import kagglehub
    except ImportError as exc:
        raise RuntimeError("Install backend/requirements.txt before downloading PlantVillage.") from exc

    SOURCE_ROOT.mkdir(parents=True, exist_ok=True)
    downloaded_path = Path(kagglehub.dataset_download(DATASET_HANDLE))
    copied_dataset = SOURCE_ROOT / "downloaded"
    if copied_dataset.exists():
        raise RuntimeError(
            f"Downloaded dataset directory already exists but has no detected class folders: {copied_dataset}"
        )
    copytree(downloaded_path, copied_dataset)
    return SOURCE_ROOT


def find_class_root(source_root: Path) -> Path:
    candidates: list[tuple[int, Path]] = []
    for directory in [source_root, *source_root.rglob("*")]:
        if not directory.is_dir():
            continue
        class_directories = [child for child in directory.iterdir() if child.is_dir()]
        image_class_count = sum(
            1 for child in class_directories if any(is_image(item) for item in child.iterdir())
        )
        if image_class_count:
            candidates.append((image_class_count, directory))
    if not candidates:
        raise RuntimeError("Could not find PlantVillage class folders containing images.")
    return max(candidates, key=lambda item: item[0])[1]


def collect_class_images(class_root: Path) -> dict[str, list[Path]]:
    classes: dict[str, list[Path]] = {}
    for class_directory in sorted(path for path in class_root.iterdir() if path.is_dir()):
        images = sorted(path for path in class_directory.rglob("*") if is_image(path))
        if images:
            classes[class_directory.name] = images
    if len(classes) < 2:
        raise RuntimeError("PlantVillage must contain at least two non-empty class directories.")
    return classes


def prepare_split(
    class_images: dict[str, list[Path]],
    validation_fraction: float,
    seed: int,
) -> dict:
    if CLASSIFICATION_ROOT.exists():
        raise RuntimeError(
            f"Generated split already exists at {CLASSIFICATION_ROOT}. Remove it manually only when "
            "you intentionally want to rebuild; source images are never removed by this script."
        )

    assignments: dict[str, str] = {}
    copied_hashes: dict[tuple[str, str], set[str]] = defaultdict(set)
    split_counts: dict[str, dict[str, int]] = {"train": {}, "val": {}}
    duplicate_count = 0

    for class_name, images in class_images.items():
        grouped_images: dict[str, list[Path]] = defaultdict(list)
        for image_path in images:
            grouped_images[image_hash(image_path)].append(image_path)
        duplicate_count += sum(len(group) - 1 for group in grouped_images.values())

        groups = list(grouped_images.items())
        Random(f"{seed}:{class_name}").shuffle(groups)
        target_validation_count = max(1, round(len(images) * validation_fraction))
        validation_count = 0

        for group_index, (digest, duplicate_images) in enumerate(groups):
            split = assignments.get(digest)
            if split is None:
                group_size = len(duplicate_images)
                remaining_groups = len(groups) - group_index - 1
                needs_validation = validation_count < target_validation_count
                closer_to_target = abs(validation_count + group_size - target_validation_count) <= abs(
                    validation_count - target_validation_count
                )
                split = "val" if needs_validation and (closer_to_target or remaining_groups == 0) else "train"
                assignments[digest] = split
            if split == "val":
                validation_count += len(duplicate_images)

            destination = CLASSIFICATION_ROOT / split / class_name
            destination.mkdir(parents=True, exist_ok=True)
            for source_path in duplicate_images:
                if digest in copied_hashes[(split, class_name)]:
                    continue
                filename = f"{source_path.stem}__{digest[:12]}{source_path.suffix.lower()}"
                copy2(source_path, destination / filename)
                copied_hashes[(split, class_name)].add(digest)

    for split in ("train", "val"):
        for class_name in class_images:
            split_counts[split][class_name] = len(
                [path for path in (CLASSIFICATION_ROOT / split / class_name).iterdir() if is_image(path)]
            )
            if split_counts[split][class_name] == 0:
                raise RuntimeError(f"Class {class_name!r} has no images in the {split} split.")

    return {
        "dataset": DATASET_HANDLE,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "class_names": sorted(class_images),
        "validation_fraction": validation_fraction,
        "seed": seed,
        "split_counts": split_counts,
        "duplicate_source_images_not_copied": duplicate_count,
        "classification_root": str(CLASSIFICATION_ROOT),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--validation-fraction", type=float, default=0.2)
    parser.add_argument("--seed", type=int, default=2026)
    args = parser.parse_args()
    if not 0 < args.validation_fraction < 1:
        parser.error("--validation-fraction must be between 0 and 1.")
    if MANIFEST_PATH.exists() and CLASSIFICATION_ROOT.exists():
        print(f"PlantVillage is already prepared: {CLASSIFICATION_ROOT}")
        return

    source_root = download_source()
    class_root = find_class_root(source_root)
    class_images = collect_class_images(class_root)
    manifest = prepare_split(class_images, args.validation_fraction, args.seed)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"PlantVillage source: {source_root}")
    print(f"Detected class root: {class_root}")
    print(f"Prepared {len(manifest['class_names'])} classes at: {CLASSIFICATION_ROOT}")


if __name__ == "__main__":
    main()
