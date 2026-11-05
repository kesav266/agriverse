"""Download PlantVillage once and prepare a leakage-safe YOLO classification split."""

import argparse
import hashlib
import json
import re
import time
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from random import Random
from shutil import copy2

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

    cached_source = _completed_cached_source()
    if cached_source is not None:
        return cached_source

    try:
        import kagglehub
    except ImportError as exc:
        raise RuntimeError("Install backend/requirements.txt before downloading PlantVillage.") from exc

    # KaggleHub may leave a partial archive in its cache after a network failure.
    # Its normal cache lookup resumes an incomplete transfer; later forced attempts
    # bypass a stale completed-cache marker. Never copy an archive or a partially
    # extracted tree into SOURCE_ROOT and mistake it for the dataset.
    attempts = 3
    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        try:
            downloaded_path = Path(
                kagglehub.dataset_download(DATASET_HANDLE, force_download=attempt > 1)
            )
            class_root = find_class_root(downloaded_path)
            collect_class_images(class_root)
            return downloaded_path
        except Exception as exc:
            last_error = exc
            if attempt < attempts:
                delay = 2 ** (attempt - 1)
                print(
                    f"PlantVillage download/validation attempt {attempt}/{attempts} failed "
                    f"({type(exc).__name__}); retrying in {delay}s."
                )
                time.sleep(delay)

    raise RuntimeError(
        f"PlantVillage was not downloaded and validated after {attempts} attempts "
        f"({type(last_error).__name__ if last_error else 'unknown error'}). "
        "Check Kaggle access/authentication and network connectivity. Existing partial "
        "files were left untouched; no dataset manifest was written."
    ) from last_error


def _completed_cached_source() -> Path | None:
    """Use a complete KaggleHub cache offline when its marker and contents validate."""
    try:
        from kagglehub.cache import Cache
        from kagglehub.config import get_cache_folder
        from kagglehub.handle import parse_dataset_handle
    except ImportError:
        return None

    owner, dataset_name = DATASET_HANDLE.split("/", 1)
    dataset_cache = Path(get_cache_folder()) / "datasets" / owner / dataset_name
    versions = sorted(
        (int(marker.stem), marker)
        for marker in dataset_cache.glob("*.complete")
        if marker.stem.isdigit()
    )
    cache = Cache()
    for version, _ in reversed(versions):
        handle = parse_dataset_handle(f"{DATASET_HANDLE}/versions/{version}")
        cached_path = cache.load_from_cache(handle)
        if not cached_path:
            continue
        try:
            class_root = find_class_root(Path(cached_path))
            collect_class_images(class_root)
            return Path(cached_path)
        except RuntimeError:
            continue
    return None


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
    return max(candidates, key=lambda item: (item[0], len(item[1].parts)))[1]


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


def validate_prepared_split(manifest: dict) -> None:
    """Check generated class counts and that duplicate image hashes stay in one split."""
    expected_classes = set(manifest["class_names"])
    split_hashes: dict[str, set[str]] = {"train": set(), "val": set()}
    for split in ("train", "val"):
        split_root = CLASSIFICATION_ROOT / split
        actual_classes = {path.name for path in split_root.iterdir() if path.is_dir()}
        if actual_classes != expected_classes:
            raise RuntimeError(f"The {split} split class directories do not match the manifest.")
        for class_name in expected_classes:
            class_dir = split_root / class_name
            images = [path for path in class_dir.iterdir() if is_image(path)]
            if len(images) != manifest["split_counts"][split].get(class_name):
                raise RuntimeError(
                    f"The {split} image count for class {class_name!r} does not match the manifest."
                )
            for image_path in images:
                suffix = image_path.stem.rsplit("__", 1)[-1]
                if not re.fullmatch(r"[0-9a-f]{12}", suffix):
                    raise RuntimeError(f"Generated image has no source hash suffix: {image_path.name}")
                split_hashes[split].add(suffix)
    if split_hashes["train"] & split_hashes["val"]:
        raise RuntimeError("Duplicate image hashes were found in both train and validation splits.")


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
    validate_prepared_split(manifest)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"PlantVillage source: {source_root}")
    print(f"Detected class root: {class_root}")
    print(f"Prepared {len(manifest['class_names'])} classes at: {CLASSIFICATION_ROOT}")


if __name__ == "__main__":
    main()
