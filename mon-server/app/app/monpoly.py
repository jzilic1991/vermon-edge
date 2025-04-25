import asyncio
import re
from multiprocessing import Process
from util import Util

class Monpoly (Process):

  def __init__ (self, t_q, v_q, requirement_to_verify):
    Process.__init__(self)
    self._t_q = t_q
    self._v_q = v_q
    self._requirement_to_verify = requirement_to_verify

  
  def get_requirement_name (cls):
    return cls._requirement_to_verify


  def get_incoming_queue (cls):
    return cls._t_q


  def get_outgoing_queue (cls):
    return cls._v_q


  def run (cls):
    asyncio.run (cls.__processing ())


  async def __processing (cls):
    proc = await asyncio.create_subprocess_exec ("monpoly", "-sig", "online-boutique-reqs/" + \
      str (cls._requirement_to_verify) + ".sig", "-formula", "online-boutique-reqs/" + \
      str (cls._requirement_to_verify) + ".mfotl", stdin = asyncio.subprocess.PIPE, \
      stdout = asyncio.subprocess.PIPE)
    print(str(cls._requirement_to_verify) + " process is started!")

    while True:
      trace = cls._t_q.get()
      if trace:
        proc.stdin.write (bytes(trace, 'utf-8'))
        await proc.stdin.drain()
        try:
          line = await asyncio.wait_for(proc.stdout.readline(), 0.1)
          pattern = r"\s*@\d+\.\d+\s+\(time point \d+\):.*"
          match = re.match(pattern, line.decode())
          if match:
              cls._v_q.put(1)
          else:
              raise ValueError("Monpoly verifier did not return agreed format of evaluation response: " + str(line.decode()))
        except Exception:
          cls._v_q.put(0)
