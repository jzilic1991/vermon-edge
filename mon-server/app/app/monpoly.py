import asyncio

from multiprocessing import Process

from util import Util


class Monpoly (Process):


	def __init__ (self, t_q, v_q, _mon_proc_enum):

		Process.__init__(self)
		self._t_q = t_q
		self._v_q = v_q
		self._mon_proc_enum = _mon_proc_enum # enum data type
		self._trace_patterns = Util.determine_trace_patterns (self._mon_proc_enum)


	def get_incoming_queue (cls):

		return cls._t_q


	def get_outgoing_queue (cls):

		return cls._v_q


	def get_trace_patterns (cls):

		return cls._trace_patterns


	def get_mon_proc_enum (cls):

		# returing enum data type i.e. tuple (name, value)
		return cls._mon_proc_enum


	def run (cls):

		asyncio.run (cls.__processing ())


	async def __processing (cls):

		proc = await asyncio.create_subprocess_exec ("monpoly", "-sig", "edge-mon-specs/" + \
			str (cls._mon_proc_enum.value) + ".sig", "-formula", "edge-mon-specs/" + \
			str (cls._mon_proc_enum.value) + ".mfotl", stdin = asyncio.subprocess.PIPE, \
			stdout = asyncio.subprocess.PIPE)

		print (str (cls._mon_proc_enum.value) + " process is started!")

		while True:

			trace = cls._t_q.get ()

			if trace:

				proc.stdin.write (bytes (trace, 'utf-8'))
				await proc.stdin.drain()

				try:
					line = await asyncio.wait_for (proc.stdout.readline(), 0.1)
					cls._v_q.put (line.decode ())

				except Exception:
				
					cls._v_q.put ("")