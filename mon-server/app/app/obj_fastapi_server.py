from fastapi import FastAPI, Form, Request, HTTPException, Body
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from mon_server import MonServer
import httpx
import sys
import os
import datetime
import statistics
import json
import uvicorn
import asyncio
import time
import re
from util import Util, MetricsDeque, pooling_task, construct_event_trace, evaluate_event_traces, print_metrics, print_spec_violation_stats
from constants import ObjectiveProcName, REQ_VERIFIER_SERVICE_URL
from state import app_state
from asyncio import Lock
from http_to_event_mapper import infer_event_from_http
from debug_utils import DebugBuffer


http_debug_buffer = DebugBuffer("HTTP Events")
metrics_lock = Lock()
session_lock = Lock()  # NEW: Lock for session maps
config_path = '/etc/service-config/service_paths.json'
with open(config_path, 'r') as file:
    service_paths = json.load(file)

service_domain = os.getenv('SERVICE_DOMAIN')
for key in service_paths:
    service_paths[key] = service_paths[key].replace('http://', service_domain)

BACKEND_SERVICES = service_paths
app = FastAPI()
metrics_dict = {service: MetricsDeque(maxlen=10000) for service in BACKEND_SERVICES}

user_to_session = {}
session_to_user = {}
session_timestamps = {}

SESSION_TIMEOUT_SECONDS = 60

async def cleanup_expired_sessions():
    #print("[DEBUG] cleanup expired sessions")
    now = datetime.datetime.now()
    expired_users = []
    async with session_lock:
        for user, timestamps in session_timestamps.items():
            last_seen_str = timestamps.get("last_seen")
            if last_seen_str:
                last_seen = datetime.datetime.strptime(last_seen_str, "%Y-%m-%d %H:%M:%S")
                if (now - last_seen).total_seconds() > SESSION_TIMEOUT_SECONDS:
                    expired_users.append(user)

        for user in expired_users:
            session = user_to_session.pop(user, None)
            if session:
                session_to_user.pop(session, None)
            session_timestamps.pop(user, None)
            print(f"[CLEANUP] Removed expired session for user '{user}'")

async def print_user_session_table():
    print(f"\n[SESSION LOG @ {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}]")
    async with session_lock:
        if not user_to_session:
            print("[INFO] No active sessions.")
            return
        print("=== User to Session Mapping ===")
        print("{:>5} | {:<36} | {:<36} | {:<20} | {:<20} | {:<20}".format(
            "#", "User ID", "Session ID", "Created At", "Last Seen", "Last Change"
        ))
        print("-" * 170)
        for i, (user, session) in enumerate(user_to_session.items(), 1):
            timestamps = session_timestamps.get(user, {})
            created_at = timestamps.get("created", "-")
            last_seen = timestamps.get("last_seen", "-")
            last_change = timestamps.get("last_change", "-")
            print("{:>5} | {:<36} | {:<36} | {:<20} | {:<20} | {:<20}".format(
                i, user, session, created_at, last_seen, last_change
            ))

async def periodic_session_log_task():
    while True:
        try:
            print("[PERIODIC] Checking sessions...")
            await cleanup_expired_sessions()
            await print_user_session_table()
        except Exception as e:
            print(f"[ERROR] Session log task failed: {e}")
        await asyncio.sleep(10)


