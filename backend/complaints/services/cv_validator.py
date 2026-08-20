import cv2
import numpy as np
from typing import Tuple

def validate_image_clarity(image_file, threshold: float = 100.0) -> Tuple[bool, float]:
    """
    Evaluates image sharpness using the Laplacian variance method.
    Returns (is_valid, blur_score).
    Higher blur_score means sharper image.
    """
    try:
        # Read image buffer into numpy array
        image_bytes = image_file.read()
        image_file.seek(0)  # Reset pointer for subsequent reads
        
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            return False, 0.0

        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Calculate Laplacian variance
        laplacian_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
        is_clear = laplacian_var >= threshold

        return is_clear, round(laplacian_var, 2)
    except Exception as e:
        image_file.seek(0)
        return True, 0.0
