class Preprocessor:
    _instance = None

    def __new__(cls, output_path="vermon_stream.log"):
        if cls._instance is None:
            cls._instance = super(Preprocessor, cls).__new__(cls)
            cls._instance.__initialized = False
        return cls._instance

    def __init__(self, output_path="vermon_stream.log"):
        if self.__initialized:
            return
        self.__initialized = True
        self.output_path = output_path
        self.additem_cache = {}           # For R1.1
        self.emptycart_cache = {}         # For R1.2

        self.event_to_verifier = {
            "reflect_latency": ["R1.1_latency"],
            "cart_empty_latency": ["R1.2_empty_cart"],
            "CartOp": ["R1.3_failure_rate"],
            "CartServiceUsage": ["R1.4_resource_usage"],
            # Primitive direct API calls:
            "AddItem": ["R1.1_latency"],
            "GetCart": ["R1.1_latency"],
            "EmptyCart": ["R1.2_empty_cart"],
            "GetCartEmpty": ["R1.2_empty_cart"]
        }

    def emit_event(self, timepoint, event_str):
        return f"@{timepoint}\n{event_str}"

    def process_event(self, event):
        if event["type"] == "AddItem":
            self.additem_cache[(event["user"], event["item"])] = event["timestamp"]

        elif event["type"] == "GetCart":
            key = (event["user"], event["item"])
            if key in self.additem_cache:
                d = round(event["timestamp"] - self.additem_cache[key], 3)
                return ("reflect_latency", self.emit_event(event["timestamp"], f'reflect_latency("{key[0]}", "{key[1]}", {d})'))

        elif event["type"] == "EmptyCart":
            self.emptycart_cache[event["user"]] = event["timestamp"]

        elif event["type"] == "GetCartEmpty":
            if event["user"] in self.emptycart_cache and event["cart"] == 0:
                d = round(event["timestamp"] - self.emptycart_cache[event["user"]], 3)
                return ("cart_empty_latency", self.emit_event(event["timestamp"], f'cart_empty_latency("{event["user"]}", {d})'))

        elif event["type"] == "CartOp":
            label = "fail" if event["status"] < 200 or event["status"] >= 300 else "ok"
            return ("CartOp", self.emit_event(event["timestamp"], f'CartOp("{event["user"]}", "{event["op"]}", "{label}")'))

        elif event["type"] == "Metrics":
            return ("CartServiceUsage", self.emit_event(event["timestamp"], f'CartServiceUsage({event["cpu"]}, {event["mem"]})'))

        return None
    

    def transform_event(self, event):
        result = self.process_event(event)
        routed_verifiers = set()

        # Primary transformed output event
        if result:
            evt_type, output = result
            with open(self.output_path, "a") as f:
                f.write(output + "\n")
            routed_verifiers.update(self.event_to_verifier.get(evt_type, []))

        # Route based on primitive event name as fallback
        if event["type"] in self.event_to_verifier:
            routed_verifiers.update(self.event_to_verifier[event["type"]])

        return list(routed_verifiers)
