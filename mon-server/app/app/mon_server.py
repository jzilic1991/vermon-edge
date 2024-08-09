from multiprocessing import Queue
from util import VerificationType, RequirementProcName, ObjectiveProcName, \
  RequirementPattern, ObjectivePattern, Util
from monpoly import Monpoly
import requests
import time

def get_tr_patterns (ver_type):
  if ver_type == VerificationType.REQUIREMENT.value:
    return RequirementPattern
  elif ver_type == VerificationType.OBJECTIVE.value:
    return ObjectivePattern

def get_verifiers (ver_type):
  if ver_type == VerificationType.REQUIREMENT.value:
    return create_verifiers (RequirementProcName)
  elif ver_type == VerificationType.OBJECTIVE.value:
    return create_verifiers (ObjectiveProcName)

def create_verifiers (ProcName):
  verifiers = dict ()

  for proc_name in (ProcName):
    mon = Monpoly (Queue (), Queue (), proc_name)
    verifiers[mon] = (mon.get_incoming_queue (), mon.get_outgoing_queue ())
    mon.start ()

  return verifiers

def get_req_ver_url (ver_type, socket):
  return 'http://' + socket +'/edge-vermon'

class MonServer:
  def __init__ (self, ver_type, socket):
    self._ver_type = ver_type
    self._verifiers = get_verifiers (self._ver_type)
    self._tr_patterns = get_tr_patterns (self._ver_type)
    self._verdicts = self.__get_verdicts ()
    self._req_to_obj_map = Util.get_req_obj_dict_mapping ()
    self._socket = socket

  def get_ver_type (cls):
    return cls._ver_type

  def evaluate_trace (cls, trace):
    # find trace pattern that fits given trace
    for tr_pattern in (cls._tr_patterns):
      if tr_pattern.value in trace:
        # iterate verifiers and find which one corresponds to matched trace pattern
        for mon in cls._verifiers.keys ():
          # iterate trace patterns which are supported by a verifier
          for tr_target_pattern in mon.get_trace_patterns ():
            # and compare it with required trace pattern
            if tr_pattern.name == tr_target_pattern.name:
              # route given trace to appropriate verifier via queues
              cls._verifiers[mon][0].put (trace)
              v = cls._verifiers[mon][1].get ()
              cls.__send_to_req_ver (v, mon.get_mon_proc_enum ())
              return v

  def __get_verdicts (cls):
    verdicts = dict ()

    for mon in cls._verifiers.keys ():
      verdicts[mon.get_mon_proc_enum ().name] = False

    return verdicts

  def __send_to_req_ver (cls, verdict, mon_proc_enum):
    if cls._ver_type == VerificationType.OBJECTIVE.value:
      # return requirement event trace if verdict of objective has been updated
      # otherwise empty string
      mon_proc_name = cls.__evaluate_verdict_update (verdict, mon_proc_enum)
      if mon_proc_name != "":
        event_traces = cls.__create_event_trace (mon_proc_name)
        if event_traces != []:
          for event in event_traces:
            x = requests.post (get_req_ver_url (cls._ver_type, cls._socket), \
              params = { "trace": event })

  def __evaluate_verdict_update (cls, verdict, mon_proc_enum):
    # print ("Verdict: " + str (verdict[:len(verdict)-1]) + ", verifier process name: " + \
    #   str (mon_proc_enum.name))
    for mon_proc_name, last_verdict in cls._verdicts.items ():
      # if mon_proc_name == mon_proc_enum.name:
      #  print ("Last verdict: " + str (last_verdict))
      if (verdict == "" and last_verdict == True) or \
          (verdict != "" and last_verdict == False):
        cls._verdicts[mon_proc_name] = not (cls._verdicts[mon_proc_name])

        return mon_proc_name

    return ""

  def __create_event_trace (cls, proc_name):
    events = list ()

    for req_pattern_name, obj_proc_names in cls._req_to_obj_map.items ():
      event_trace = "@" + str (int (time.time ())) + " "
      # iterate through list of objective process names
      for obj_proc_name in obj_proc_names:
        # find which objective has been updated
        if proc_name == obj_proc_name:
          # start creating requirement event trace based on corresponded objective update
          event_trace += req_pattern_name + "("
          # include verdict values from all corresponding objectives of the same requirement
          for obj_name in cls._req_to_obj_map[req_pattern_name]:
            # cast verdict boolean value into integer value before string concatination
            event_trace += str (int(cls._verdicts[obj_name])) + ", "

          event_trace = event_trace[:len(event_trace)-2] + ")"
          events.append (event_trace)
          print ("Created verdict event trace: " + str (event_trace))
          # when event is constructed then break from inner loop to iterate further events
          break

    return events
