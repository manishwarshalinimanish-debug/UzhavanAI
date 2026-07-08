def get_recommendation(crop: str, disease: str):
    disease_lower = disease.lower()

    if disease_lower == "healthy":
        return {
            "treatment": "No treatment needed.",
            "prevention": "Continue regular watering and inspect leaves weekly.",
            "fertilizer": "Use balanced NPK fertilizer as per soil condition."
        }

    if "early blight" in disease_lower:
        return {
            "treatment": "Remove infected leaves and apply Mancozeb or Copper-based fungicide.",
            "prevention": "Avoid overhead watering and maintain spacing between plants.",
            "fertilizer": "Use potassium-rich fertilizer to improve plant resistance."
        }

    if "late blight" in disease_lower:
        return {
            "treatment": "Apply Metalaxyl or Mancozeb fungicide immediately.",
            "prevention": "Avoid excess moisture and remove infected plants quickly.",
            "fertilizer": "Use balanced NPK and avoid excess nitrogen."
        }

    if "common rust" in disease_lower:
        return {
            "treatment": "Apply suitable fungicide such as Mancozeb or Propiconazole.",
            "prevention": "Use resistant varieties and avoid dense planting.",
            "fertilizer": "Use balanced fertilizer and avoid nitrogen overdose."
        }

    return {
        "treatment": "Consult a local agriculture expert for accurate treatment.",
        "prevention": "Monitor crop regularly and remove infected leaves.",
        "fertilizer": "Use fertilizer based on soil test recommendation."
    }