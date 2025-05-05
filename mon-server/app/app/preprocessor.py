import time
from debug_utils import DebugBuffer
from collections import deque
synthetic_buffer = DebugBuffer("Synthetic Events")

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
          "cart_empty_latency": ["R1.2_empty_cart_latency"],
          "EmptyCart": ["R1.2_empty_cart_latency", "R1.2_empty_cart_sequence"],
          "GetCart": ["R1.2_empty_cart_latency", "R1.2_empty_cart_sequence"],
          "CartOp": ["R1.3_failure_rate"],
          "CartServiceUsage": ["R1.4_resource_usage"]
        }
        self.fifo_buffers = {name: [] for name in self.event_to_verifier.keys()}
        self.fifo_limit = 100
        self.fifo_print_every = 10
        self.event_counter = {name: 0 for name in self.event_to_verifier.keys()}

    def emit_event(self, timestamp: int, event_str: str) -> str:
        # Determine which verifiers this event should be sent to
        event_name = event_str.split("(")[0]
        verifiers = self.event_to_verifier.get(event_name, [])

        for verifier in verifiers:
            if verifier not in self.fifo_buffers:
                self.fifo_buffers[verifier] = deque(maxlen=100)
                self.event_counter[verifier] = 0

            self.fifo_buffers[verifier].append(f"{timestamp} {event_str}")
            self.event_counter[verifier] += 1

            if self.event_counter[verifier] % 10 == 0:
                print(f"\n[Preprocessor] Last {len(self.fifo_buffers[verifier])} entries for verifier '{verifier}':")
                for entry in list(self.fifo_buffers[verifier]):
                    print(entry)

        return f"{timestamp} {event_str}"

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
        #print('[DEBUG] Processing GetCart for synthetic events')
        #print(f"[DEBUG] GetCart contents: {cart_contents}")
        #print(f"[DEBUG] AddItem cache keys: {list(self.additem_cache.keys())}")
        if user_id in self.emptycart_cache and len(cart_contents) == 0:
            d = round(timestamp - self.emptycart_cache[user_id], 3)
            evt_type = "cart_empty_latency"
            evt_str = self.emit_event(timestamp, f'cart_empty_latency("{user_id}", {d})')
            events.append((evt_type, evt_str))
            #print(f'[DEBUG] Emitting synthetic: {evt_type} -> {evt_str}')
        
        for item_id in cart_contents:
            if (user_id, item_id) in self.additem_cache:
                d = round(timestamp - self.additem_cache[(user_id, item_id)], 3)
                evt_type = "reflect_latency"
                evt_str = self.emit_event(timestamp, f'reflect_latency("{user_id}", "{item_id}", {d})')
                events.append((evt_type, evt_str))
                #print(f'[DEBUG] Emitting synthetic: {evt_type} -> {evt_str}')
        
        return events

    def transform_event(self, event):
        routed_verifiers = set()
        timestamp = event["timestamp"]
        user = event.get("user", "unknown")
        # print('[DEBUG] Transforming event:', event)

        if event["type"] == "AddItem":
            item_id = event.get("item") or event.get("product_id")
            if item_id:
                self.additem_cache[(user, item_id)] = timestamp
                #print(f"[DEBUG] Cached AddItem: ({user}, {item_id}) at {timestamp}")
                event_str = self.emit_event(timestamp, f'AddItem("{user}", "{item_id}")')
                routed_verifiers.add("R1.1_latency")
                print(f'[DEBUG] Routing to verifier: {routed_verifiers}')
            else:
                print(f"Warning: AddItem missing item_id! Event: {event}")

        elif event["type"] == "GetCart":
            cart_contents = event.get("cart", [])
            events = self.process_get_cart(user, cart_contents, timestamp)
            for evt_type, evt_str in events:
                routed_verifiers.update(self.event_to_verifier.get(evt_type, []))
                print(f"[DEBUG] Routed synthetic event '{evt_type}' to: {self.event_to_verifier.get(evt_type, [])}")
                #print(f"[DEBUG] Emitting synthetic event to MonPoly: {evt_str}")

        elif event["type"] == "EmptyCart":
            self.cache_emptycart(user, timestamp)

        elif event["type"] == "GetCartEmpty":
            if user in self.emptycart_cache and event.get("cart", 0) == 0:
                d = round(timestamp - self.emptycart_cache[user], 3)
                event_str = self.emit_event(timestamp, f'cart_empty_latency("{user}", {d})')
                routed_verifiers.add("R1.2_empty_cart")
                print(f'[DEBUG] Routing to verifier: {routed_verifiers}')

        elif event["type"] == "CartOp":
            label = "fail" if event["status"] < 200 or event["status"] >= 300 else "ok"
            event_str = self.emit_event(timestamp, f'CartOp("{user}", "{event["op"]}", "{label}")')
            routed_verifiers.add("R1.3_failure_rate")
            print(f'[DEBUG] Routing to verifier: {routed_verifiers}')

        elif event["type"] == "Metrics":
            cpu, mem = event.get("cpu", 0.0), event.get("mem", 0.0)
            event_str = self.emit_event(timestamp, f'CartServiceUsage({cpu}, {mem})')
            routed_verifiers.add("R1.4_resource_usage")
            print(f'[DEBUG] Routing to verifier: {routed_verifiers}')

        # Also route based on raw primitive event type if mapped
        if event["type"] in self.event_to_verifier:
            routed_verifiers.update(self.event_to_verifier[event["type"]])
            print(f"[DEBUG] Routed raw event type '{event['type']}' to: {self.event_to_verifier.get(event['type'], [])}")
        
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
            # print(f"Warning: Unknown event type for formatting: {event}")
            return None

    def cache_r1_verdict(self, user, subreq, verdict):
        if not hasattr(self, "r1_verdict_cache"):
            self.r1_verdict_cache = {}
        if user not in self.r1_verdict_cache:
            self.r1_verdict_cache[user] = {}
        self.r1_verdict_cache[user][subreq] = verdict
   
    def synthesize_r1_event(self, user, timestamp=None):
        if user not in self.r1_verdict_cache:
            return None

        subreqs = self.r1_verdict_cache[user]
        required = ["R1.1_latency", "R1.2_empty_cart", "R1.3_failure_rate", "R1.4_resource_usage"]

        if not all(r in subreqs for r in required):
            return None

        if timestamp is None:
            timestamp = time.time()

        # 0 = OK, 1 = Violation (already set by upstream logic)
        verdicts = [1 if subreqs[r] == "Violation" else 0 for r in required]
        event = f'R1("{user}", {verdicts[0]}, {verdicts[1]}, {verdicts[2]}, {verdicts[3]})'
        return self.emit_event(timestamp, event)

