import asyncio
import re
from multiprocessing import Process

class Monpoly(Process):

    def __init__(self, t_q, v_q, requirement_to_verify):
        super().__init__()
        self._t_q = t_q
        self._v_q = v_q
        self._requirement_to_verify = requirement_to_verify

    def get_verifier_name(self):
        return self._requirement_to_verify

    def get_incoming_queue(self):
        return self._t_q

    def get_outgoing_queue(self):
        return self._v_q

    def run(self):
        asyncio.run(self.__processing())

    async def __processing(self):
        proc = await asyncio.create_subprocess_exec(
            "monpoly",
            "-sig", f"online-boutique-reqs/{self._requirement_to_verify}.sig",
            "-formula", f"online-boutique-reqs/{self._requirement_to_verify}.mfotl",
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE
        )
        print(f"[Monpoly] {self._requirement_to_verify} process is started!")

        while True:
            trace = self._t_q.get()
            if not trace:
                continue

            if isinstance(trace, str):
                trace_str = trace
            elif isinstance(trace, dict):
                print(f"[ERROR] Raw dict passed to Monpoly for {self._requirement_to_verify}. Expected preprocessed string! Got: {trace}")
                continue
            else:
                print(f"[ERROR] Unexpected trace type: {type(trace)}")
                continue

            proc.stdin.write(trace_str.encode('utf-8'))
            await proc.stdin.drain()

            try:
                line = await asyncio.wait_for(proc.stdout.readline(), timeout=0.1)
                pattern = r"\s*@\d+\.\d+\s+\(time point \d+\):.*"
                match = re.match(pattern, line.decode())

                if match:
                    self._v_q.put(1)  # 1 = satisfied
                else:
                    print(f"[WARN] Unexpected monpoly output: {line.decode().strip()}")
                    self._v_q.put(0)  # 0 = violated
            except asyncio.TimeoutError:
                print(f"[WARN] Timeout reading monpoly output for {self._requirement_to_verify}. Assuming violation.")
                self._v_q.put(0)
            except Exception as e:
                print(f"[ERROR] Unexpected error in monpoly process for {self._requirement_to_verify}: {str(e)}")
                self._v_q.put(0)

