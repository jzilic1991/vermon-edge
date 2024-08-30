from fastapi import FastAPI, Form, Request, HTTPException
from mon_server import MonServer
import httpx
import uvicorn
import asyncio
import os
import sys
from util import Util, construct_event_trace, evaluate_event_traces
from constants import ObjectiveProcName
from state import app_state
from asyncio import Lock

verdict_lock = Lock()
REQUIREMENTS = Util.get_req_obj_proc_dict()
app = FastAPI()
reqs_stats = {requirement: 0 for requirement in REQUIREMENTS.keys()}
reqs_dict = {requirement: {objective: 0 for objective in REQUIREMENTS[requirement]} for requirement in REQUIREMENTS.keys()} 

async def handling_verdicts(verdict: dict):
    global reqs_dict

    reqs = list()
    verdict_keys = verdict.keys()
    for req, objs in REQUIREMENTS.items():
        for key in verdict_keys:
            if key in objs:
                reqs.append(req)
    
    if not reqs: 
        raise HTTPException(status_code=404, detail="Objective not related to none of requirements")
   
    async with verdict_lock:
        traces = list()
        for req in reqs:
            for key in verdict_keys:
              reqs_dict[req][key] = verdict[key]
              traces.append(construct_event_trace(req, reqs_dict[req]))
    
    verdicts = evaluate_event_traces(traces)

@app.on_event("startup")
async def startup():
    app_state.host = 1
    app_state.request_counter = 0
    app_state.req_fail_cnt = 0
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
