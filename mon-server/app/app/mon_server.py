from multiprocessing import Queue
from constants import VerificationType, RequirementProcName, ObjectiveProcName, RequirementPattern, ObjectivePattern
from util import Util
from monpoly import Monpoly
from verifier_loader import load_verifiers
from preprocessor import Preprocessor
import requests
import time


def get_tr_patterns (ver_type):
  if ver_type == VerificationType.REQUIREMENT.value:
    return RequirementPattern
  elif ver_type == VerificationType.OBJECTIVE.value:
    return ObjectivePattern


def get_req_ver_url (ver_type, socket):
  return 'http://' + socket +'/edge-vermon'


class MonServer:
  def __init__ (self, ver_type, socket):
    self._ver_type = ver_type
    self._verifiers = dict()
    self.verifier_stats = dict()
    self.__init_verifiers()
    self._preprocessor = Preprocessor()
    self._tr_patterns = get_tr_patterns (self._ver_type)
    self._verdicts = self.__get_verdicts ()
    self._req_to_obj_map = Util.get_req_pattern_obj_process_dict ()
    self._socket = socket

  
  def get_ver_type (self):
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

    print(f"Evaluating trace inside MonServer: {trace}")
    return self.evaluate_trace(trace)


  def evaluate_trace(self, formatted_trace):
    v = dict()
    print(f"[DEBUG] Evaluating trace: {formatted_trace.strip()}")

    for mon in self._verifiers.keys():
        mon_name = mon.get_verifier_name()
        self._verifiers[mon][0].put(formatted_trace)
        verdict = self._verifiers[mon][1].get()

        if verdict == 1:
            v[mon_name] = "violated"
            self.verifier_stats[mon_name]["violated"] += 1
        else:
            v[mon_name] = "satisfied"

        self.verifier_stats[mon_name]["last_update"] = time.strftime("%Y-%m-%d %H:%M:%S")

    return v


  def __init_verifiers(self):
    for verifier_name in load_verifiers():
      self.__start_verifier(verifier_name)


  def __start_verifier (self, verifier_name):
    mon = Monpoly (Queue(), Queue(), verifier_name)
    self._verifiers[mon] = (mon.get_incoming_queue(), mon.get_outgoing_queue())
    mon.start()

    self.verifier_stats[verifier_name] = {
        "violated": 0,
        "last_update": "N/A"
    }
  

  def __get_verdicts (self):
    verdicts = dict ()

    for mon in self._verifiers.keys():
      verdicts[mon.get_verifier_name()] = False

    return verdicts


  def __send_to_req_ver (self, verdict, mon_proc_enum):
    if self._ver_type == VerificationType.OBJECTIVE.value:
      # return requirement event trace if verdict of objective has been updated
      # otherwise empty string
      mon_proc_name = self.__evaluate_verdict_update (verdict, mon_proc_enum)
      if mon_proc_name != "":
        event_traces = self.__create_event_trace (mon_proc_name)
        if event_traces != []:
          for event in event_traces:
            x = requests.post (get_req_ver_url (self._ver_type, self._socket), \
              params = { "trace": event })


  def __evaluate_verdict_update (self, verdict, mon_proc_enum):
    # print ("Verdict: " + str (verdict[:len(verdict)-1]) + ", verifier process name: " + \
    #   str (mon_proc_enum.name))
    for mon_proc_name, last_verdict in self._verdicts.items ():
      # if mon_proc_name == mon_proc_enum.name:
      #  print ("Last verdict: " + str (last_verdict))
      if (verdict == "" and last_verdict == True) or \
          (verdict != "" and last_verdict == False):
        self._verdicts[mon_proc_name] = not (self._verdicts[mon_proc_name])

        return mon_proc_name

    return ""


  def __create_event_trace (self, proc_name):
    events = list ()

    for req_pattern_name, obj_proc_names in self._req_to_obj_map.items ():
      event_trace = "@" + str (int (time.time ())) + " "
      # iterate through list of objective process names
      for obj_proc_name in obj_proc_names:
        # find which objective has been updated
        if proc_name == obj_proc_name:
          # start creating requirement event trace based on corresponded objective update
          event_trace += req_pattern_name + "("
          # include verdict values from all corresponding objectives of the same requirement
          for obj_name in self._req_to_obj_map[req_pattern_name]:
            # cast verdict boolean value into integer value before string concatination
            event_trace += str (int(self._verdicts[obj_name])) + ", "

          event_trace = event_trace[:len(event_trace)-2] + ")"
          events.append (event_trace)
          print ("Created verdict event trace: " + str (event_trace))
          # when event is constructed then break from inner loop to iterate further events
          break

    return events
