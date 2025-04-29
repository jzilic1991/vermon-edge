import time
import datetime
import statistics
import asyncio
import httpx
from statistics import median
from tabulate import tabulate
from collections import deque
from enum import Enum
from state import app_state
from preprocessor import Preprocessor
from asyncio import Lock
from constants import REQ_VERIFIER_SERVICE_URL, ObjectiveProcName, RequirementProcName, ObjectivePattern, RequirementPattern

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

    def get_req_pattern_obj_process_dict ():
        return {RequirementPattern.REQ1.value: [ObjectiveProcName.RESPONSE.name, \
            ObjectiveProcName.REL_DEFECT.name, ObjectiveProcName.TH_REQS.name],\
          RequirementPattern.REQ2.value: [ObjectiveProcName.AVAIL_SAAS.name,\
            ObjectiveProcName.REL_FAIL.name, ObjectiveProcName.RESPONSE.name, \
            ObjectiveProcName.TH_REQS.name],\
          RequirementPattern.REQ3.value: [ObjectiveProcName.FAIL_DETECT.name,\
            ObjectiveProcName.RESPONSE.name, ObjectiveProcName.TH_REQS.name]}
    
    def get_req_obj_proc_dict ():
        return {RequirementProcName.REQ1: [ObjectiveProcName.RESPONSE, \
            ObjectiveProcName.REL_DEFECT, ObjectiveProcName.TH_REQS],\
          RequirementProcName.REQ2: [ObjectiveProcName.AVAIL_SAAS,\
            ObjectiveProcName.REL_FAIL, ObjectiveProcName.RESPONSE, \
            ObjectiveProcName.TH_REQS],\
          RequirementProcName.REQ3: [ObjectiveProcName.FAIL_DETECT,\
            ObjectiveProcName.RESPONSE, ObjectiveProcName.TH_REQS]}


def construct_event_trace(trace_type, *args):
    traces = ""
    trace_patterns = Util.determine_trace_patterns(trace_type)
    
    if trace_type in [ObjectiveProcName.RESPONSE, ObjectiveProcName.TH_REQS]:
        traces += f"@{time.time()} {trace_patterns[0].value} ({app_state.host},{args[0]})"
    elif trace_type == ObjectiveProcName.REL_DEFECT:
        traces += f"@{time.time()} {trace_patterns[0].value} ({app_state.host},{args[0]}) {trace_patterns[1].value} ({app_state.host},{args[1]})"
    elif trace_type == RequirementProcName.REQ1 or trace_type == RequirementProcName.REQ2 or \
      trace_type == RequirementProcName.REQ3:
        traces = f"@{time.time()} {trace_patterns[0].value} ("
        for verdict in args[0].values():
            traces += f"{verdict['verdict']},"
        traces = traces[:-1] + ")"
    
    return traces


def evaluate_event_traces(response):
    try:
        # Try parsing JSON first (if response is JSON)
        response_data = response.json()
        if isinstance(response_data, dict) and "trace" in response_data:
            trace = response_data["trace"]
        else:
            trace = response.text
    except Exception:
        # If not JSON, fallback to raw text
        trace = response.text

    print(f"Evaluating trace: {trace}")
    return app_state.mon_server.evaluate_trace(trace)


async def send_verdict_to_remote_service(objective: ObjectiveProcName, url: str, current_verdict: int):
    data = {"verdict": current_verdict}
    try:
        headers = ["Objective", "Current Verdict"]
        rows = []
        for objective_key, last_verdict in app_state.last_verdicts.items():
            if objective_key == objective:
                if last_verdict != current_verdict:
                    change_indicator = f" ({last_verdict} -> {current_verdict})"
                else:
                    change_indicator = ""
                rows.append([f"{objective.value}{change_indicator}", current_verdict])
            else:
                rows.append([objective_key.value, app_state.last_verdicts[objective_key]])

        print("\nVerdict Change Notification:")
        print(tabulate(rows, headers=headers, tablefmt="grid"))
        app_state.last_verdicts[objective] = current_verdict
        
        async with httpx.AsyncClient() as client:
            await client.post("http://" + url, data=data)
    except Exception as e:
        print(f"Failed to send verdict: {data}, exception: {e}")


def extract_objective_from_trace(trace):
    if ObjectivePattern.RESPONSE_TIME.value in trace:
        return ObjectiveProcName.RESPONSE
    elif ObjectivePattern.REQUESTS.value in trace:
        return ObjectiveProcName.TH_REQS
    elif ObjectivePattern.DEFECT.value in trace:
        return ObjectiveProcName.REL_DEFECT
    elif RequirementPattern.REQ1.value in trace:
        return RequirementProcName.REQ1
    elif RequirementPattern.REQ2.value in trace:
        return RequirementProcName.REQ2
    elif RequirementPattern.REQ3.value in trace:
        return RequirementProcName.REQ3
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
    pass

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
