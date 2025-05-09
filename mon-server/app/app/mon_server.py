import time
from multiprocessing import Queue
from constants import VerificationType, RequirementPattern, ObjectivePattern
from util import Util
from monpoly import Monpoly
from verifier_loader import load_verifiers
from preprocessor import Preprocessor
import requests
from collections import deque
from debug_utils import DebugBuffer

def get_tr_patterns(ver_type):
    if ver_type == VerificationType.REQUIREMENT.value:
        return RequirementPattern
    elif ver_type == VerificationType.OBJECTIVE.value:
        return ObjectivePattern


def get_req_ver_url(ver_type, socket):
    return f"http://{socket}/edge-vermon"


class MonServer:
    def __init__(self, ver_type, socket):
        self._ver_type = ver_type
        self._socket = socket
        self._verifiers = dict()
        self._verdicts = dict()
        self._preprocessor = Preprocessor()
        self._tr_patterns = get_tr_patterns(self._ver_type)
        self._req_to_obj_map = Util.get_req_pattern_obj_process_dict()
        self.verifier_stats = dict()

        self.__init_verifiers()
        self.verifier_buffers = dict()
        self.buffer_print_threshold = 10
        self.buffer_max_size = 100
        self.buffer_counters = dict()
        import threading
        def force_print():
          print("[DEBUG] Force-print thread is running...")
          import time
          while True:
              time.sleep(5)
              for verifier_name, buffer in self.verifier_buffers.items():
                  print(f"\n[FORCE BUFFER DUMP: {verifier_name}]")
                  for i, t in enumerate(buffer):
                      print(f"  [{i}] {t}")

        threading.Thread(target=force_print, daemon=True).start()

    def __init_verifiers(self):
        for verifier_name in load_verifiers():
            self.__start_verifier(verifier_name)

    def __start_verifier(self, verifier_name):
        mon = Monpoly(Queue(), Queue(), verifier_name)
        self._verifiers[mon] = (mon.get_incoming_queue(), mon.get_outgoing_queue())
        mon.start()

        # Initialize stats
        self.verifier_stats[verifier_name] = {
            "violated": 0,
            "last_update": "N/A"
        }

    def get_ver_type(self):
        return self._ver_type

    def evaluate_response(self, response):
        try:
            response_data = response.json()
            if isinstance(response_data, dict) and "trace" in response_data:
                trace = response_data["trace"]
            else:
                trace = response.text
        except Exception:
            trace = response.text

        print(f"[DEBUG] Evaluating response trace inside MonServer: {trace}")
        return self.evaluate_trace(trace)


    def evaluate_trace(self, trace: str, routed_verifiers: List[str]) -> Dict[str, str]:
        verdicts = {}

        for mon in self._verifiers.keys():
            verifier_name = mon.get_verifier_name()
            if verifier_name in routed_verifiers:
                mon.get_incoming_queue().put(trace)

                # Initialize buffer if not exists
                if verifier_name not in self.verifier_buffers:
                    self.verifier_buffers[verifier_name] = deque(maxlen=self.buffer_max_size)
                    self.buffer_counters[verifier_name] = 0

                self.verifier_buffers[verifier_name].append(trace)
                self.buffer_counters[verifier_name] += 1

                if self.buffer_counters[verifier_name] >= self.buffer_print_threshold:
                    print(f"\n[Buffer: {verifier_name}] Last {len(self.verifier_buffers[verifier_name])} traces:")
                    for i, t in enumerate(self.verifier_buffers[verifier_name]):
                        print(f"  [{i}] {t}")
                    self.buffer_counters[verifier_name] = 0

                try:
                    verdict = mon.get_outgoing_queue().get(timeout=1.0)
                except Exception:
                    print(f"[WARN] Timeout reading monpoly output for {verifier_name}. Assuming violation.")
                    verdict = 0

                result = "violated" if verdict == 0 else "satisfied"
                verdicts[verifier_name] = result
                self.verifier_stats[verifier_name]["last_update"] = time.strftime("%Y-%m-%d %H:%M:%S")
                if result == "violated":
                    self.verifier_stats[verifier_name]["violated"] += 1

        return verdicts


    def __send_to_req_ver(self, verdict, mon_proc_enum):
        if self._ver_type == VerificationType.OBJECTIVE.value:
            mon_proc_name = self.__evaluate_verdict_update(verdict, mon_proc_enum)
            if mon_proc_name:
                event_traces = self.__create_event_trace(mon_proc_name)
                if event_traces:
                    for event in event_traces:
                        x = requests.post(get_req_ver_url(self._ver_type, self._socket),
                                          params={"trace": event})

    def __evaluate_verdict_update(self, verdict, mon_proc_enum):
        for mon_proc_name, last_verdict in self._verdicts.items():
            if (verdict == "" and last_verdict) or (verdict and not last_verdict):
                self._verdicts[mon_proc_name] = not last_verdict
                return mon_proc_name
        return ""

    def __create_event_trace(self, proc_name):
        events = []
        for req_pattern_name, obj_proc_names in self._req_to_obj_map.items():
            event_trace = f"@{int(time.time())} "
            for obj_proc_name in obj_proc_names:
                if proc_name == obj_proc_name:
                    event_trace += req_pattern_name + "("
                    for obj_name in self._req_to_obj_map[req_pattern_name]:
                        event_trace += str(int(self._verdicts[obj_name])) + ", "
                    event_trace = event_trace.rstrip(", ") + ")"
                    events.append(event_trace)
                    print("[DEBUG] Created event trace:", event_trace)
                    break
        return events

