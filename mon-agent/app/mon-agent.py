import os
import psutil
import requests
import threading
import time
import logging
from requests.exceptions import RequestException
from http.server import BaseHTTPRequestHandler, HTTPServer

logging.basicConfig(level=logging.INFO)

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
            response = requests.post(url, json=metrics, timeout=2)  # Add timeout to avoid hanging
            response.raise_for_status()
            logging.info(f"✅ Sent: {metrics}")
        except requests.exceptions.ConnectionError as ce:
            logging.warning(f"🔌 Connection error sending metrics: {ce}")
        except requests.exceptions.Timeout:
            logging.warning("⏱️ Request timed out when sending metrics")
        except requests.exceptions.RequestException as e:
            logging.warning(f"❌ Failed to send metrics: {e}")
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

