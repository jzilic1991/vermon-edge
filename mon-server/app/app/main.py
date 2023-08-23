import sys

# from multiprocessing import Queue
from flask import Flask, request, jsonify

# from util import MonpolyProcName, TracePattern
# from monpoly import Monpoly
from mon_server import MonServer


# def init_verifiers ():

# 	verifiers = dict ()

# 	for proc_name in (MonpolyProcName):

# 		mon = Monpoly (Queue (), Queue (), proc_name)
# 		verifiers[mon] = (mon.get_incoming_queue (), mon.get_outgoing_queue ())
# 		mon.start ()

# 	return verifiers


# verifiers = init_verifiers ()
mon_server = MonServer (sys.argv[1])
app = Flask (__name__)


@app.route('/edge-vermon')
def trace_handler ():

	global mon_server

	trace = request.args.get ('trace', None)
	print ("Trace: " + trace)

	v = mon_server.evaluate_trace (trace)

	# # find trace pattern that fits given trace
	# for tr_pattern in (TracePattern):

	# 	if tr_pattern.value in trace:

	# 		# iterate verifiers and find which one corresponds to matched trace pattern
	# 		for mon in verifiers.keys ():

	# 			# iterate trace patterns which are supported by a verifier
	# 			for tr_target_pattern in mon.get_trace_patterns ():

	# 				# and compare it with required trace pattern
	# 				if tr_pattern.name == tr_target_pattern.name:

	# 					# route given trace to appropriate verifier via queues
	# 					verifiers[mon][0].put (trace)
	# 					v = verifiers[mon][1].get ()

	# 					# send verdict
	# 					print ("Verdict: " + str(v))

	# 					return jsonify ([v])

	return jsonify ([v])




if __name__ == "__main__":

	app.run(host = '0.0.0.0', port = 5001, debug = True, use_reloader = False)