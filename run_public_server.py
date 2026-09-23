import subprocess
import sys
import re
import time
import os
import signal
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = ROOT_DIR / "backend"
VENV_PYTHON = BACKEND_DIR / ".venv" / "Scripts" / "python.exe"
CLOUDFLARED = ROOT_DIR / "cloudflared.exe"

print("=" * 70)
print("             Starting UzhavanAI Public Backend & Tunnel")
print("=" * 70)

# Step 1: Start uvicorn backend
print("[1/2] Starting FastAPI backend on http://127.0.0.1:8000 ...")
backend_proc = subprocess.Popen(
    [
        str(VENV_PYTHON),
        "-m", "uvicorn",
        "main:app",
        "--host", "0.0.0.0",
        "--port", "8000"
    ],
    cwd=str(BACKEND_DIR),
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)

time.sleep(2)

# Step 2: Start Cloudflare quick tunnel
print("[2/2] Creating public Cloudflare HTTPS tunnel ...")
tunnel_proc = subprocess.Popen(
    [str(CLOUDFLARED), "tunnel", "--url", "http://127.0.0.1:8000"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1,
)

public_url = None
url_regex = re.compile(r"https://[a-zA-Z0-9-]+\.trycloudflare\.com")

# Read tunnel output to extract the public URL
for line in iter(tunnel_proc.stdout.readline, ""):
    match = url_regex.search(line)
    if match:
        public_url = match.group(0)
        break

if public_url:
    print("\n" + "=" * 76)
    print("                [***] UzhavanAI PUBLIC SERVER IS LIVE! [***]")
    print("=" * 76)
    print(f"\n   [+] PUBLIC HTTPS URL (Works on ANY Network, Mobile 4G/5G, Anywhere):")
    print(f"      >>> {public_url} <<<\n")
    print("   [+] Local Network Wi-Fi URL:")
    print("      http://10.99.130.185:8000\n")
    print("   [i] How to connect on your phone:")
    print("      1. Open the UzhavanAI app on your phone.")
    print("      2. Tap the Settings icon in the top right corner.")
    print(f"      3. Paste this URL: {public_url}")
    print("      4. Tap 'Test' (it will show 'Connected successfully!'), then tap 'Save'.")
    print("=" * 76)
    print("\nPress Ctrl+C to stop the server and tunnel.\n")
else:
    print("[!] Could not automatically capture the public URL. Check tunnel logs.")

def shutdown(sig, frame):
    print("\nShutting down server and tunnel...")
    tunnel_proc.terminate()
    backend_proc.terminate()
    sys.exit(0)

signal.signal(signal.SIGINT, shutdown)
signal.signal(signal.SIGTERM, shutdown)

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    shutdown(None, None)
