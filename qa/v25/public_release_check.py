"""Read-only v25 release check using the existing private deployment test cookie.

Usage: python3 -B qa/v25/public_release_check.py tmp/v19-public-state.json
Checks HTTPS, the saved mission/task/progress, existing game assets, parent
settings, and all 20 new illustrations. Never creates a browser or mission,
submits an answer, changes progress, or prints cookies.
"""
import hashlib
import importlib.util
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("v23_release_check", ROOT / "qa/v23/public_release_check.py")
baseline = importlib.util.module_from_spec(spec)
spec.loader.exec_module(baseline)

NEW_ILLUSTRATIONS = (
    "antennas", "apartment", "cliffs", "coins", "excavator", "frying_pan",
    "hose", "manta", "notes", "pacifier", "pillow", "seeds_many", "sieves",
    "skirt", "snowdrift", "threads", "totem", "wall", "wasps", "wrapper",
)


def main():
    # Reuse the previously verified read-only cookie restoration and health,
    # JavaScript/cache-version, and parent-settings checks without new sessions.
    baseline.main()
    previous = baseline.previous
    for name in NEW_ILLUSTRATIONS:
        path = "/school_images/" + name + ".svg"
        expected = hashlib.sha256((ROOT / "public" / path.lstrip("/")).read_bytes()).hexdigest()
        status, headers, contents = previous.request("GET", path + "?v=" + expected[:12])
        content_type = dict((key.lower(), value) for key, value in headers).get("content-type", "")
        previous.verify(status == 200 and "image/svg+xml" in content_type,
                        "Illustration unavailable: " + name)
        previous.verify(not previous.cookies(headers), "Static illustration issued cookies: " + name)
        actual = hashlib.sha256(contents.encode("utf-8")).hexdigest()
        previous.verify(actual == expected, "Deployed illustration differs: " + name)
        print("PASS: Exact new SVG and cache-version URL: " + name + ".svg", flush=True)
    print("PASS: All 20 v25 illustrations match local SHA-256; saved mission remains unchanged.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        print("ERROR: " + str(error), file=sys.stderr)
        sys.exit(1)
    except Exception as error:
        # Exception values can contain private request details; only name the type.
        print("ERROR: Release check failed (" + type(error).__name__ + "); no private state printed.", file=sys.stderr)
        sys.exit(1)
