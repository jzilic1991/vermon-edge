from fastapi import FastAPI, Form, Request, HTTPException
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
from util import Util, MetricsDeque, ObjectiveProcName, ObjectivePattern, pooling_task, construct_event_trace, evaluate_event_traces, print_metrics
from state import app_state
from asyncio import Lock

metrics_lock = Lock()
class TraceRequest(BaseModel):
    trace: str = None
    verdict: str = None

config_path = '/etc/config/service_paths.json'
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

async def forward_request(service_name: str, method: str, data: dict = None, path_params: dict = None):
    global metrics_dict
    
    if service_name not in BACKEND_SERVICES:
        raise HTTPException(status_code=404, detail="Service not found")

    url = BACKEND_SERVICES[service_name]
    if path_params:
        url = url.rstrip('/') + '/' + '/'.join(path_params.values())
    
    request_start_time = datetime.datetime.now() 
    
    async with httpx.AsyncClient(timeout = 30.0) as client:
        if method == "POST":
            response = await client.post(url, data = data)
        elif method == "GET":
            response = await client.get(url)
        else:
            raise HTTPException(status_code=405, detail="Method not allowed")
        
    async with metrics_lock:
        app_state.request_counter += 1
        if response.status_code in [200, 302]:
            response_end_time = datetime.datetime.now() 
            response_time = (response_end_time - request_start_time).total_seconds() * 1000
            metrics_dict[service_name].append(response_time)
            traces = list()
            traces.append(construct_event_trace(ObjectiveProcName.RESPONSE, response_time))
            evaluate_event_traces(traces)
        else:
            metrics_dict[service_name].failed_requests += 1
            app_state.req_fail_cnt += 1
        
        if app_state.request_counter % 50 == 0:
            print_metrics(metrics_dict)
    
    try:
        response_content = response.json()  
    except ValueError:
        response_content = response.text  

    return JSONResponse(content = response_content, status_code = response.status_code)

@app.on_event("startup")
async def start_pooling_task():
    app_state.host = 1
    app_state.request_counter = 0
    app_state.req_fail_cnt = 0
    app_state.mon_server = MonServer(sys.argv[1], sys.argv[2])
    asyncio.create_task(pooling_task())

@app.get("/")
async def get_index():
    result = await forward_request("index", "GET")
    return result

@app.get("/cart")
async def get_cart():
    # Forward the request to the cart service
    result = await forward_request("cart", "GET")
    return result

@app.post("/cart")
async def add_to_cart(product_id: str = Form(...), quantity: int = Form (...)):
    result = {"product_id": product_id, "quantity": quantity}
    response = await forward_request("cart", "POST", result)
    return response

@app.post("/cart/empty")
async def empty_cart():
    result = await forward_request("empty", "POST")
    return result

@app.post("/cart/checkout")
async def checkout(email: str = Form(...), \
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
    response = await forward_request("checkout", "POST", result)
    return response

@app.get("/logout")
async def logout():
    # Forward the request to the cart service (or another service if needed)
    result = await forward_request("logout", "GET")
    return result

@app.get("/product/{product_id}")
async def get_product(product_id: str):
    # Forward the request to the product catalog service
    response = await forward_request("product", "GET", path_params = {"product_id": product_id})
    return response

@app.post("/setCurrency")
async def set_currency(currency_code: str = Form(...)):
    result = {"currency_code": currency_code} 
    # Forward the request to the currency service
    response = await forward_request("currency", "POST", result)
    return response

def start_fastapi_server():
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("SERVER_PORT")), log_level="info")
