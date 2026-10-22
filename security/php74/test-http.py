#!/usr/bin/env python3
"""Isolated Apache smoke test. Never mount a real Drupal site or database."""
import argparse
import json
import pathlib
import subprocess
import tempfile
import time
import urllib.error
import urllib.request


def docker(*args):
    return subprocess.check_output(["docker", *args], text=True).strip()


parser = argparse.ArgumentParser()
parser.add_argument("image")
args = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="cloudrup-php74-http-") as temporary:
    root = pathlib.Path(temporary)
    root.chmod(0o755)
    (root / ".htaccess").write_text(
        "php_value session.save_path /tmp\n"
        "php_value session.upload_progress.enabled 1\n"
        "php_value session.upload_progress.cleanup 0\n"
    )
    (root / "index.php").write_text('''<?php
if (isset($_GET['oom'])) {
    ini_set('memory_limit', '4M');
    register_shutdown_function(function () {
        file_put_contents('/tmp/cloudrup-php74-shutdown-ran', 'unsafe');
    });
    str_repeat('x', 64 * 1024 * 1024);
    exit;
}
session_start();
header('Content-Type: application/json');
echo json_encode([
    'php' => PHP_VERSION,
    'sapi' => PHP_SAPI,
    'extensions' => get_loaded_extensions(),
    'post' => $_POST,
    'upload_error' => isset($_FILES['file']) ? $_FILES['file']['error'] : null,
    'upload_progress_enabled' => ini_get('session.upload_progress.enabled'),
    'upload_progress_cleanup' => ini_get('session.upload_progress.cleanup'),
    'session' => $_SESSION,
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
        assert info["php"] == "7.4.33", info
        assert info["sapi"] == "apache2handler", info
        for extension in ["PDO", "pdo_mysql", "mbstring", "gd", "curl", "redis"]:
            assert extension in info["extensions"], extension

        boundary = "cloudrup-php74-smoke"
        body = (
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"PHP_SESSION_UPLOAD_PROGRESS\"\r\n\r\ncloudrup-smoke\r\n"
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\nhello\r\n"
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"smoke.txt\"\r\n"
            "Content-Type: text/plain\r\n\r\nhello\r\n"
            f"--{boundary}--\r\n"
        ).encode()
        request = urllib.request.Request(url, data=body, headers={
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "Cookie": "PHPSESSID=cloudrupphp74smoke",
        })
        with urllib.request.urlopen(request, timeout=10) as response:
            result = json.load(response)
        assert result["post"]["title"] == "hello", result
        assert result["upload_error"] == 0, result
        assert result["upload_progress_enabled"] == "1", result
        assert result["upload_progress_cleanup"] == "0", result
        assert "upload_progress_cloudrup-smoke" not in result["session"], result

        try:
            urllib.request.urlopen(url + "?oom=1", timeout=10).read()
        except (OSError, urllib.error.HTTPError):
            pass  # An immediate worker exit may close the response connection.
        docker("exec", container, "test", "!", "-e", "/tmp/cloudrup-php74-shutdown-ran")
        with urllib.request.urlopen(url, timeout=10) as response:
            assert json.load(response)["sapi"] == "apache2handler"
        print("PASS: Apache PHP 7.4, required extensions, multipart upload, upload progress disabled despite INI, OOM skips shutdown callback, later requests succeed")
    finally:
        subprocess.run(["docker", "rm", "-f", "-v", container], check=True, stdout=subprocess.DEVNULL)
