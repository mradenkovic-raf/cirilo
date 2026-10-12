"""Small live HTTPS check; state contains a private test cookie, never printed.

Usage: python3 qa/v19/public_http_check.py write tmp/v19-public-state.json
       python3 qa/v19/public_http_check.py restore tmp/v19-public-state.json

Write creates two fresh browser identities and one unfinished test mission.
Restore verifies that mission with only its permanent device cookie.
"""
import argparse
import datetime
import email.utils
import http.client
import http.cookies
import json
import os
import pathlib
import re
import stat
import sys
import urllib.parse
from html.parser import HTMLParser

ORIGIN = "https://cirilo-production.up.railway.app"
HOST = urllib.parse.urlsplit(ORIGIN).hostname
TMP = pathlib.Path(__file__).resolve().parents[2] / "tmp"


def verify(condition, message):
    if not condition:
        raise RuntimeError(message)


def local_path(value):
    parsed = urllib.parse.urlsplit(urllib.parse.urljoin(ORIGIN, value))
    verify(parsed.scheme == "https" and parsed.netloc == HOST,
           "Response points outside the fixed HTTPS target")
    return urllib.parse.urlunsplit(("", "", parsed.path or "/", parsed.query, ""))


def request(method, path, *, cookie="", data=None):
    headers = {"User-Agent": "Cirilo-deployment-smoke/1.0"}
    if cookie:
        headers["Cookie"] = cookie
    body = urllib.parse.urlencode(data) if data is not None else None
    if body is not None:
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    connection = http.client.HTTPSConnection(HOST, timeout=30)
    try:
        connection.request(method, local_path(path), body=body, headers=headers)
        response = connection.getresponse()
        return response.status, response.getheaders(), response.read().decode("utf-8")
    finally:
        connection.close()


def cookies(headers):
    jar = http.cookies.SimpleCookie()
    for name, value in headers:
        if name.lower() == "set-cookie":
            jar.load(value)
    return jar


def cookie_header(jar):
    return "; ".join(item.OutputString(attrs=[]) for item in jar.values())


class Page(HTMLParser):
    def __init__(self, body):
        super().__init__()
        self.token = None
        self.css = None
        self.js = None
        self.exercise = None
        self.progress = None
        self.feed(body)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "meta" and attrs.get("name") == "csrf-token":
            self.token = attrs.get("content")
        if tag == "link" and attrs.get("rel") == "stylesheet" and not self.css:
            self.css = attrs.get("href")
        if tag == "script" and attrs.get("src") and not self.js:
            self.js = attrs["src"]
        if "data-exercise" in attrs:
            self.exercise = {key: attrs.get(key) for key in ("data-id", "data-kind")}
        if "data-mission-path" in attrs:
            self.progress = attrs.get("aria-valuenow")

    def mission_snapshot(self):
        verify(self.exercise and self.exercise["data-id"] and self.progress is not None,
               "Unfinished mission content missing")
        return {"exercise": self.exercise, "progress": self.progress}


def write(state_path):
    verify(not state_path.exists(), "State already exists; use restore or choose a new file")
    status, headers, body = request("GET", "/")
    verify(status == 200, "Homepage did not return HTTPS 200")
    jar = cookies(headers)
    device = jar.get("cirilo_device")
    verify(device and device["secure"] and device["httponly"] and
           device["samesite"].lower() == "lax" and device["path"] == "/",
           "Protected device cookie missing")
    expires = email.utils.parsedate_to_datetime(device["expires"])
    verify(expires > datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=365),
           "Device cookie is not permanent")
    page = Page(body)
    verify(page.token and page.css and page.js, "Homepage token or asset references missing")
    for asset, mime_types in ((page.css, ("text/css",)),
                              (page.js, ("text/javascript", "application/javascript"))):
        asset_status, asset_headers, asset_body = request("GET", asset)
        content_type = dict((key.lower(), value) for key, value in asset_headers).get("content-type", "")
        verify(asset_status == 200 and asset_body.strip() and
               any(mime in content_type for mime in mime_types), "Static CSS or JavaScript unavailable")

    browser_cookie = cookie_header(jar)
    status, headers, _ = request("POST", "/practice_sessions", cookie=browser_cookie,
                                 data={"authenticity_token": page.token})
    verify(status == 303, "Mission creation with genuine CSRF failed")
    location = dict((key.lower(), value) for key, value in headers).get("location", "")
    mission = local_path(location)
    verify(re.fullmatch(r"/practice_sessions/\d+", mission), "Mission redirect missing")
    status, _, body = request("GET", mission, cookie=browser_cookie)
    verify(status == 200, "Created mission unavailable")
    snapshot = Page(body).mission_snapshot()

    state_path.parent.mkdir(parents=True, exist_ok=True)
    descriptor = os.open(state_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w") as saved:
        json.dump({"origin": ORIGIN, "mission": mission,
                   "cookie": device.OutputString(attrs=[]), "snapshot": snapshot}, saved)
    os.chmod(state_path, 0o600)

    status, second_headers, _ = request("GET", "/")
    second_jar = cookies(second_headers)
    verify(status == 200 and "cirilo_device" in second_jar, "Second browser unavailable")
    verify(second_jar["cirilo_device"].value != device.value, "Browsers share a device cookie")
    verify(request("GET", mission, cookie=cookie_header(second_jar))[0] == 404,
           "Second browser could access the first browser's mission")
    verify(request("POST", "/practice_sessions", cookie=browser_cookie)[0] == 422,
           "Mutation without CSRF was accepted")
    print("PASS: HTTPS, static CSS/JS, permanent protected cookie, mission, browser isolation, CSRF.")


def restore(state_path):
    verify(stat.S_IMODE(state_path.stat().st_mode) == 0o600, "State file must have mode 0600")
    state = json.loads(state_path.read_text())
    verify(state.get("origin") == ORIGIN, "State belongs to a different target")
    verify(re.fullmatch(r"/practice_sessions/\d+", state.get("mission", "")), "Invalid saved mission")
    jar = http.cookies.SimpleCookie()
    jar.load(state.get("cookie", ""))
    verify(set(jar) == {"cirilo_device"}, "State must contain only the permanent device cookie")
    status, _, body = request("GET", state["mission"], cookie=cookie_header(jar))
    verify(status == 200, "Saved browser could not restore its mission")
    verify(Page(body).mission_snapshot() == state["snapshot"], "Saved mission content changed")
    print("PASS: Same mission and task restored using only the permanent browser cookie.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("write", "restore"))
    parser.add_argument("state", type=pathlib.Path)
    args = parser.parse_args()
    state_path = args.state.resolve()
    verify(state_path.is_relative_to(TMP.resolve()) and state_path != TMP.resolve(),
           "State must be a file under this project's ignored tmp directory")
    status, headers, _ = request("GET", "/up")
    verify(status == 200 and not cookies(headers), "Public healthcheck failed or issued cookies")
    (write if args.mode == "write" else restore)(state_path)


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
    except Exception as error:
        # Do not include exception values: HTTP/parser exceptions can contain cookies.
        print(f"ERROR: Public check failed ({type(error).__name__}); no private state printed.", file=sys.stderr)
        sys.exit(1)
