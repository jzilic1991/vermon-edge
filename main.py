import asyncio
 
# main coroutine
async def main():
	# create as a subprocess using create_subprocess_exec
	process = await asyncio.create_subprocess_exec("monpoly", "-sig", "edge-monitoring/netper.sig", "-formula", \
	"edge-monitoring/netper.mfotl", stdin = asyncio.subprocess.PIPE, stdout = asyncio.subprocess.PIPE)
	f = open("edge-monitoring/netper.log", "r")
	
	for l in f.readlines():
		# write data to the subprocess
		process.stdin.write(bytes (l, 'utf-8'))
		await process.stdin.drain()
		
		try:
			line = await asyncio.wait_for(process.stdout.readline(), 0.01)
		
			if line:
				line = line.decode()
				print (line)

		except:
			continue
 
# entry point
asyncio.run(main())