import os
from enum import Enum

class ObjectiveProcName(Enum):
    AVAIL_IAAS = "avail-iaas"
    AVAIL_SAAS = "avail-saas"
    REL_DEFECT = "rel-defect"
    REL_FAIL = "rel-fail"
    RESPONSE = "response"
    FAIL_DETECT = "fail-detector"
    TH_REQS = "reqs-throughput" 
    TH_PACKETS = "pck-throughput"

class RequirementProcName(Enum):
    REQ1 = "req-1"
    REQ2 = "req-2"
    REQ3 = "req-3"

class ObjectivePattern(Enum):
    STATUS = "status"
    TOTAL_REQS = "totalrequests"
    DEFECT = "defect"
    DOWN = "down"
    RESPONSE_TIME = "responsetime"
    HEARTBEAT = "heartbeat"
    REQUESTS = "requests"
    PACKETS = "packets"

class RequirementPattern(Enum):
    REQ1 = "req1"
    REQ2 = "req2"
    REQ3 = "req3"

class VerificationType(Enum):
    OBJECTIVE = "obj"
    REQUIREMENT = "req"

REQ_VERIFIER_SERVICE_URL = os.getenv("REQUIREMENT_VERIFIER_SERVICE")
