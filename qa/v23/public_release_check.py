"""Read-only release smoke check using the existing private deployment test cookie.

Usage: python3 qa/v23/public_release_check.py tmp/v19-public-state.json
Never prints cookies or creates missions/browser identities.
"""
import hashlib
import importlib.util
import json
import pathlib
import sys
from html.parser import HTMLParser

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("previous_check", ROOT / "qa/v19/public_http_check.py")
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)


class ReleasePage(HTMLParser):
    def __init__(self, body):
        super().__init__()
        self.in_map = False
        self.map_text = ""
        self.school = False
        self.letters = []
        self.feed(body)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "script" and attrs.get("type") == "importmap":
            self.in_map = True
        if tag == "input" and "checked" in attrs:
            if attrs.get("name") == "learning_mode" and attrs.get("value") == "school":
                self.school = True
            if attrs.get("name") == "school_letter_ids[]":
                self.letters.append(attrs.get("data-school-letter"))

    def handle_endtag(self, tag):
        if tag == "script":
            self.in_map = False

    def handle_data(self, data):
        if self.in_map:
            self.map_text += data


def main():
    previous.verify(len(sys.argv) == 2, "Pass the existing private state file")
    state_path = pathlib.Path(sys.argv[1]).resolve()
    previous.verify(state_path.is_relative_to((ROOT / "tmp").resolve()), "State must be under ignored tmp")
    status, headers, _ = previous.request("GET", "/up")
    previous.verify(status == 200 and not previous.cookies(headers), "HTTPS healthcheck failed")
    print("PASS: HTTPS healthcheck.")
    previous.restore(state_path)
    state = json.loads(state_path.read_text())
    status, _, body = previous.request("GET", state["mission"], cookie=state["cookie"])
    previous.verify(status == 200, "Existing mission unavailable")
    imports = json.loads(ReleasePage(body).map_text).get("imports", {})
    for name in ("game_audio.js", "battle.js", "dino_drive.js", "mission_path.js"):
        asset = imports.get("/" + name)
        previous.verify(asset is not None, "Release import map missing " + name)
        status, headers, contents = previous.request("GET", asset)
        content_type = dict((k.lower(), v) for k, v in headers).get("content-type", "")
        previous.verify(status == 200 and "javascript" in content_type, "JavaScript unavailable: " + name)
        expected = hashlib.sha256((ROOT / "public" / name).read_bytes()).hexdigest()
        actual = hashlib.sha256(contents.encode("utf-8")).hexdigest()
        previous.verify(actual == expected and "v=" + expected[:12] in asset, "Deployed asset differs: " + name)
        print("PASS: Exact release asset and cache version: " + name)
    status, _, body = previous.request("GET", "/progress", cookie=state["cookie"])
    previous.verify(status == 200, "Parent progress page unavailable")
    page = ReleasePage(body)
    previous.verify(page.school and set(page.letters) == set("АМИТОНСЕ"), "Expected school defaults through E missing")
    print("PASS: Parent settings show school mode and default letters through Е.")


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        print("ERROR: " + str(error), file=sys.stderr)
        sys.exit(1)
    except Exception as error:
        print("ERROR: Release check failed (" + type(error).__name__ + "); no private state printed.", file=sys.stderr)
        sys.exit(1)
