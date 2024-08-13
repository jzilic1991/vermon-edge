from fastapi import FastAPI, Form, Request, HTTPException
from fastapi.responses import JSONResponse, PlainTextResponse
from pydantic import BaseModel
from collections import deque 
from mon_server import MonServer
import httpx
import sys
import os
import datetime
import statistics
import time
import json
import uvicorn
from tabulate import tabulate
from statistics import median

class MetricsDeque:
    def __init__(self, maxlen = 1000):
        self.dq = deque(maxlen = maxlen)
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
        return len(self.dq)

    def starting_time(self):
        return self.start_time

class TraceRequest(BaseModel):
    trace: str = None
    verdict: str = None

config_path = '/etc/config/service_paths.json'
with open(config_path, 'r') as file:
    service_paths = json.load(file)

print("Service paths: " + str(service_paths))

service_domain = os.getenv('SERVICE_DOMAIN')
for key in service_paths:
    service_paths[key] = service_paths[key].replace('http://', service_domain)

print("Service paths: " + str(service_paths))
BACKEND_SERVICES = service_paths
app = FastAPI()
mon_server = MonServer (sys.argv[1], sys.argv[2])
metrics_dict = {service: MetricsDeque(maxlen = 1000) for service in BACKEND_SERVICES}
request_counter = 0

def print_metrics():
    global metrics_dict
    headers = ["Type", "Name", "# reqs", "Avg (ms)", "Min (ms)", "Max (ms)", "Med (ms)", "req/s"]
    rows = []
    total_requests = 0
    all_timings = []
    
    for service_name, timings in metrics_dict.items():
        avg = timings.avg()
        min_time = timings.min()
        max_time = timings.max()
        med = timings.med()
        req_per_sec = timings.len() / (datetime.datetime.now() - timings.starting_time()).total_seconds()

        total_requests += timings.len()
        all_timings.extend(timings.dq)
        rows.append([
            "GET",  # Change to actual request type if needed
            service_name,
            timings.len(),
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
        f"{avg_agg:.2f}",
        f"{min_agg:.2f}",
        f"{max_agg:.2f}",
        f"{med_agg:.2f}",
        f"{req_per_sec_agg:.2f}",
    ])
    
    print(tabulate(rows, headers=headers, tablefmt="grid"))


async def forward_request(service_name: str, method: str, data: dict = None, path_params: dict = None):
    global metrics_dict, request_counter 
    
    if service_name not in BACKEND_SERVICES:
        raise HTTPException(status_code=404, detail="Service not found")

    url = BACKEND_SERVICES[service_name]
    if path_params:
        url = url.rstrip('/') + '/' + '/'.join(path_params.values())
    
    request_start_time = datetime.datetime.now() 
    
    async with httpx.AsyncClient() as client:
        if method == "POST":
            response = await client.post(url, data = data)
        elif method == "GET":
            response = await client.get(url)
        else:
            raise HTTPException(status_code=405, detail="Method not allowed")
    
    response_end_time = datetime.datetime.now() 
    response_time = (response_end_time - request_start_time).total_seconds() * 1000
    metrics_dict[service_name].append(response_time)
    trace = "@" + str(time.time()) + " responsetime (1, " + str(response_time) + ")"
    verdict = mon_server.evaluate_trace(trace)
    if verdict != "":
        print("Spec violation! Trace: " + str(verdict))
    
    request_counter += 1
    if request_counter % 10 == 0:
        print_metrics()
    
    try:
        response_content = response.json()  
    except ValueError:
        response_content = response.text  

    return JSONResponse(content = response_content, status_code = response.status_code)


@app.post("/edge-vermon")
async def trace_handler(request: TraceRequest):
    param = request.trace
    verdict_param = request.verdict
    
    if param is not None:
        print("Event trace: " + param)
        v = mon_server.evaluate_trace(param)
        return [v]

    if verdict_param is not None:
        print("Verdict trace:" + verdict_param)
        v = mon_server.evaluate_trace(verdict_param)
        print("Requirement evaluation: " + str(v))
        return {"evaluation": str(v)}

    raise HTTPException(status_code=400, detail="No valid parameters provided")

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
