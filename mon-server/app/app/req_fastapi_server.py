from fastapi import FastAPI, Form, Request, HTTPException
from mon_server import MonServer
import httpx
import uvicorn
import asyncio
import os
from util import Util, construct_event_trace, evaluate_event_traces
from constants import ObjectiveProcName
from state import app_state
from asyncio import Lock

verdict_lock = Lock()
REQUIREMENTS = Util.get_req_obj_dict_mapping()
app = FastAPI()
reqs_stats = {requirement: 0 for requirement in REQUIREMENTS.keys()}
reqs_dict = {requirement: {objective: False for objective in REQUIREMENTS[requirement]} for requirement in REQUIREMENTS.keys()} 
async def handling_verdicts(verdict: dict):
    global reqs_dict

    if not verdict.keys()[0] in REQUIREMENTS:
        raise HTTPException(status_code=404, detail="Objective not related to none of requirements")

    reqs = list()
    for req, objs in REQUIREMENTS.items():
        if verdict.keys()[0] in objs:
            reqs.append(req)
    
    async with verdict_lock:
        traces = list()
        for req in reqs:
            reqs_dict[req][verdict.keys()[0]] = verdict.values()[0]
            traces.append(construct_event_trace(req, reqs_dict[req]))
        
    evaluate_event_traces(traces)
    return None

@app.post("/response")
async def response(responsetime: bool = Form(...)):
    verdict = {ObjectiveProcName.RESPONSE: responsetime}
    result = await handling_verdicts(verdict)
    return None

@app.post("/throughput")
async def throughput(throughput: bool = Form(...)):
    verdict = {ObjectiveProcName.TH_REQS: throughput}
    result = await handling_verdicts(verdict)
    return None

@app.post("/defect")
async def defect(defect: bool = Form(...)):
    verdict = {ObjectiveProcName.REL_DEFECT: defect}
    result = await handling_verdicts(verdict)
    return None

@app.get("/healthz")
async def health_check():
    return {"status": "OK"}

def start_req_fastapi_server():
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("SERVER_PORT")), log_level="info")
