import hashlib
from pathlib import Path
import shutil
from types import SimpleNamespace
from uuid import uuid4

import pytest

import download_dataset as dataset


@pytest.fixture
def local_tmp_path():
    path = Path(__file__).resolve().parent / f".dataset-test-tmp-{uuid4().hex}"
    path.mkdir()
    try:
        yield path
    finally:
        shutil.rmtree(path)


def _write_class_images(root: Path) -> None:
    for class_name in ("class_a", "class_b"):
        class_dir = root / class_name
        class_dir.mkdir(parents=True)
        for index in range(4):
            (class_dir / f"image_{index}.jpg").write_bytes(
                f"{class_name}:{index}".encode()
            )


def test_split_is_deterministic_and_does_not_leak_duplicate_bytes(local_tmp_path, monkeypatch):
    class_root = local_tmp_path / "classes"
    class_root.mkdir()
    _write_class_images(class_root)
    # The same image content can appear under different class labels in source data.
    (class_root / "class_b" / "duplicate.jpg").write_bytes(b"shared image")
    (class_root / "class_a" / "duplicate.jpg").write_bytes(b"shared image")
    monkeypatch.setattr(dataset, "CLASSIFICATION_ROOT", local_tmp_path / "classification")

    classes = dataset.collect_class_images(class_root)
    manifest = dataset.prepare_split(classes, validation_fraction=0.25, seed=2026)
    dataset.validate_prepared_split(manifest)

    hashes_by_split = {}
    for split in ("train", "val"):
        hashes_by_split[split] = {
            hashlib.sha256(path.read_bytes()).hexdigest()
            for path in (local_tmp_path / "classification" / split).rglob("*")
            if path.is_file()
        }
    assert hashes_by_split["train"].isdisjoint(hashes_by_split["val"])
    assert manifest["class_names"] == ["class_a", "class_b"]
    assert manifest["duplicate_source_images_not_copied"] == 0


def test_download_retries_and_does_not_use_partial_source_archive(local_tmp_path, monkeypatch):
    source_root = local_tmp_path / "source"
    source_root.mkdir()
    (source_root / "1.archive").write_bytes(b"incomplete archive")
    valid_download = local_tmp_path / "kaggle-cache" / "dataset"
    valid_download.mkdir(parents=True)
    _write_class_images(valid_download)
    calls = []

    def fake_download(handle, *, force_download):
        calls.append((handle, force_download))
        if len(calls) == 1:
            raise ConnectionError("interrupted transfer")
        return str(valid_download)

    monkeypatch.setattr(dataset, "SOURCE_ROOT", source_root)
    monkeypatch.setattr(dataset, "_completed_cached_source", lambda: None)
    monkeypatch.setitem(__import__("sys").modules, "kagglehub", SimpleNamespace(dataset_download=fake_download))
    monkeypatch.setattr(dataset.time, "sleep", lambda _: None)

    result = dataset.download_source()

    assert result == valid_download
    assert calls == [(dataset.DATASET_HANDLE, False), (dataset.DATASET_HANDLE, True)]
    assert (source_root / "1.archive").read_bytes() == b"incomplete archive"


def test_download_uses_complete_cache_before_network(local_tmp_path, monkeypatch):
    cached_download = local_tmp_path / "completed-cache"
    cached_download.mkdir()
    _write_class_images(cached_download)
    monkeypatch.setattr(dataset, "SOURCE_ROOT", local_tmp_path / "empty-source")
    monkeypatch.setattr(dataset, "_completed_cached_source", lambda: cached_download)

    def unexpected_network_call(*args, **kwargs):
        raise AssertionError("A completed cache should avoid a network request")

    monkeypatch.setitem(
        __import__("sys").modules,
        "kagglehub",
        SimpleNamespace(dataset_download=unexpected_network_call),
    )

    assert dataset.download_source() == cached_download


def test_class_root_prefers_deeper_equal_sized_nested_classes(local_tmp_path):
    outer_root = local_tmp_path / "PlantVillage"
    nested_root = outer_root / "PlantVillage"
    nested_root.mkdir(parents=True)
    _write_class_images(outer_root)
    _write_class_images(nested_root)

    selected = dataset.find_class_root(outer_root)

    assert selected == nested_root
    assert list(dataset.collect_class_images(selected)) == ["class_a", "class_b"]


def test_existing_generated_split_is_never_overwritten(local_tmp_path, monkeypatch):
    split_root = local_tmp_path / "classification"
    split_root.mkdir()
    sentinel = split_root / "keep.txt"
    sentinel.write_text("existing user data", encoding="utf-8")
    monkeypatch.setattr(dataset, "CLASSIFICATION_ROOT", split_root)

    with pytest.raises(RuntimeError, match="already exists"):
        dataset.prepare_split({"class_a": []}, validation_fraction=0.2, seed=2026)

    assert sentinel.read_text(encoding="utf-8") == "existing user data"
