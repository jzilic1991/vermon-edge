from fastapi import FastAPI, Form, Request, HTTPException
from mon_server import MonServer
from constants import ObjectiveProcName
from util import Util, construct_event_trace, evaluate_event_traces, print_spec_violation_stats
from state import app_state
from preprocessor import Preprocessor  # 🆕 NEW for R1 logic
from asyncio import Lock
from datetime import datetime
import os, sys, uvicorn, asyncio

app = FastAPI()
verdict_lock = Lock()
verdict_counter = 0
pp = Preprocessor()  # 🆕 instantiate singleton

REQUIREMENTS = Util.get_req_obj_proc_dict()

# Structured verdict cache per requirement
reqs_dict = {
    requirement: {
        "objectives": {objective: {"verdict": 0, "timestamp": "N/A"} for objective in REQUIREMENTS[requirement]},
        "verdict": 0
    }
    for requirement in REQUIREMENTS.keys()
}

def print_req_status():
    header = "+-----------------+" + "+".join(["-" * 20 for _ in reqs_dict[next(iter(reqs_dict))]["objectives"]]) + "+--------------------+"
    print("\nRequirement status:")
    print(header)
    for req, data in reqs_dict.items():
        obj_names = " | ".join([str(obj.value).ljust(18) for obj in data["objectives"]])
        obj_values = " | ".join([str(v['verdict']).rjust(18) for v in data["objectives"].values()])
        print(f"| {str(req.value).ljust(15)} | {obj_names} | {'Verdict'.ljust(18)} |")
        print(header.replace('-', '='))
        print(f"| {' ' * 15} | {obj_values} | {str(data['verdict']).rjust(18)} |")
        print(header)

async def handling_verdicts(verdict: dict, user: str = "user1"):  # 🆕 Accept user ID
    global verdict_counter

    # Determine which requirement(s) this objective maps to
    related_reqs = [req for req, objs in REQUIREMENTS.items() if any(obj in verdict for obj in objs)]
    if not related_reqs:
        raise HTTPException(status_code=404, detail="Objective not related to any requirements")

    async with verdict_lock:
        for req in related_reqs:
            for key in verdict:
                if key in reqs_dict[req]["objectives"]:
                    reqs_dict[req]["objectives"][key]["verdict"] = verdict[key]
                    reqs_dict[req]["objectives"][key]["timestamp"] = datetime.now().isoformat()

                    # 🆕 R1 Synthesis logic
                    pp.cache_r1_verdict(user, key, "OK" if verdict[key] == 0 else "Violation")
                    r1_event = pp.synthesize_r1_event(user)
                    if r1_event:
                        print(f"[R1] Synthesized event: {r1_event}")
                        r1_verdicts = app_state.mon_server.evaluate_trace(r1_event)
                        print(f"[R1] Verdicts: {r1_verdicts}")

            trace = construct_event_trace(req, reqs_dict[req]["objectives"])
            results = evaluate_event_traces([trace])
            reqs_dict[req]["verdict"] = results[0]

        verdict_counter += 1
        if verdict_counter % 5 == 0:
            print_spec_violation_stats()
            print_req_status()

@app.on_event("startup")
async def startup():
    app_state.mon_server = MonServer(sys.argv[1], sys.argv[2])

# ✅ Unified endpoint to handle all objective verdicts
@app.post("/verdict/{objective}")
async def receive_verdict(objective: str, verdict: bool = Form(...)):
    try:
        objective_enum = ObjectiveProcName(objective)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid objective name")

    verdict_data = {objective_enum: int(verdict)}
    await handling_verdicts(verdict_data)
    return {"status": "OK"}

@app.get("/healthz")
async def health_check():
    return {"status": "OK"}

def start_req_fastapi_server():
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("SERVER_PORT", 8000)), log_level="info")

