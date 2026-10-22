#!/usr/bin/env python3
"""Generic Apache smoke test for cloudrup-webserver images (PHP 8.x).

Unlike security/php74/test-http.py, this does not assert the PHP 7.4 EOL
mitigation behaviours; it only verifies that Apache serves PHP, required
extensions load, and multipart POST/file upload work.
"""
import argparse
import json
import pathlib
import subprocess
import tempfile
import time
import urllib.request


def docker(*args):
    return subprocess.check_output(["docker", *args], text=True).strip()


parser = argparse.ArgumentParser()
parser.add_argument("image")
parser.add_argument("expected_prefix", help="e.g. 8.1 — PHP_VERSION must start with this")
args = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="cloudrup-http-") as temporary:
    root = pathlib.Path(temporary)
    root.chmod(0o755)
    (root / ".htaccess").write_text("php_value session.save_path /tmp\n")
    (root / "index.php").write_text('''<?php
session_start();
header('Content-Type: application/json');
echo json_encode([
    'php' => PHP_VERSION,
    'sapi' => PHP_SAPI,
    'extensions' => get_loaded_extensions(),
    'post' => $_POST,
    'upload_error' => isset($_FILES['file']) ? $_FILES['file']['error'] : null,
]);
''')
    container = docker(
        "run", "-d", "--platform", "linux/amd64",
        "--entrypoint", "/bin/sh",
        "-p", "127.0.0.1::80",
        "-v", f"{root}:/var/www/html:ro",
        args.image, "-c", ". /etc/apache2/envvars; exec apache2 -D FOREGROUND",
    )
    try:
        port = docker("port", container, "80/tcp").split(":")[-1]
        url = f"http://127.0.0.1:{port}/index.php"
        for attempt in range(40):
            try:
                with urllib.request.urlopen(url, timeout=2) as response:
                    info = json.load(response)
                break
            except (OSError, ValueError):
                time.sleep(0.5)
        else:
            raise RuntimeError("Apache did not become ready")
        assert info["php"].startswith(args.expected_prefix), info
        assert info["sapi"] == "apache2handler", info
        for extension in ["PDO", "pdo_mysql", "mbstring", "gd", "curl", "redis"]:
            assert extension in info["extensions"], extension

        boundary = "cloudrup-smoke"
        body = (
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\nhello\r\n"
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"smoke.txt\"\r\n"
            "Content-Type: text/plain\r\n\r\nhello\r\n"
            f"--{boundary}--\r\n"
        ).encode()
        request = urllib.request.Request(url, data=body, headers={
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "Cookie": "PHPSESSID=cloudrupsmoke",
        })
        with urllib.request.urlopen(request, timeout=10) as response:
            result = json.load(response)
        assert result["post"]["title"] == "hello", result
        assert result["upload_error"] == 0, result

        with urllib.request.urlopen(url, timeout=10) as response:
            assert json.load(response)["sapi"] == "apache2handler"
        print(f"PASS: Apache PHP {args.expected_prefix}, required extensions, multipart upload")
    finally:
        subprocess.run(["docker", "rm", "-f", "-v", container], check=True, stdout=subprocess.DEVNULL)
