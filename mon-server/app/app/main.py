from fastapi import FastAPI, Form, Request, HTTPException
from fastapi.responses import JSONResponse, PlainTextResponse
from pydantic import BaseModel
import httpx
import sys
import os

app = FastAPI()
FRONTEND_ADDR = os.getenv("FRONTEND_ADDR")

# Define a BaseModel for request validation
class TraceRequest(BaseModel):
    trace: str = None
    verdict: str = None

BACKEND_SERVICES = {
    "index": f"http://{FRONTEND_ADDR}/",  
    "currency": f"http://{FRONTEND_ADDR}/setCurrency",  
    "product": f"http://{FRONTEND_ADDR}/product",  
    "cart": f"http://{FRONTEND_ADDR}/cart",  
    "empty": f"http://{FRONTEND_ADDR}/cart/empty",  
    "checkout": f"http://{FRONTEND_ADDR}/cart/checkout",  
    "logout": f"http://{FRONTEND_ADDR}/logout",
}

# Utility function to forward requests to the backend services
async def forward_request(service_name: str, method: str, data: dict = None, path_params: dict = None):
    if service_name not in BACKEND_SERVICES:
        raise HTTPException(status_code=404, detail="Service not found")

    url = BACKEND_SERVICES[service_name]
    if path_params:
        url = url.rstrip('/') + '/' + '/'.join(path_params.values())
    
    async with httpx.AsyncClient() as client:
        if method == "POST":
            response = await client.post(url, data = data)
        elif method == "GET":
            response = await client.get(url)
        else:
            raise HTTPException(status_code=405, detail="Method not allowed")
        
        # print ("Response is " + str (response))
        # response.raise_for_status()  # Raise an exception for HTTP errors
        try:
          response_content = response.json()  # Attempt to parse JSON
        except ValueError:
          response_content = response.text  # Fallback to raw text if not JSON

        return JSONResponse(content=response_content, status_code=response.status_code)


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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("FASTAPI_PORT")), log_level="info")
