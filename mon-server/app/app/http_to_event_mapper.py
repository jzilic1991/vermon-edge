# app/app/http_to_event_mapper.py

def infer_event_from_http(method: str, path: str, data: dict = None):
    # Normalize the path
    path = path.rstrip("/")

    if method == "POST" and path == "/cart":
        return "AddItem"
    elif method == "GET" and path == "/cart":
        return "GetCart"
    elif method == "POST" and path == "/cart/empty":
        return "EmptyCart"
    elif method == "GET" and path == "/cart/empty":
        return "GetCartEmpty"
    # You can add more rules later

    return None

