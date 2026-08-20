import os
from pathlib import Path
from django.conf import settings
from typing import Dict, Any, List

# Cache loaded model instance
_YOLO_MODEL = None

def get_yolo_model():
    global _YOLO_MODEL
    if _YOLO_MODEL is None:
        model_path = getattr(settings, 'YOLO_MODEL_PATH', None)
        if model_path and os.path.exists(model_path):
            try:
                from ultralytics import YOLO
                _YOLO_MODEL = YOLO(str(model_path))
            except Exception as e:
                print(f"[YOLO Warning] Failed to load model from {model_path}: {e}")
    return _YOLO_MODEL

def detect_civic_defects(image_path_or_file) -> Dict[str, Any]:
    """
    Runs YOLO inference on the image to locate potholes, garbage heaps, broken streetlights, etc.
    Returns detected defects with bounding boxes and confidence scores.
    """
    model = get_yolo_model()
    if model is None:
        return {
            "status": "model_not_loaded",
            "message": "Pre-trained YOLO weights not found or ultralytics not configured.",
            "detections": []
        }

    try:
        results = model(image_path_or_file)
        detections: List[Dict[str, Any]] = []

        for r in results:
            boxes = r.boxes
            for box in boxes:
                cls_id = int(box.cls[0].item())
                label = model.names[cls_id] if hasattr(model, 'names') else f"class_{cls_id}"
                confidence = float(box.conf[0].item())
                xyxy = box.xyxy[0].tolist()

                detections.append({
                    "label": label,
                    "confidence": round(confidence, 3),
                    "bbox": [round(coord, 2) for coord in xyxy]
                })

        return {
            "status": "success",
            "detections": detections,
            "count": len(detections)
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e),
            "detections": []
        }
