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

The script downloads `emmarex/plantdisease` only when `backend/datasets/PlantVillage/source/` is empty. It inspects the downloaded directories to find the actual class folders, retains their exact names, copies data into:

```text
backend/datasets/PlantVillage/
  source/downloaded/      # cached Kaggle download copied locally; never deleted by the script
  classification/
    train/<actual class name>/
    val/<actual class name>/
  manifest.json
```

The split is deterministic (`seed=2026`), targets 80:20 train/validation data, and assigns duplicate image hashes to one split only. The generated `manifest.json` records the discovered class names and image counts. The script refuses to overwrite an existing generated split; remove only the generated `classification/` directory manually if you deliberately need a rebuilt split.

## 3. Train the model

Training can require a CUDA GPU and substantial disk/RAM. The script selects CUDA with Ultralytics automatic batch sizing when available, uses a small batch on Apple Silicon, and uses batch size 8 on CPU. CPU training is supported but may be slow.

```powershell
.\.venv\Scripts\python.exe train_disease_classifier.py
```

This always trains `yolo26n-cls.pt` for 30 epochs at image size 224. On success it creates ignored local artifacts:

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

Training refuses to overwrite `backend/models/crop_disease.pt` by default. If you have reviewed a replacement model, add `--overwrite --configure-env .env`.

The generated configuration contains the absolute model path and a JSON `DISEASE_ALLOWED_LABELS` array taken directly from that model. For Docker or another host, mount the reviewed model outside the image and copy those two generated values into the deployment secret/configuration system.

## 5. Verify the API

Restart FastAPI. `GET /health/ready` should report `disease_model_configured: true`. Upload a known valid PNG/JPEG/WebP leaf image to the authenticated endpoint:

```text
POST /api/v1/crop-health/diagnose-image
```

The response includes `detected_disease`, `confidence_score`, and `top_predictions`. If the model file is missing, the runtime is unavailable, a label is not on the generated allow-list, or confidence is below the configured threshold, the API returns a safe unavailable/uncertain result instead of inventing a diagnosis.

## Data and model handling

`backend/datasets/` and `backend/models/` are ignored by Git. Do not commit PlantVillage images, trained weights, Kaggle credentials, generated `.env` files, or provider/database credentials. Confirm the PlantVillage dataset license and intended-use constraints before any public or commercial deployment.
