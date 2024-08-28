import time
import datetime
import statistics
import asyncio
from statistics import median
from tabulate import tabulate
from collections import deque
from enum import Enum
from state import app_state
from asyncio import Lock
from constants import ObjectiveProcName, RequirementProcName, ObjectivePattern, RequirementPattern

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
        return {RequirementPattern.REQ1.value: [ObjectiveProcName.RESPONSE.name, \
            ObjectiveProcName.REL_DEFECT.name, ObjectiveProcName.TH_REQS.name],\
          RequirementPattern.REQ2.value: [ObjectiveProcName.AVAIL_SAAS.name,\
            ObjectiveProcName.REL_FAIL.name, ObjectiveProcName.RESPONSE.name, \
            ObjectiveProcName.TH_REQS.name],\
          RequirementPattern.REQ3.value: [ObjectiveProcName.FAIL_DETECT.name,\
            ObjectiveProcName.RESPONSE.name, ObjectiveProcName.TH_REQS.name]}

def construct_event_trace(trace_type, *args):
    traces = ""
    trace_patterns = Util.determine_trace_patterns(trace_type)

    if trace_type in [ObjectiveProcName.RESPONSE, ObjectiveProcName.TH_REQS]:
        traces += f"@{time.time()} {trace_patterns[0].value} ({app_state.host},{args[0]})"
    elif trace_type == ObjectiveProcName.REL_DEFECT:
        traces += f"@{time.time()} {trace_patterns[0].value} ({app_state.host},{args[0]}) {trace_patterns[1].value} ({app_state.host},{args[1]})"
    elif trace_type == RequirementProcName.REQ1:
        traces += f"@{time.time() {trace_pattern[0].value}} ({args[0]},{args[1]},{args[2]})"
    return traces

def evaluate_event_traces(traces):
    print ("Event TRACE: " + str(traces))
    for trace in traces:
        verdict = app_state.mon_server.evaluate_trace(trace)
        if verdict:
            print(f"Spec violation detected! Trace: {verdict}")
            objective = extract_objective_from_trace(trace)
            timestamp = datetime.datetime.now()
            app_state.spec_violations[objective]["timestamps"].append(timestamp)
            app_state.spec_violations[objective]["count"] += 1

def extract_objective_from_trace(trace):
    if ObjectivePattern.RESPONSE_TIME.value in trace:
        return ObjectiveProcName.RESPONSE
    elif ObjectivePattern.REQUESTS.value in trace:
        return ObjectiveProcName.TH_REQS
    elif ObjectivePattern.DEFECT.value in trace:
        return ObjectiveProcName.REL_DEFECT
    return None

def print_spec_violation_stats():
    headers = ["Objective", "Violations Count", "Last Timestamp"]
    rows = []
    
    for objective, stats in app_state.spec_violations.items():
        last_timestamp = stats["timestamps"][-1] if stats["timestamps"] else "N/A"
        rows.append([
            objective.value,
            stats["count"],
            last_timestamp,
        ])
    
    print("\nSpecification Violation Statistics:")
    print(tabulate(rows, headers=headers, tablefmt="grid"))

class MetricsDeque:
    def __init__(self, maxlen = 1000):
        self.dq = deque(maxlen = maxlen)
        self.failed_requests = 0
        self.start_time = datetime.datetime.now()

    def append(self, value):
        self.dq.append(value)

    def avg(self):
        return sum(self.dq) / len(self.dq) if self.dq else 0

    def med(self):
        return statistics.median(self.dq) if self.dq else None

    def min(self):
        return min(self.dq) if self.dq else None

    def max(self):
        return max(self.dq) if self.dq else None

    def len(self):
        return len(self.dq) + self.failed_requests

    def starting_time(self):
        return self.start_time

async def pooling_task():
    req_total_prior = 0
    req_fail_total_prior = 0
    req_total_residual = 0
    req_fail_total_residual = 0

    while True:
        await asyncio.sleep(10)
        print("Pooling...")
        req_total_residual = app_state.request_counter - req_total_prior
        req_total_prior = app_state.request_counter
        req_fail_total_residual = app_state.req_fail_cnt - req_fail_total_prior
        req_fail_total_prior = app_state.req_fail_cnt
        traces = list()
        traces.append(construct_event_trace(ObjectiveProcName.TH_REQS, req_total_residual))
        traces.append(construct_event_trace(ObjectiveProcName.REL_DEFECT, req_fail_total_residual, req_total_residual))
        evaluate_event_traces(traces)        

def print_metrics(metrics_dict):
    headers = ["Type", "Name", "# reqs", "Failed reqs", "Avg (ms)", "Min (ms)", "Max (ms)", "Med (ms)", "req/s"]
    rows = []
    total_requests = 0
    total_failed_requests = 0
    all_timings = []
    
    for service_name, timings in metrics_dict.items():
        avg = timings.avg()
        min_time = timings.min()
        max_time = timings.max()
        med = timings.med()
        req_per_sec = timings.len() / (datetime.datetime.now() - timings.starting_time()).total_seconds()

        total_requests += timings.len()
        total_failed_requests += timings.failed_requests 
        all_timings.extend(timings.dq)
        rows.append([
            "GET",
            service_name,
            timings.len(),
            timings.failed_requests,
            f"{avg:.2f}",
            min_time,
            max_time,
            med,
            f"{req_per_sec:.2f}",
        ])
    
    
    if all_timings:
        avg_agg = sum(all_timings) / len(all_timings)
        min_agg = min(all_timings)
        max_agg = max(all_timings)
        med_agg = statistics.median(all_timings)
        req_per_sec_agg = total_requests / (datetime.datetime.now() - next(iter(metrics_dict.values())).starting_time()).total_seconds()
    else:
        avg_agg = min_agg = max_agg = med_agg = req_per_sec_agg = 0

    rows.append([
        "Aggregated",
        "",
        total_requests,
        total_failed_requests,  
        f"{avg_agg:.2f}",
        f"{min_agg:.2f}",
        f"{max_agg:.2f}",
        f"{med_agg:.2f}",
        f"{req_per_sec_agg:.2f}",
    ])
    
    print(tabulate(rows, headers=headers, tablefmt="grid"))
