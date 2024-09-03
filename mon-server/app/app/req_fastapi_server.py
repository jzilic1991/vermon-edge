from fastapi import FastAPI, Form, Request, HTTPException
from mon_server import MonServer
import httpx
import uvicorn
import asyncio
import os
import sys
from datetime import datetime
from util import Util, construct_event_trace, evaluate_event_traces, print_spec_violation_stats
from constants import ObjectiveProcName
from state import app_state
from asyncio import Lock

verdict_lock = Lock()
REQUIREMENTS = Util.get_req_obj_proc_dict()
app = FastAPI()
verdict_counter = 0
reqs_dict = {
    requirement: {
        "objectives": {objective: {"verdict": 0, "timestamp": "N/A"} for objective in REQUIREMENTS[requirement]},
        "verdict": 0
    }
    for requirement in REQUIREMENTS.keys()
}

def print_req_status():
    global reqs_dict

    for req, data in reqs_dict.items():
        objectives = data["objectives"]
        obj_names = " | ".join([str(obj.value).ljust(18) for obj in objectives])
        obj_values = " | ".join([str(obj_data["verdict"]).rjust(18) for obj_data in objectives.values()])
        header = "+-----------------+" + "+".join(["-" * 20 for _ in objectives]) + "+--------------------+"
        print(f"\nRequirement status:")
        print(header)
        print(f"| {'Name'.ljust(15)} | {obj_names} | {'Verdict'.ljust(18)} |")
        print(header.replace('-', '='))
        print(f"| {str(req.value).ljust(15)} | {obj_values} | {str(data['verdict']).rjust(18)} |")
        print(header)

async def handling_verdicts(verdict: dict):
    global reqs_dict, verdict_counter
    # print("Received objective verdict: " + str(verdict))
    reqs = list()
    verdict_keys = verdict.keys()
    for req, objs in REQUIREMENTS.items():
        for key in verdict_keys:
            if key in objs:
                reqs.append(req)
    
    if not reqs:
        raise HTTPException(status_code=404, detail="Objective not related to any of the requirements")
   
    async with verdict_lock:
        for req in reqs:
            for key in verdict_keys:
                reqs_dict[req]["objectives"][key]["verdict"] = verdict[key]
                reqs_dict[req]["objectives"][key]["timestamp"] = datetime.now().isoformat()
                
            trace = construct_event_trace(req, reqs_dict[req]["objectives"])
            a = evaluate_event_traces([trace])
            # print(str(req) + " verdict status: " + str(a))
            reqs_dict[req]["verdict"] = a[0]
    
    verdict_counter += 1

    if verdict_counter % 5 == 0:
        print_spec_violation_stats()
        print_req_status()

@app.on_event("startup")
async def startup():
    app_state.mon_server = MonServer(sys.argv[1], sys.argv[2])

@app.post("/" + str(ObjectiveProcName.RESPONSE.value))
async def response(verdict: bool = Form(...)):
    verdict = {ObjectiveProcName.RESPONSE: int(verdict)}
    await handling_verdicts(verdict)
    return {"status": "OK"}

@app.post("/" + str(ObjectiveProcName.TH_REQS.value))
async def throughput(verdict: bool  = Form(...)):
    verdict = {ObjectiveProcName.TH_REQS: int(verdict)}
    await handling_verdicts(verdict)
    return {"status": "OK"}

@app.post("/" + str(ObjectiveProcName.REL_DEFECT.value))
async def defect(verdict: bool = Form(...)):
    verdict = {ObjectiveProcName.REL_DEFECT: int(verdict)}
    await handling_verdicts(verdict)
    return {"status": "OK"}

@app.get("/healthz")
async def health_check():
    return {"status": "OK"}

def start_req_fastapi_server():
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("SERVER_PORT")), log_level="info")
