# DebugBuffer for visibility
from collections import deque

class DebugBuffer:
    def __init__(self, name, capacity=100, print_every=10):
        self.name = name
        self.buffer = deque(maxlen=capacity)
        self.counter = 0
        self.print_every = print_every

    def add(self, item):
        self.buffer.append(item)
        self.counter += 1
        if self.counter % self.print_every == 0:
            print(f"\n[DebugBuffer: {self.name}] Last {len(self.buffer)} items:")
            for i, entry in enumerate(self.buffer):
                print(f"{i+1:02d}: {entry}")

