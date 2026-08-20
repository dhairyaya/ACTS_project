import json
import os
from django.conf import settings
from typing import Dict, Any, Optional

def analyze_civic_issue(image_path: str, user_description: str = "") -> Dict[str, Any]:
    """
    Sends the complaint image and user description to Gemini Multimodal API
    to evaluate defect type, civic department, severity score (1-10), and action priority.
    """
    api_key = getattr(settings, 'GEMINI_API_KEY', '') or os.getenv('GEMINI_API_KEY', '')
    
    if not api_key or api_key == 'your_gemini_api_key_here':
        return {
            "status": "api_key_missing",
            "category": "Uncategorized Civic Defect",
            "department": "Municipal Corporation",
            "severity_score": 5,
            "summary": user_description or "Citizen submitted complaint pending automated Gemini triage.",
            "recommended_action": "Manual inspection required"
        }

    try:
        from google import genai
        from google.genai import types
        from PIL import Image

        client = genai.Client(api_key=api_key)
        pil_image = Image.open(image_path)

        prompt = f"""
You are an expert AI Municipal Civic Infrastructure Inspector.
Analyze this civic complaint photo.
Citizen Description: "{user_description}"

Return ONLY a valid JSON object with the following schema:
{{
    "category": "Pothole / Garbage Dump / Water Leakage / Broken Streetlight / Open Manhole / Other",
    "department": "Road Maintenance / Sanitation / Water Works / Electricity / Public Safety",
    "severity_score": <integer from 1 to 10 where 1 is minor cosmetic issue and 10 is critical life safety hazard>,
    "urgency": "LOW / MEDIUM / HIGH / CRITICAL",
    "summary": "Concise summary of the civic hazard observed in the image",
    "recommended_action": "Specific repair or cleanup recommendation for ground staff"
}}
"""

        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[pil_image, prompt]
        )

        response_text = response.text.strip()
        # Clean potential markdown formatting
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.startswith("```"):
            response_text = response_text[3:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]

        parsed_json = json.loads(response_text.strip())
        return parsed_json

    except Exception as e:
        return {
            "status": "error",
            "error_message": str(e),
            "category": "General Civic Issue",
            "department": "General Administration",
            "severity_score": 5,
            "summary": user_description or "Issue reported by citizen.",
            "recommended_action": "Review by department officer"
        }
