# PlantVillage Crop Disease Classification

This project uses the PlantVillage image dataset as a **classification** dataset. It contains labeled leaf images, not bounding boxes, so the runtime uses an Ultralytics YOLO classification model (`yolo26n-cls.pt`). The app reports a screening result only; it is not a confirmed diagnosis or pesticide recommendation.

## 1. Install dependencies

Run from `backend/` with Python 3.11 or newer:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

`kagglehub` may require you to authenticate or accept the dataset terms interactively. Keep any Kaggle token outside this repository and never commit it.

## 2. Download and prepare PlantVillage

```powershell
.\.venv\Scripts\python.exe download_dataset.py
```

The script first reuses an existing valid source tree or a complete KaggleHub cache. Otherwise, it retries the download up to three times and lets KaggleHub resume partial transfers where supported. It validates that class directories contain images before preparing a split. A stale file such as `source/1.archive` is never treated as a dataset or copied over the completed cache. The prepared output is:

```text
backend/datasets/PlantVillage/
  source/                 # optional manually supplied source data
  classification/
    train/<actual class name>/
    val/<actual class name>/
  manifest.json
```

The extracted archive keeps an outer `PlantVillage/PlantVillage/` directory. Root discovery checks direct class folders and chooses the deeper path on equal class-count candidates so a parent directory cannot become a bogus class label. The split is deterministic (`seed=2026`), targets 80:20 train/validation data, and assigns duplicate image hashes to one split only. Before writing `manifest.json`, the script validates exact class counts, non-empty train/validation folders, generated hash suffixes, and split separation. It refuses to overwrite an existing generated split.

## 3. Train the model

Training can require a CUDA GPU and substantial disk/RAM. The script selects CUDA with Ultralytics automatic batch sizing when available, uses a small batch on Apple Silicon, and uses batch size 8 on CPU. CPU training is supported but may be slow.

```powershell
# Preserve any existing model and train a reviewable candidate (CPU, 16 GB RAM).
.\.venv\Scripts\python.exe train_disease_classifier.py `
  --output models/crop_disease_candidate.pt --epochs 5 --batch 32 --workers 2
```

The default remains 30 epochs. On the available CPU, batch size 8 measured roughly 45 minutes per epoch; batch size 32 is faster and uses two data workers without caching the dataset in RAM. The current five-epoch run is a hardware-bounded candidate, not a production validation. Increase to 30 epochs on a machine that can finish the run in a practical time, then compare the completed validation results before promotion.

By default, the script trains `yolo26n-cls.pt` for 30 epochs at image size 224; `--epochs` can be changed for a bounded candidate run. On success it creates ignored local artifacts:

```text
backend/models/crop_disease.pt
backend/models/crop_disease_labels.json
backend/models/crop_disease.env
```

`crop_disease_labels.json` is generated from the trained model's actual class names. Do not replace it with guessed or copied labels. Review validation metrics and test with known holdout images before enabling users.

## 4. Configure the backend

The training command can update the local environment file as part of a reviewed training run:

```powershell
.\.venv\Scripts\python.exe train_disease_classifier.py --configure-env .env
```

To configure an already-trained, reviewed `backend/models/crop_disease.pt` without retraining:

```powershell
.\.venv\Scripts\python.exe train_disease_classifier.py --configure-existing --configure-env .env
```

Training refuses to overwrite the selected output weights by default. Keep the candidate path until its metrics and known-image behavior have been reviewed. Promotion to `crop_disease.pt` and changes to `.env` are separate operator actions.

The generated configuration contains the absolute model path and a JSON `DISEASE_ALLOWED_LABELS` array taken directly from that model. For Docker or another host, mount the reviewed model outside the image and copy those two generated values into the deployment secret/configuration system.

## 5. Verify the API

Restart FastAPI. `GET /health/ready` should report `disease_model_configured: true`. Upload a known valid PNG/JPEG/WebP leaf image to the authenticated endpoint:

```text
POST /api/v1/crop-health/diagnose-image
```

The response includes `detected_disease`, `confidence_score`, and `top_predictions`. If the model file is missing, the runtime is unavailable, a label is not on the generated allow-list, or confidence is below the configured threshold, the API returns a safe unavailable/uncertain result instead of inventing a diagnosis.

## Data and model handling

`backend/datasets/`, `backend/models/`, and `*.pt` are ignored by Git. Do not commit PlantVillage images, trained weights, Kaggle credentials, generated `.env` files, or provider/database credentials. The [Kaggle dataset listing currently marks its license as Unknown](https://www.kaggle.com/datasets/emmarex/plantdisease); obtain rights clarification before redistribution or public/commercial use.
