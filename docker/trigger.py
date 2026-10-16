"""Trigger and status of the pipeline in the container (port 8080).

POST /update   asks for a run soon (header "Authorization: Bearer <TRIGGER_TOKEN>");
               several requests lead to one run, at most every MIN_GAP_MINUTES
GET  /status   state of the last run (no token needed)

Without TRIGGER_TOKEN, triggering is switched off.
"""
import json
import os
import pathlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STATE = pathlib.Path("/work/state")
TOKEN = os.environ.get("TRIGGER_TOKEN", "")


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body):
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.rstrip("/") == "/status":
            try:
                self._send(200, json.loads((STATE / "status.json").read_text()))
            except (OSError, ValueError):
                self._send(200, {"state": "starting"})
        else:
            self._send(404, {"error": "not found"})

    def do_POST(self):
        if self.path.rstrip("/") != "/update":
            self._send(404, {"error": "not found"})
        elif not TOKEN or self.headers.get("Authorization", "") != f"Bearer {TOKEN}":
            self._send(401, {"error": "missing or wrong token"})
        else:
            (STATE / "trigger").touch()
            self._send(202, {"queued": True})

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
