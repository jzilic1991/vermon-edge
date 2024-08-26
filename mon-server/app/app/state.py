class AppState:
    def __init__(self):
        self.host = 1
        self.request_counter = 0
        self.req_fail_cnt = 0
        self.mon_server = None

app_state = AppState()

