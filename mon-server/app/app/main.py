import sys

from flask import Flask, request, jsonify

from mon_server import MonServer
from util import VerificationType




# verifiers = init_verifiers ()
mon_server = MonServer (sys.argv[1])
app = Flask (__name__)


@app.route('/edge-vermon', methods = ["GET", "POST"])
def trace_handler ():

	global mon_server

	param = request.args.get ('trace', None)

	if param != None:

		print ("Event trace: " + param)
		v = mon_server.evaluate_trace (param)
		return jsonify ([v])

	param = request.args.get ('verdict', None)

	if param != None:

		print ("Verdict trace:" + param)
		v = mon_server.evaluate_trace (param)
		print ("Requirement evaluation: " + str (v))




if __name__ == "__main__":

	#if mon_server.get_ver_type () == VerificationType.OBJECTIVE.value:

	app.run(host = '0.0.0.0', port = 5001, debug = True, use_reloader = False)

	#elif mon_server.get_ver_type () == VerificationType.REQUIREMENT.value:

	#	app.run (host = '0.0.0.0', port = 5002, debug = True, use_reloader = False)