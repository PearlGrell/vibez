"""HTTP relay that streams YouTube audio through this service.

Stream URLs are bound to the IP that requested them, so a URL extracted here
can only be fetched from here. This relay extracts (with yt-dlp) and proxies
the audio bytes from the same process, with Range support so players can seek.
"""

import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import requests

from app.songs.service import SongService

_service = SongService()
_resolve_lock = threading.Lock()

_FORWARDED_HEADERS = (
    "Content-Type",
    "Content-Length",
    "Content-Range",
    "Accept-Ranges",
)


def _resolve(video_id):
    with _resolve_lock:
        cached = _service.url_cache.get(video_id)
        if cached:
            _, _, expire_ts = cached
            if expire_ts == 0 or expire_ts - time.time() > SongService.URL_SAFETY_MARGIN:
                return cached
        result = SongService.resolve_url(video_id)
        _service.url_cache[video_id] = result
        return result


class StreamRelayHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format, *args):  # noqa: A002 - stdlib signature
        pass

    def do_GET(self):
        parts = self.path.split("?")[0].strip("/").split("/")
        if len(parts) != 2 or parts[0] != "stream" or not parts[1]:
            self.send_error(404)
            return
        video_id = parts[1]

        try:
            url, _, _ = _resolve(video_id)
        except Exception:
            self.send_error(502, "Could not resolve audio")
            return

        headers = {}
        range_header = self.headers.get("Range")
        if range_header:
            headers["Range"] = range_header

        upstream = None
        try:
            upstream = requests.get(url, headers=headers, stream=True, timeout=30)
            if upstream.status_code in (401, 403):
                # URL expired or got invalidated: re-extract once and retry.
                upstream.close()
                _service.url_cache.pop(video_id, None)
                url, _, _ = _resolve(video_id)
                upstream = requests.get(url, headers=headers, stream=True, timeout=30)
        except Exception:
            if upstream is not None:
                upstream.close()
            self.send_error(502, "Upstream fetch failed")
            return

        try:
            self.send_response(upstream.status_code)
            for header in _FORWARDED_HEADERS:
                if header in upstream.headers:
                    self.send_header(header, upstream.headers[header])
            self.send_header("Connection", "close")
            self.close_connection = True
            self.end_headers()

            for chunk in upstream.iter_content(chunk_size=64 * 1024):
                if chunk:
                    self.wfile.write(chunk)
        except Exception:
            # Client disconnected mid-stream (seek, skip, pause) — normal.
            pass
        finally:
            upstream.close()


class _DualStackServer(ThreadingHTTPServer):
    address_family = socket.AF_INET6
    daemon_threads = True


def start_stream_relay(port):
    """Starts the relay on a daemon thread; [::] accepts IPv4 and IPv6."""
    server = _DualStackServer(("::", port), StreamRelayHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    print(f"Stream relay listening on [::]:{port}")
    return server
