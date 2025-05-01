from fastapi import FastAPI, Form, Request, HTTPException, Body
from fastapi.responses import JSONResponse, PlainTextResponse
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
from statistics import median
from util import Util, MetricsDeque, pooling_task, construct_event_trace, evaluate_event_traces, print_metrics, print_spec_violation_stats, send_verdict_to_remote_service
from constants import ObjectiveProcName, REQ_VERIFIER_SERVICE_URL
from state import app_state
from asyncio import Lock
from http_to_event_mapper import infer_event_from_http
import time  # Add this if not imported yet

metrics_lock = Lock()
config_path = '/etc/service-config/service_paths.json'
with open(config_path, 'r') as file:
    service_paths = json.load(file)

# print("Service paths: " + str(service_paths))

service_domain = os.getenv('SERVICE_DOMAIN')
for key in service_paths:
    service_paths[key] = service_paths[key].replace('http://', service_domain)

# print("Service paths: " + str(service_paths))
BACKEND_SERVICES = service_paths
app = FastAPI()
metrics_dict = {service: MetricsDeque(maxlen = 10000) for service in BACKEND_SERVICES}

async def forward_request(service_name: str, method: str, data: dict = None, path_params: dict = None, request: Request = None):
    global metrics_dict

    if service_name not in BACKEND_SERVICES:
        raise HTTPException(status_code=404, detail="Service not found")

    url = BACKEND_SERVICES[service_name]
    if path_params:
        url = url.rstrip('/') + '/' + '/'.join(path_params.values())

    request_start_time = datetime.datetime.now()

    params = dict(request.query_params) if request else None

    async with httpx.AsyncClient(timeout=60.0) as client:
      if method == "POST":
        response = await client.post(url, data=data, params=params)
      elif method == "GET":
        response = await client.get(url, params=params)
      else:
        raise HTTPException(status_code=405, detail="Method not allowed")

    try:
        response_content = response.json()
    except ValueError:
        response_content = response.text

    async with metrics_lock:
        app_state.request_counter += 1

        # Only if successful request, create and verify event
        if response.status_code in [200, 302]:
            event_type = infer_event_from_http(method, "/" + service_name)
            user = "user1"  # default
            item = None
            
            if request:
                # First try from query param (GET or POST with ?user=...)
                user = request.query_params.get("user", user)

                # Then fall back to POST body (form-encoded)
                if method == "POST" and data:
                  user = data.get("user", user)

            # For POST, extract product_id (not user, since it's in query param not form)
            if method == "POST" and data:
                item = data.get("product_id")

            event = {
                "type": event_type,
                "user": user,
                "timestamp": time.time(),
            }
            if method == "POST" and data and "product_id" in data:
                event["item"] = data["product_id"]

            print(f"[DEBUG] Emitting event: {event}")
            routed_verifiers = app_state.mon_server._preprocessor.transform_event(event)
            formatted_event = app_state.mon_server._preprocessor.format_for_monpoly(event)
            if formatted_event:
                print(f"[DEBUG] Evaluating trace: {formatted_event}")
                verdicts = app_state.mon_server.evaluate_trace(formatted_event)
                print(f"[DEBUG] Verdicts: {verdicts}")

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

@app.get("/")
async def get_index(request: Request):
    result = await forward_request("index", "GET", request=request)
    return result

@app.get("/cart")
async def get_cart(request: Request):
    # Forward the request to the cart service
    result = await forward_request("cart", "GET", request=request)
    return result

@app.post("/cart")
async def add_to_cart(
    request: Request,
    product_id: str = Form(...),
    quantity: int = Form(...),
    user: str = Form(...)  # ✅ ADD THIS LINE
):
    result = {"product_id": product_id, "quantity": quantity, "user": user}  # ✅ INCLUDE user
    response = await forward_request("cart", "POST", result, request=request)
    return response

@app.post("/cart/empty")
async def empty_cart(request: Request):
    result = await forward_request("empty", "POST", request=request)
    return result

@app.post("/cart/checkout")
async def checkout(request: Request, \
                   email: str = Form(...), \
                   street_address: str = Form(...), \
                   zip_code: str = Form(...), \
                   city: str = Form(...), \
                   state: str = Form(...), \
                   country: str = Form(...), \
                   credit_card_number: str = Form(...), \
                   credit_card_expiration_month: int = Form(...),\
                   credit_card_expiration_year: int = Form(...),\
                   credit_card_cvv: str = Form(...)):
    result = {"email": email, "street_address": street_address, "zip_code": zip_code, "city": city, \
      "state": state, "country": country, "credit_card_number": credit_card_number, \
      "credit_card_expiration_month": credit_card_expiration_month,\
      "credit_card_expiration_year": credit_card_expiration_year,\
      "credit_card_cvv": credit_card_cvv}

    # Forward the request to the cart service
    response = await forward_request("checkout", "POST", result, request=request)
    return response

@app.get("/logout")
async def logout(request: Request):
    # Forward the request to the cart service (or another service if needed)
    result = await forward_request("logout", "GET", request=request)
    return result

@app.get("/product/{product_id}")
async def get_product(request: Request, product_id: str):
    # Forward the request to the product catalog service
    response = await forward_request("product", "GET", path_params = {"product_id": product_id}, request=request)
    return response

@app.post("/setCurrency")
async def set_currency(request: Request, currency_code: str = Form(...)):
    result = {"currency_code": currency_code} 
    # Forward the request to the currency service
    response = await forward_request("currency", "POST", result, request=request)
    return response

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
