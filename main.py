import asyncio

from flask import Flask, request, jsonify


async def create_mon_instance ():

	subprocess = await asyncio.create_subprocess_exec("monpoly", "-sig", "edge-monitoring/netper.sig", "-formula", \
	"edge-monitoring/netper.mfotl", stdin = asyncio.subprocess.PIPE, stdout = asyncio.subprocess.PIPE)
	print ("Subprocess: " + str(subprocess))

	return subprocess


# main coroutine
async def monitor (trace, process):
	
	# create as a subprocess using create_subprocess_exec
	# f = open("edge-monitoring/netper.log", "r")
	
	# for l in f.readlines():
	# 	# write data to the subprocess
	# 	process.stdin.write(bytes (l, 'utf-8'))
	# 	await process.stdin.drain()
		
	# 	try:
	# 		line = await asyncio.wait_for(process.stdout.readline(), 0.01)
		
	# 		if line:
	# 			line = line.decode()
	# 			print (line)

	# 	except:
	# 		continue
	
	process.stdin.write(bytes (trace, 'utf-8'))
	print ("Monitor process: " + str (process))
	await process.stdin.drain()
		
	try:
		line = await asyncio.wait_for(process.stdout.readline(), 1)
		
		if line:
			line = line.decode()
			print ("Line:" + line)
			return line

	except:
		
		return ""



process = asyncio.run (create_mon_instance ())
app = Flask (__name__)

@app.route('/edge-vermon')
def trace_handler ():

	trace = request.args.get('trace', None)
	print ("Trace: " + trace)
	print ("Process: " + str (process))

	return jsonify ([asyncio.run (monitor (trace, process))])



if __name__ == "__main__":

	app.run(host = '0.0.0.0', port = 5000, debug = True)