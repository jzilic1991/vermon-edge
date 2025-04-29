import time

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
        self.additem_cache = {}        # (user, item) -> (timestamp)
        self.emptycart_cache = {}      # user -> timestamp
        self.cache_ttl_seconds = 300   # 5 minutes TTL for cache entries

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
        return f"@{timepoint}\n{event_str}"

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

        # Before anything, clean old cache entries
        self.clean_caches(event.get("timestamp", time.time()))

        if event["type"] == "AddItem":
            item_id = event.get("item") or event.get("product_id")
            if item_id:
                self.cache_additem(event["user"], item_id, event["timestamp"])
            else:
                print(f"Warning: AddItem missing item_id! Event: {event}")

        elif event["type"] == "EmptyCart":
            if "user" in event:
                self.cache_emptycart(event["user"], event["timestamp"])
            else:
                print(f"Warning: EmptyCart missing user {event}")

        elif event["type"] == "GetCart":
            if "user" in event:
                cart_contents = event.get("cart", [])
                events = self.process_get_cart(event["user"], cart_contents, event["timestamp"])
                for evt_type, evt_str in events:
                    with open(self.output_path, "a") as f:
                        f.write(evt_str + "\n")
                    routed_verifiers.update(self.event_to_verifier.get(evt_type, []))
            else:
                print(f"Warning: GetCart missing user {event}")

        # Always check direct mapping too
        if event["type"] in self.event_to_verifier:
            routed_verifiers.update(self.event_to_verifier[event["type"]])

        return list(routed_verifiers)

