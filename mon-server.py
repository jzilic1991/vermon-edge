import asyncio

from multiprocessing import Process, Queue
from flask import Flask, request, jsonify


class Monpoly (Process):

	def __init__ (self, t_q, v_q):

		Process.__init__(self)
		self._t_q = t_q
		self._v_q = v_q


	def run (cls):

		asyncio.run (cls.__processing ())


	async def __processing (cls):

		proc = await asyncio.create_subprocess_exec("monpoly", "-sig", "edge-monitoring/netper.sig", "-formula", \
		 	"edge-monitoring/netper.mfotl", stdin = asyncio.subprocess.PIPE, stdout = asyncio.subprocess.PIPE)

		while True:

			trace = cls._t_q.get ()
			
			if trace:

				proc.stdin.write(bytes (trace, 'utf-8'))
				await proc.stdin.drain()

				try:
					line = await asyncio.wait_for (proc.stdout.readline(), 0.1)
					cls._v_q.put (line.decode ())

				except Exception:
				
					cls._v_q.put ("")
					

app = Flask (__name__)
t_q = Queue ()
v_q = Queue ()
mon = Monpoly (t_q, v_q)
mon.start ()


@app.route('/edge-vermon')
def trace_handler ():

	global t_q, v_q
	
	trace = request.args.get('trace', None)
	print ("Trace: " + trace)

	t_q.put (trace)
	v = v_q.get ()
	print ("Verdict: " + str(v))

	return jsonify ([v])


if __name__ == "__main__":

	app.run(host = '0.0.0.0', port = 5000, debug = True)