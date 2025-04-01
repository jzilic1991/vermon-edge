import os
import psutil
import requests
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

def get_app_container_pid():
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            if 'cartservice' in ' '.join(proc.info['cmdline']):
                return proc.info['pid']
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return 1  # fallback to PID 1

def collect_metrics():
    pid = get_app_container_pid()
    proc = psutil.Process(pid)
    cpu = proc.cpu_percent(interval=1)
    mem = proc.memory_info().rss / (1024 * 1024)
    return {'cpu': cpu, 'memory': mem}

def send_metrics():
    url = os.getenv("OBJECTIVE_VERIFIER_URL", "http://loadgenerator.default.svc.cluster.local:5001") + "/metrics"
    while True:
        metrics = collect_metrics()
        try:
            requests.post(url, json=metrics)
            print(f"Sent: {metrics}")
        except Exception as e:
            print(f"Failed to send metrics: {e}")
        time.sleep(1)

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
    threading.Thread(target=send_metrics, daemon=True).start()
    run_health_check_server()
    send_metrics()

