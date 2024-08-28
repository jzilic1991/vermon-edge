import psutil
import iperf3
import time
from tabulate import tabulate
from http.server import BaseHTTPRequestHandler, HTTPServer
import threading

def server_monitoring():
    cpu_count = psutil.cpu_count()
    cpu_freq = psutil.cpu_freq().current / 1000
    percent_tuple = [(load / cpu_count) * 100 for load in psutil.getloadavg()]
    cpu_percent = psutil.cpu_percent(interval=1, percpu=True)
    vmem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    net_io = psutil.net_io_counters(pernic=True)
    
    data = [
        ["CPU Count", "N/A", cpu_count, "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"],
        ["CPU Frequency (GHz)", "N/A", "N/A", "N/A", cpu_freq, "N/A", "N/A", "N/A", "N/A"],
        ["System Load (1 min)", "N/A", percent_tuple[0], "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"],
        ["System Load (5 min)", "N/A", percent_tuple[1], "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"],
        ["System Load (15 min)", "N/A", percent_tuple[2], "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"],
        ["CPU Usage (%)", "Core 0", cpu_percent[0], "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"],
        *[["CPU Usage (%)", f"Core {i+1}", percent, "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"] for i, percent in enumerate(cpu_percent[1:])],
        ["Virtual Memory (MB)", "Free", vmem.free / 1000000, "N/A", "N/A", "N/A", "N/A", vmem.percent, "N/A"],
        ["Disk Usage (MB)", "/", disk.free / 1000000, "N/A", "N/A", "N/A", "N/A", disk.percent, "N/A"],
        ["Network I/O", "eth0", net_io['eth0'].packets_sent, net_io['eth0'].packets_recv, "N/A", "N/A", "N/A", "N/A", "N/A"]
    ]

    headers = ["Metric", "Detail", "Value", "Failed reqs", "Avg (ms)", "Min (ms)", "Max (ms)", "Med (ms)", "req/s"]
    
    print(tabulate(data, headers=headers, tablefmt="grid"))
    print()

def networking_monitoring():
    remote_site = '172.19.172.150'
    test_duration = 1

    # TCP Test
    client_tcp = iperf3.Client()
    client_tcp.server_hostname = remote_site
    client_tcp.zerocopy = True
    client_tcp.verbose = False
    client_tcp.reverse = True
    client_tcp.port = 5201
    client_tcp.num_streams = 10
    client_tcp.duration = int(test_duration)
    client_tcp.bandwidth = 1000000000
    result = client_tcp.run()

    print(f"Upload speed: {int(result.sent_MB_s)} MB/s")
    print(f"Download speed: {int(result.received_MB_s)} MB/s")
    
    del client_tcp
    
    # UDP Test
    client_udp = iperf3.Client()
    client_udp.server_hostname = remote_site
    client_udp.zerocopy = True
    client_udp.verbose = False
    client_udp.reverse = True
    client_udp.port = 5201
    client_udp.num_streams = 10
    client_udp.duration = int(test_duration)
    client_udp.bandwidth = 1000000000
    client_udp.protocol = 'udp'
    result = client_udp.run()

    print(f"Jitter: {int(result.jitter_ms)} ms")
    print(f"Packets: {int(result.packets)}")
    print(f"Lost packets: {int(result.lost_packets)}")
    print()

class HealthCheckHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/healthz':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")
        else:
            self.send_response(404)
            self.end_headers()

def run_health_check_server():
    server_address = ('', 8000)
    httpd = HTTPServer(server_address, HealthCheckHandler)
    httpd.serve_forever()

if __name__ == "__main__":
    health_check_thread = threading.Thread(target=run_health_check_server)
    health_check_thread.daemon = True
    health_check_thread.start()

    while True:
        server_monitoring()
        time.sleep(1)
