"""HTTP smoke check for bin/check-container; never prints cookies or CSRF tokens."""
import http.client
import http.cookies
import json
import pathlib
import re
import sys
import time
import urllib.parse
from html.parser import HTMLParser

MODE, PORT, STATE = sys.argv[1:]
HOST = "qa-cirilo.up.railway.app"


def verify(condition, message):
    if not condition:
        raise RuntimeError(message)


def request(method, path, *, host=HOST, cookie="", data=None):
    headers = {"Host": host, "X-Forwarded-Proto": "https"}
    if host == "healthcheck.railway.app":
        headers.pop("X-Forwarded-Proto")
    if cookie:
        headers["Cookie"] = cookie
    body = urllib.parse.urlencode(data) if data else None
    if body:
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    connection = http.client.HTTPConnection("127.0.0.1", int(PORT), timeout=3)
    try:
        connection.request(method, path, body=body, headers=headers)
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


class FormToken(HTMLParser):
    token = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "meta" and attrs.get("name") == "csrf-token":
            self.token = attrs.get("content")


try:
    deadline = time.monotonic() + 90
    while True:
        try:
            health = request("GET", "/up", host="healthcheck.railway.app")
            if health[0] == 200:
                break
        except (OSError, http.client.HTTPException):
            pass
        verify(time.monotonic() < deadline, "Healthcheck failed or redirected for 90 seconds")
        time.sleep(0.5)
    verify(not cookies(health[1]), "Healthcheck issued a cookie")
    verify(request("GET", "/", host="untrusted.example")[0] == 403, "Unknown host was accepted")

    if MODE == "write":
        status, headers, body = request("GET", "/")
        verify(status == 200, "Valid host failed or redirected behind HTTPS proxy")
        jar = cookies(headers)
        device = jar.get("cirilo_device")
        verify(device and device["secure"] and device["httponly"] and
               device["samesite"].lower() == "lax", "Protected device cookie missing")
        token = FormToken()
        token.feed(body)
        verify(token.token, "CSRF form token missing")
        browser_cookie = "; ".join(item.OutputString(attrs=[]) for item in jar.values())
        status, headers, _ = request("POST", "/practice_sessions", cookie=browser_cookie,
                                     data={"authenticity_token": token.token})
        verify(status == 303, "CSRF-enabled mission creation failed")
        location = dict((key.lower(), value) for key, value in headers).get("location", "")
        mission = urllib.parse.urlparse(location).path
        verify(re.fullmatch(r"/practice_sessions/\d+", mission), "Mission redirect missing")
        verify(request("GET", mission, cookie=browser_cookie)[0] == 200, "Created mission unavailable")
        verify(request("POST", "/practice_sessions", cookie=browser_cookie)[0] == 422,
               "CSRF-free mutation accepted")
        pathlib.Path(STATE).write_text(json.dumps({"mission": mission, "cookie": device.OutputString(attrs=[])}))
    elif MODE == "restore":
        state = json.loads(pathlib.Path(STATE).read_text())
        verify(request("GET", state["mission"], cookie=state["cookie"])[0] == 200,
               "Persistent device cookie did not restore its mission in the new container")
    else:
        raise RuntimeError("Unknown check mode")
except Exception as error:
    print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)
