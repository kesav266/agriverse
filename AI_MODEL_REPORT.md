# AI Model Report

## Status

A five-epoch YOLO26n classification candidate was trained on the prepared PlantVillage split with CPU-only PyTorch. The existing `backend/models/crop_disease.pt` is preserved; it has 18 class names that do not match this dataset, and its checkpoint contains no training arguments or evaluation metadata. Neither artifact should be promoted to production on the basis of configuration alone.

## Dataset

- Source: Kaggle dataset `emmarex/plantdisease`, cached as version 1 and extracted from the completed KaggleHub archive.
- The split is deterministic with seed 2026 and a 20% validation fraction.
- Images: 20,624 total; 16,500 train and 4,124 validation.
- Classes: 15. The class directories and counts are recorded in `backend/datasets/PlantVillage/manifest.json` (ignored by Git with the dataset).
- Duplicate images are grouped by SHA-256 before assignment. The manifest records 14 duplicate source files within classes; validation checks generated hash suffixes and confirms no hash is represented in both splits.
- Root discovery selects the inner class directory in the archive's nested `PlantVillage/PlantVillage` layout, avoiding an incorrect synthetic `PlantVillage` label.
- Licensing: the [Kaggle dataset listing](https://www.kaggle.com/datasets/emmarex/plantdisease) currently reports the license as **Unknown**. Obtain written usage/redistribution rights clarification before public or commercial deployment.

The split is a holdout from the same dataset distribution, not an external field-image test set. PlantVillage images have controlled backgrounds and do not establish performance on farmer-submitted field photos.

## Architecture and runtime

- Task: image classification, not object detection.
- Architecture: Ultralytics `yolo26n-cls.pt` pretrained classifier.
- Runtime checked: Python 3.14.3, PyTorch 2.15.0+cpu, Ultralytics 8.4.201; the checkpoint loaded and CPU training began successfully.
- Training configuration: 224px, batch size 32, two data workers, `cache=False`, five epochs for this CPU-constrained candidate. The intended default remains 30 epochs. A batch-size-8 run showed an estimated 40+ minutes per epoch on the available CPU, so the five-epoch run is a time-bounded adjustment, not a final production training recommendation.
- Runtime class names are generated from the trained checkpoint, never hand-entered.

## Metrics

The final epoch reported top-1 accuracy **99.224%** and top-5 accuracy **99.952%**. A separate full pass of the saved best checkpoint over all 4,124 validation images produced **99.248%** top-1 accuracy (4,093 correct), macro precision **99.341%**, and macro recall **99.243%**. The small difference from the training log is due to the final saved best checkpoint versus the last-epoch report.

The separate per-image CPU prediction pass measured median latency **9.52 ms** and p95 **14.67 ms** with Ultralytics `predict`, 224px images, and model already loaded in the process. This is a local inference measurement, not end-to-end API or deployment latency. Candidate weights are **3,220,162 bytes** (about 3.07 MiB).

Class metrics from the full pass (precision / recall):

| Class | Validation images | Precision | Recall |
| --- | ---: | ---: | ---: |
| Pepper bacterial spot | 199 | 100.00% | 100.00% |
| Pepper healthy | 296 | 99.66% | 99.66% |
| Potato early blight | 200 | 100.00% | 100.00% |
| Potato late blight | 200 | 99.50% | 99.00% |
| Potato healthy | 30 | 100.00% | 100.00% |
| Tomato bacterial spot | 425 | 98.83% | 99.76% |
| Tomato early blight | 200 | 100.00% | 95.50% |
| Tomato late blight | 380 | 97.68% | 99.74% |
| Tomato leaf mold | 190 | 99.47% | 98.95% |
| Tomato Septoria leaf spot | 354 | 98.88% | 99.72% |
| Tomato spider mites | 335 | 98.24% | 99.70% |
| Tomato target spot | 281 | 99.64% | 97.86% |
| Tomato yellow leaf curl virus | 642 | 99.84% | 99.07% |
| Tomato mosaic virus | 75 | 98.68% | 100.00% |
| Tomato healthy | 317 | 99.68% | 99.68% |

The 15-class confusion matrix is available in the ignored training run output directory `backend/models/crop_disease_candidate_training_5ep` and can be regenerated using the validation images and candidate checkpoint.

No accuracy is claimed for the existing local 18-class `crop_disease.pt`; its checkpoint lacks provenance/metrics and its labels do not correspond to the 15-class PlantVillage dataset. No test-set or field-image performance has been measured.

## Safety and promotion

Treat results as image-screening output only, not a confirmed diagnosis. The candidate API smoke test succeeded using an isolated SQLite database: a held-out tomato healthy image returned `Tomato_healthy` at 99.97% confidence and was saved to diagnosis history. This checks the code path, not generalization beyond the dataset. Keep the existing model and local labels untouched until independent field-image results and dataset rights are reviewed. The candidate is written to ignored local model storage and is not bundled or committed.
