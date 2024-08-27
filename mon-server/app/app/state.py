from constants import ObjectiveProcName

class AppState:
    def __init__(self):
        self.host = 1
        self.request_counter = 0
        self.req_fail_cnt = 0
        self.mon_server = None

        self.spec_violations = {
            ObjectiveProcName.RESPONSE: {"timestamps": [], "count": 0},
            ObjectiveProcName.TH_REQS: {"timestamps": [], "count": 0},
            ObjectiveProcName.REL_DEFECT: {"timestamps": [], "count": 0},
        }

app_state = AppState()

