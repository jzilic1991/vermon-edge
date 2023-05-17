import psutil
import iperf3

print ("CPU count: " + str (psutil.cpu_count ()))
cpu_count = psutil.cpu_count ()
cpu_freq = psutil.cpu_freq ()
print ("CPU frequency: " + str (cpu_freq.current / 1000) + " GHz")
percent_tuple = list ()

for load in psutil.getloadavg ():
    percent = (load / cpu_count) * 100
    percent_tuple.append(percent)

print ("System load per CPU core: " + str (percent_tuple))
print ("CPU percent: " + str (psutil.cpu_percent (interval = 1, percpu = True)))
vmem = psutil.virtual_memory ()
print ("Virtual memory free: " + str (vmem.free / 1000000) + " MB, usage: " + str (vmem.percent) + "%")
disk = psutil.disk_usage ('/')
print ("Disk free: " + str (disk.free / 1000000) + " MB, usage: " + str (disk.percent) + "%")
net_io = psutil.net_io_counters (pernic = True)
print ("ens33 netif packets sent: " + str (net_io['ens33'].packets_sent) + ", packets received: " + \
	str (net_io['ens33'].packets_recv))

# Set vars
# Remote iperf server IP
remote_site = '127.0.0.1'
# How long to run iperf3 test in seconds
test_duration = 1

# Set Iperf Client Options
# Run 10 parallel streams on port 5201 for duration w/ reverse
client_tcp = iperf3.Client()
client_tcp.server_hostname = remote_site
client_tcp.zerocopy = True
client_tcp.verbose = False
client_tcp.reverse = True
client_tcp.port = 5201
client_tcp.num_streams = 10
client_tcp.duration = int (test_duration)
client_tcp.bandwidth = 1000000000

# Run iperf3 test
result = client_tcp.run()

print ("Upload speed: " + str (int (result.sent_MB_s)) + "MBs")
print ("Download speed: " + str (int (result.received_MB_s)) + "MBs")

del client_tcp

client_udp = iperf3.Client()
client_udp.server_hostname = remote_site
client_udp.zerocopy = True
client_udp.verbose = False
client_udp.reverse = True
client_udp.port = 5201
client_udp.num_streams = 10
client_udp.duration = int (test_duration)
client_udp.bandwidth = 1000000000
client_udp.protocol = 'udp'
result = client_udp.run()

print ("Jitter: " + str (int (result.jitter_ms)) + " ms")
print ("Packets: " + str (int (result.packets)))
print ("Lost packets: " + str (int (result.lost_packets)))