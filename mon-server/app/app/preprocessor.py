import time

class Preprocessor:
    _instance = None

    def __new__(cls, output_path="/tmp/vermon_stream.log"):
        if cls._instance is None:
            cls._instance = super(Preprocessor, cls).__new__(cls)
            cls._instance.__initialized = False
        return cls._instance

    def __init__(self, output_path="/tmp/vermon_stream.log"):
        if self.__initialized:
            return
        self.__initialized = True
        self.output_path = output_path
        self.additem_cache = {}        # (user, item) -> timestamp
        self.emptycart_cache = {}      # user -> timestamp
        self.cache_ttl_seconds = 300   # 5 minutes TTL

        self.event_to_verifier = {
            "reflect_latency": ["R1.1_latency"],
            "cart_empty_latency": ["R1.2_empty_cart"],
            "CartOp": ["R1.3_failure_rate"],
            "CartServiceUsage": ["R1.4_resource_usage"],
            "AddItem": ["R1.1_latency"],
            "GetCart": ["R1.1_latency"],
            "EmptyCart": ["R1.2_empty_cart"],
            "GetCartEmpty": ["R1.2_empty_cart"]
        }

    def emit_event(self, timepoint, event_str):
        return f"@{int(timepoint)}\n{event_str}"

    def cache_additem(self, user_id, item_id, timestamp):
        self.additem_cache[(user_id, item_id)] = timestamp

    def cache_emptycart(self, user_id, timestamp):
        self.emptycart_cache[user_id] = timestamp

    def clean_caches(self, current_time=None):
        if current_time is None:
            current_time = time.time()

        # Clean additem_cache
        old_keys = [key for key, ts in self.additem_cache.items() if current_time - ts > self.cache_ttl_seconds]
        for key in old_keys:
            del self.additem_cache[key]

        # Clean emptycart_cache
        old_users = [user for user, ts in self.emptycart_cache.items() if current_time - ts > self.cache_ttl_seconds]
        for user in old_users:
            del self.emptycart_cache[user]

    def process_get_cart(self, user_id, cart_contents, timestamp):
        events = []

        if user_id in self.emptycart_cache and len(cart_contents) == 0:
            d = round(timestamp - self.emptycart_cache[user_id], 3)
            events.append(("cart_empty_latency", self.emit_event(timestamp, f'cart_empty_latency("{user_id}", {d})')))

        for item_id in cart_contents:
            if (user_id, item_id) in self.additem_cache:
                d = round(timestamp - self.additem_cache[(user_id, item_id)], 3)
                events.append(("reflect_latency", self.emit_event(timestamp, f'reflect_latency("{user_id}", "{item_id}", {d})')))

        return events

    def transform_event(self, event):
        routed_verifiers = set()
        timestamp = event["timestamp"]
        user = event.get("user", "unknown")

        if event["type"] == "AddItem":
            item_id = event.get("item") or event.get("product_id")
            if item_id:
                self.cache_additem(user, item_id, timestamp)
                event_str = self.emit_event(timestamp, f'AddItem("{user}", "{item_id}")')
                routed_verifiers.add("R1.1_latency")
                # [NO file write]
            else:
                print(f"Warning: AddItem missing item_id! Event: {event}")

        elif event["type"] == "GetCart":
            cart_contents = event.get("cart", [])
            events = self.process_get_cart(user, cart_contents, timestamp)
            for evt_type, evt_str in events:
                routed_verifiers.update(self.event_to_verifier.get(evt_type, []))

        elif event["type"] == "EmptyCart":
            self.cache_emptycart(user, timestamp)

        elif event["type"] == "GetCartEmpty":
            if user in self.emptycart_cache and event.get("cart", 0) == 0:
                d = round(timestamp - self.emptycart_cache[user], 3)
                event_str = self.emit_event(timestamp, f'cart_empty_latency("{user}", {d})')
                routed_verifiers.add("R1.2_empty_cart")

        elif event["type"] == "CartOp":
            label = "fail" if event["status"] < 200 or event["status"] >= 300 else "ok"
            event_str = self.emit_event(timestamp, f'CartOp("{user}", "{event["op"]}", "{label}")')
            routed_verifiers.add("R1.3_failure_rate")

        elif event["type"] == "Metrics":
            cpu, mem = event.get("cpu", 0.0), event.get("mem", 0.0)
            event_str = self.emit_event(timestamp, f'CartServiceUsage({cpu}, {mem})')
            routed_verifiers.add("R1.4_resource_usage")

        # Also route based on raw primitive event type if mapped
        if event["type"] in self.event_to_verifier:
            routed_verifiers.update(self.event_to_verifier[event["type"]])

        return list(routed_verifiers)

    def format_for_monpoly(self, event):
        timestamp = event.get("timestamp", time.time())
        user = event.get("user", "unknown")

        if event["type"] == "AddItem":
            item_id = event.get("item") or event.get("product_id", "unknown")
            return self.emit_event(timestamp, f'AddItem("{user}", "{item_id}")')

        elif event["type"] == "GetCart":
            return self.emit_event(timestamp, f'GetCart("{user}")')

        elif event["type"] == "EmptyCart":
            return self.emit_event(timestamp, f'EmptyCart("{user}")')

        elif event["type"] == "GetCartEmpty":
            return self.emit_event(timestamp, f'GetCartEmpty("{user}")')

        elif event["type"] == "CartOp":
            label = "fail" if event["status"] < 200 or event["status"] >= 300 else "ok"
            return self.emit_event(timestamp, f'CartOp("{user}", "{event["op"]}", "{label}")')

        elif event["type"] == "Metrics":
            cpu, mem = event.get("cpu", 0.0), event.get("mem", 0.0)
            return self.emit_event(timestamp, f'CartServiceUsage({cpu}, {mem})')

        else:
            print(f"Warning: Unknown event type for formatting: {event}")
            return None

