from ..models import Complaint, ComplaintStatus

def evaluate_submission_trust(user_trust_score: float) -> str:
    """
    Evaluates whether the complaint should be auto-published to triage or held for admin spam review.
    """
    if user_trust_score < 0.4:
        return ComplaintStatus.SUBMITTED  # Held for manual admin review
    return ComplaintStatus.QUEUED

def adjust_user_trust_score(user_identifier: str, is_accurate: bool) -> float:
    """
    Updates the reputation of a reporter based on confirmed resolution or false reports.
    """
    recent_reports = Complaint.objects.filter(user_identifier=user_identifier)
    current_score = recent_reports.first().user_trust_score if recent_reports.exists() else 1.0

    if is_accurate:
        new_score = min(1.0, current_score + 0.05)
    else:
        new_score = max(0.1, current_score - 0.25)

    recent_reports.update(user_trust_score=new_score)
    return new_score