async def forward_request(service_name: str, method: str, data: dict = None, path_params: dict = None, request: Request = None):
    global metrics_dict

    if service_name not in BACKEND_SERVICES:
        raise HTTPException(status_code=404, detail="Service not found")

    url = BACKEND_SERVICES[service_name]
    if path_params:
        url = url.rstrip('/') + '/' + '/'.join(path_params.values())

    request_start_time = datetime.datetime.now()
    params = dict(request.query_params) if request else None

    user = request.query_params.get("user", "user1") if request else "user1"
    cookies = {}
    session_id = None
    async with session_lock:
        session_id = user_to_session.get(user)
        if session_id:
            cookies["shop_session-id"] = session_id

    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    forward_data = {k: v for k, v in (data or {}).items() if k != "user"}

    async with httpx.AsyncClient(timeout=60.0, follow_redirects=False) as client:
        req = client.build_request(
            method=method,
            url=url,
            data=forward_data if method == "POST" else None,
            params=params,
            cookies=cookies,
            headers=headers
        )

        print("\n🔎 OUTGOING HTTP REQUEST")
        print(f"  Method: {method}")
        print(f"  URL: {req.url}")
        print(f"  Cookies (dict): {cookies}")
        print(f"  Cookie header: {req.headers.get('cookie')}")
        print(f"  Headers: {dict(req.headers)}")
        print(f"  Body: {req.content.decode() if req.content else '<empty>'}")

        response = await client.send(req)

        if response.status_code == 302:
            redirect_path = response.headers.get("location")
            if redirect_path:
                from urllib.parse import urljoin
                redirect_url = urljoin(str(req.url), redirect_path)
                response = await client.get(redirect_url, cookies=cookies, headers=headers)

        print("\n📥 INCOMING HTTP RESPONSE")
        print(f"  Status: {response.status_code}")
        print(f"  Set-Cookie: {response.headers.get('set-cookie')}")
        print(f"  Final Session Cache: {user_to_session.get(user)}")

        try:
            response_content = response.json()
        except ValueError:
            response_content = response.text

    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if user in session_timestamps:
        session_timestamps[user]["last_seen"] = now_str
    
    set_cookie = response.headers.get("set-cookie")
    if set_cookie:
      for part in set_cookie.split(";"):
        if "shop_session-id=" in part:
            new_session_id = part.split("shop_session-id=")[-1].strip()
            session_id = new_session_id
            async with session_lock:
                if user not in user_to_session:
                    user_to_session[user] = session_id
                    session_to_user[session_id] = user
                    session_timestamps[user] = {
                        "created": now_str,
                        "last_seen": now_str,
                        "last_change": now_str  # ✅ ADD THIS FIELD
                    }
                    print(f"[INFO] Stored new session for user '{user}': {session_id}")
                else:
                    # ✅ Only update last_change if session ID actually changed
                    if user_to_session[user] != session_id:
                        session_timestamps[user]["last_change"] = now_str
                        user_to_session[user] = session_id
                        session_to_user[session_id] = user
                    session_timestamps[user]["last_seen"] = now_str

    async with metrics_lock:
        app_state.request_counter += 1

        if response.status_code in [200, 302]:
            elapsed_ms = (datetime.datetime.now() - request_start_time).total_seconds() * 1000
            metrics_dict[service_name].dq.append(elapsed_ms)

            event_type = infer_event_from_http(method, "/" + service_name)
            quantity, item = None, None
            if method == "POST" and data:
                item = data.get("product_id")
            
            if service_name == "cart" and method.upper() == "GET":
                try:
                    quantity = app_state.mon_server._preprocessor.extract_cart_quantity_from_html(response.text)
                    # print(f'[DEBUG][MONPOLY] GetCart("{user}", {quantity})')
                except Exception as e:
                    print(f'[DEBUG][MONPOLY] Failed to parse cart HTML: {e}')
            
            event = {
                "type": event_type,
                "user": user,
                "session": session_id,
                "timestamp": time.time(),
            }
            if item:
                event["item"] = item

            if quantity:
                event["quantity"] = quantity
            
            verifier_events = app_state.mon_server._preprocessor.transform_event(event)
            # print("[DEBUG] Verifier events: " + str(verifier_events))
            
            for verifier, trace_list in verifier_events.items():
                for trace in trace_list:
                    #print(f"Sending to {verifier} a trace: {trace}")
                    app_state.mon_server.evaluate_trace(trace, [verifier])
        else:
            metrics_dict[service_name].failed_requests += 1
            app_state.req_fail_cnt += 1

        if app_state.request_counter % 50 == 0:
            print_metrics(metrics_dict)
            print_spec_violation_stats()

    return JSONResponse(content=response_content, status_code=response.status_code)


@app.on_event("startup")
async def start_pooling_task():
    app_state.mon_server = MonServer(sys.argv[1], sys.argv[2])
    asyncio.create_task(pooling_task())
    asyncio.create_task(periodic_session_log_task())  # ✅ new: periodic session print task


@app.get("/")
async def get_index(request: Request):
    return await forward_request("index", "GET", request=request)

@app.get("/cart")
async def get_cart(request: Request):
    return await forward_request("cart", "GET", request=request)

@app.post("/cart")
async def add_to_cart(request: Request, product_id: str = Form(...), quantity: int = Form(...)):
    data = {"product_id": product_id, "quantity": quantity}
    return await forward_request("cart", "POST", data, request=request)

@app.post("/cart/empty")
async def empty_cart(request: Request):
    return await forward_request("empty", "POST", {}, request=request)

@app.post("/cart/checkout")
async def checkout(request: Request,
                   email: str = Form(...),
                   street_address: str = Form(...),
                   zip_code: str = Form(...),
                   city: str = Form(...),
                   state: str = Form(...),
                   country: str = Form(...),
                   credit_card_number: str = Form(...),
                   credit_card_expiration_month: int = Form(...),
                   credit_card_expiration_year: int = Form(...),
                   credit_card_cvv: str = Form(...)):
    data = {
        "email": email, "street_address": street_address, "zip_code": zip_code,
        "city": city, "state": state, "country": country,
        "credit_card_number": credit_card_number,
        "credit_card_expiration_month": credit_card_expiration_month,
        "credit_card_expiration_year": credit_card_expiration_year,
        "credit_card_cvv": credit_card_cvv
    }
    return await forward_request("checkout", "POST", data, request=request)

@app.get("/logout")
async def logout(request: Request):
    return await forward_request("logout", "GET", request=request)

@app.get("/product/{product_id}")
async def get_product(request: Request, product_id: str):
    return await forward_request("product", "GET", path_params={"product_id": product_id}, request=request)

@app.post("/setCurrency")
async def set_currency(request: Request, currency_code: str = Form(...)):
    return await forward_request("currency", "POST", {"currency_code": currency_code}, request=request)

@app.post("/metrics")
async def receive_metrics(data: dict = Body(...)):
    service_name = data.get("service_name", "unknown")
    metrics = data.get("metrics", {})
    cpu = metrics.get("cpu", 0.0)
    memory = metrics.get("memory", 0.0)
    print(f"[{service_name.upper()}] CPU: {cpu:.2f}% | Memory: {memory:.2f} MB")
    return {"status": "ok"}

def start_obj_fastapi_server():
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("SERVER_PORT")), log_level="info")

