import time
from enum import Enum

class ObjectiveProcName (Enum):
    AVAIL_IAAS = "avail-iaas"
    AVAIL_SAAS = "avail-saas"
    REL_DEFECT = "rel-defect"
    REL_FAIL = "rel-fail"
    RESPONSE = "response"
    FAIL_DETECT = "fail-detector"
    TH_REQS = "reqs-throughput" 
    TH_PACKETS = "pck-throughput"

class RequirementProcName (Enum):
    REQ1 = "req-1"
    REQ2 = "req-2"
    REQ3 = "req-3"

class ObjectivePattern (Enum):
    STATUS = "status"
    TOTAL_REQS = "totalrequests"
    DEFECT = "defect"
    DOWN = "down"
    RESPONSE_TIME = "responsetime"
    HEARTBEAT = "heartbeat"
    REQUESTS = "requests"
    PACKETS = "packets"

class RequirementPattern (Enum):
    REQ1 = "req1"
    REQ2 = "req2"
    REQ3 = "req3"

class VerificationType (Enum):
    OBJECTIVE = "obj"
    REQUIREMENT = "req"

class Util (object):
    # return trace pattern based on monpoly verifier process naming
    def determine_trace_patterns (mon_proc_name):
        if mon_proc_name == ObjectiveProcName.AVAIL_IAAS or \
          mon_proc_name == ObjectiveProcName.AVAIL_SAAS:
            return [ObjectivePattern.STATUS]
        elif mon_proc_name == ObjectiveProcName.REL_DEFECT:
            return [ObjectivePattern.DEFECT, ObjectivePattern.TOTAL_REQS]
        elif mon_proc_name == ObjectiveProcName.REL_FAIL:
            return [ObjectivePattern.DOWN]
        elif mon_proc_name == ObjectiveProcName.RESPONSE:
            return [ObjectivePattern.RESPONSE_TIME]
        elif mon_proc_name == ObjectiveProcName.FAIL_DETECT:
            return [ObjectivePattern.HEARTBEAT]
        elif mon_proc_name == ObjectiveProcName.TH_REQS:
            return [ObjectivePattern.REQUESTS]
        elif mon_proc_name == ObjectiveProcName.TH_PACKETS:
            return [ObjectivePattern.PACKETS]
        elif mon_proc_name == RequirementProcName.REQ1:
            return [RequirementPattern.REQ1]
        elif mon_proc_name == RequirementProcName.REQ2:
            return [RequirementPattern.REQ2]
        elif mon_proc_name == RequirementProcName.REQ3:
            return [RequirementPattern.REQ3]

    def get_req_obj_dict_mapping ():
        return {RequirementPattern.REQ1.value: [ObjectiveProcName.AVAIL_IAAS.name, \
            ObjectiveProcName.REL_DEFECT.name, ObjectiveProcName.RESPONSE.name, \
            ObjectiveProcName.TH_PACKETS.name],\
          RequirementPattern.REQ2.value: [ObjectiveProcName.AVAIL_SAAS.name,\
            ObjectiveProcName.REL_FAIL.name, ObjectiveProcName.RESPONSE.name, \
            ObjectiveProcName.TH_REQS.name],\
          RequirementPattern.REQ3.value: [ObjectiveProcName.FAIL_DETECT.name,\
            ObjectiveProcName.RESPONSE.name, ObjectiveProcName.TH_REQS.name]}

def construct_event_trace(trace_type, *args):
    traces = ""
    trace_patterns = Util.determine_trace_patterns(trace_type)

    if trace_type in [ObjectiveProcName.RESPONSE, ObjectiveProcName.TH_REQS]:
        traces += f"@{time.time()} {trace_patterns[0].value} ({args[0]},{args[1]})"
    elif trace_type == ObjectiveProcName.REL_DEFECT:
        traces += f"@{time.time()} {trace_patterns[0].value} ({args[0]},{args[1]}) {trace_patterns[1].value} ({args[0]},{args[2]})"

    return traces

def evaluate_event_traces(traces, mon_server):
    print ("Event TRACE: " + str(traces))
    for trace in traces:
        verdict = mon_server.evaluate_trace(trace)
        if verdict:
            print(f"Spec violation detected! Trace: {verdict}")
