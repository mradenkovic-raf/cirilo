"""Read-only v26 music release check using the existing private test cookie.

Usage: python3 -B qa/v26/public_release_check.py tmp/v19-public-state.json
Checks saved mission/progress, HTTPS, exact game JavaScript/cache versions,
school settings, music routing, and both MP3 files. No new browser identities,
missions, answers, or production writes; cookies are never printed.
"""
import hashlib
import http.client
import importlib.util
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("v23_release_check", ROOT / "qa/v23/public_release_check.py")
baseline = importlib.util.module_from_spec(spec)
spec.loader.exec_module(baseline)

TRACKS = {
    "drive": "/audio/bouncy-toy-time.mp3?v=1",
    "arena": "/audio/strasni-mrguuud.mp3?v=2",
}


def read_audio(path):
    """Fetch raw bytes from the fixed production host, without any cookies."""
    previous = baseline.previous
    connection = http.client.HTTPSConnection(previous.HOST, timeout=30)
    try:
        connection.request("GET", previous.local_path(path),
                           headers={"User-Agent": "Cirilo-deployment-smoke/1.0"})
        response = connection.getresponse()
        return response.status, response.getheaders(), response.read()
    finally:
        connection.close()


def main():
    # The baseline proves deployed JavaScript equals the local file, including
    # its import-map cache version, and restores the original saved task.
    baseline.main()
    previous = baseline.previous
    source = (ROOT / "public/game_audio.js").read_text()
    match = re.search(r"const\s+TRACKS\s*=\s*\{([^}]+)\}", source)
    previous.verify(match is not None, "Music routing table missing")
    actual_tracks = dict(re.findall(r"(\w+)\s*:\s*['\"]([^'\"]+)['\"]", match.group(1)))
    previous.verify(actual_tracks == TRACKS, "Arena/drive music routing differs")
    print("PASS: Drive uses Bouncy Toy Time; arena uses the replacement Mrgud track (v2).", flush=True)

    for mode, path in TRACKS.items():
        local = ROOT / "public" / path.split("?", 1)[0].lstrip("/")
        expected = hashlib.sha256(local.read_bytes()).hexdigest()
        status, headers, contents = read_audio(path)
        content_type = dict((key.lower(), value) for key, value in headers).get("content-type", "")
        previous.verify(status == 200 and content_type.split(";", 1)[0].strip().lower() == "audio/mpeg",
                        "MP3 unavailable or wrong MIME type: " + mode)
        previous.verify(not any(key.lower() == "set-cookie" for key, _ in headers),
                        "Static MP3 issued cookies: " + mode)
        previous.verify(hashlib.sha256(contents).hexdigest() == expected,
                        "Deployed MP3 differs: " + mode)
        print("PASS: Exact MP3 SHA-256, audio/mpeg, no cookies: " + path, flush=True)
    print("PASS: Both production music files match this release; saved mission remains unchanged.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        print("ERROR: " + str(error), file=sys.stderr)
        sys.exit(1)
    except Exception as error:
        print("ERROR: Release check failed (" + type(error).__name__ + "); no private state printed.", file=sys.stderr)
        sys.exit(1)
