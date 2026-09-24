from app.schemas.models import Finding, FindingStatus, ValidationResult
DEFAULT_RULES={"minimum_anomaly_score":.35}
def validate(findings:list[Finding], page_sizes:dict[int,tuple[int|None,int|None]], config:dict|None=None):
    cfg=DEFAULT_RULES | (config or {}); results=[]; seen=set()
    for finding in findings:
        box=finding.region_coordinates; width,height=page_sizes.get(finding.page_number,(None,None)); status=FindingStatus.requires_review; rules=[]; rationale=[]
        if finding.page_number not in page_sizes or (width and box.right>width) or (height and box.bottom>height): status=FindingStatus.dismissed; rules.append("coordinates_within_page"); rationale.append("Coordinates exceed declared page bounds.")
        elif finding.detector_error: rules.append("detector_error"); rationale.append("Detector failure is retained for review.")
        elif finding.anomaly_score is not None and finding.anomaly_score<cfg["minimum_anomaly_score"]: status=FindingStatus.dismissed; rules.append("minimum_anomaly_score"); rationale.append("Below configured heuristic threshold.")
        else:
            key=(finding.category.value,finding.page_number,round(box.x,1),round(box.y,1),round(box.width,1),round(box.height,1))
            if key in seen: status=FindingStatus.dismissed; rules.append("duplicate_finding"); rationale.append("Duplicate category and coordinates.")
            else: seen.add(key); status=FindingStatus.flagged; rules.append("review_required"); rationale.append("Valid heuristic signal requires downstream review.")
        finding.status=status; results.append(ValidationResult(finding_id=finding.finding_id,status=status,applied_rules=rules,rationale=rationale))
    return findings,results
