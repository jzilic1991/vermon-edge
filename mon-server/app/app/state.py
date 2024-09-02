import sys
from constants import ObjectiveProcName, RequirementProcName

class AppState:
    def __init__(self):
        self.host = 1
        self.request_counter = 0
        self.req_fail_cnt = 0
        self.mon_server = None

        if sys.argv[1] == "obj":
            objectives = [ObjectiveProcName.RESPONSE, ObjectiveProcName.TH_REQS, ObjectiveProcName.REL_DEFECT]
        else:
            objectives = [RequirementProcName.REQ1, RequirementProcName.REQ2, RequirementProcName.REQ3]

        self.last_verdicts = self.initialize_verdicts(objectives)
        self.spec_violations = self.initialize_spec_violations(objectives)

    @staticmethod
    def initialize_verdicts(objectives):
        return {objective: None for objective in objectives}

    @staticmethod
    def initialize_spec_violations(objectives):
        return {objective: {"timestamps": [], "count": 0} for objective in objectives}

app_state = AppState()

