import os
import psutil
import requests
import threading
import time
import logging
from requests.exceptions import RequestException
from http.server import BaseHTTPRequestHandler, HTTPServer

logging.basicConfig(level=logging.INFO)

SERVICE_NAME = os.getenv("SERVICE_NAME", "unknown-service")
CPU_THRESHOLD = float(os.getenv("CPU_DELTA_THRESHOLD", 5.0))  # in percent
MEM_THRESHOLD = float(os.getenv("MEM_DELTA_THRESHOLD", 10.0))  # in MB

last_metrics = {"cpu": None, "memory": None}

def get_app_container_pid():
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            cmd = ' '.join(proc.info['cmdline'])
            if SERVICE_NAME.lower() in cmd.lower():
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

def should_send(current):
    global last_metrics
    if last_metrics["cpu"] is None:
        return True  # always send the first sample

    delta_cpu = abs(current["cpu"] - last_metrics["cpu"])
    delta_mem = abs(current["memory"] - last_metrics["memory"])

    return delta_cpu > CPU_THRESHOLD or delta_mem > MEM_THRESHOLD

def send_metrics():
    global last_metrics
    url = os.getenv("OBJECTIVE_VERIFIER_URL", "http://loadgenerator.default.svc.cluster.local:5001") + "/metrics"
    while True:
        metrics = collect_metrics()
        if should_send(metrics):
            enriched = {
                "service_name": SERVICE_NAME,
                "metrics": metrics
            }
            try:
                response = requests.post(url, json=enriched, timeout=2)
                response.raise_for_status()
                logging.info(f"✅ Sent: {enriched}")
                last_metrics = metrics
            except requests.exceptions.ConnectionError as ce:
                logging.warning(f"🔌 Connection error: {ce}")
            except requests.exceptions.Timeout:
                logging.warning("⏱️ Request timed out")
            except requests.exceptions.RequestException as e:
                logging.warning(f"❌ Failed to send metrics: {e}")
        else:
            logging.info("🔕 No significant change, skipping send.")
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

