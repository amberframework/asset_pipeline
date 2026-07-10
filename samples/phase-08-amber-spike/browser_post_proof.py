"""Phase 8A — Browser POST proof.

Drives Chrome (headless) through the spike's sign-in screen to verify
that a REAL browser form submission from the UI::Form-rendered page
reaches the controller's submit action and surfaces the flash notice
in the re-render. Captures three artifacts to the spike directory:

  findings-browser-get.png        — GET / rendered in the browser
  findings-browser-submit.png     — POST response after submitting
  findings-browser-network.json   — network log so the POST request
                                    can be audited offline

The closing gate for Phase 8A.
"""

from __future__ import annotations
import json
import os
import sys
import time
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By

SPIKE = Path(
    "/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/phase-08-amber-spike"
)
URL = "http://localhost:3000/"

opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--no-sandbox")
opts.add_argument("--disable-gpu")
opts.add_argument("--window-size=1024,768")
# Enable performance logging so we can capture the POST network event.
opts.set_capability("goog:loggingPrefs", {"performance": "ALL"})

driver = webdriver.Chrome(options=opts)

try:
    driver.get(URL)
    time.sleep(0.5)
    title = driver.title
    page_source = driver.page_source

    # GET screenshot
    get_path = SPIKE / "findings-browser-get.png"
    driver.save_screenshot(str(get_path))
    print(f"GET screenshot:  {get_path} ({get_path.stat().st_size} bytes)")
    print(f"GET title:       {title!r}")

    # Verify the form rendered correctly in the real browser
    assert "<form" in page_source, "no <form> element in DOM"
    assert "action=\"/sign_in/submit\"" in page_source, "form action missing"
    assert "name=\"_csrf\"" in page_source, "_csrf hidden input missing"
    assert "name=\"email\"" in page_source, "email input missing"
    assert "name=\"password\"" in page_source, "password input missing"
    assert "type=\"submit\"" in page_source, "submit button missing"
    print("OK   form, _csrf, email, password, submit all present in DOM")

    # Locate inputs and type values
    email_el = driver.find_element(By.CSS_SELECTOR, "input[name='email']")
    pwd_el = driver.find_element(By.CSS_SELECTOR, "input[name='password']")
    submit_btn = driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
    email_el.clear()
    email_el.send_keys("seth@example.com")
    pwd_el.clear()
    pwd_el.send_keys("password123")
    print(f"Email value before submit: {email_el.get_attribute('value')!r}")

    # Trigger the form submit — this is the real browser POST.
    submit_btn.click()
    time.sleep(1.0)

    post_source = driver.page_source
    submit_path = SPIKE / "findings-browser-submit.png"
    driver.save_screenshot(str(submit_path))
    print(f"POST screenshot: {submit_path} ({submit_path.stat().st_size} bytes)")

    # Capture the network log for the POST
    perf_log = driver.get_log("performance")
    network_path = SPIKE / "findings-browser-network.json"
    relevant = []
    for entry in perf_log:
        try:
            msg = json.loads(entry.get("message", "{}")).get("message", {})
        except json.JSONDecodeError:
            continue
        method = msg.get("method", "")
        if method not in {
            "Network.requestWillBeSent",
            "Network.responseReceived",
        }:
            continue
        params = msg.get("params", {})
        req = params.get("request", {}) or {}
        resp = params.get("response", {}) or {}
        url = req.get("url") or resp.get("url") or ""
        if "sign_in" not in url and url.rstrip("/") != "http://localhost:3000":
            continue
        relevant.append(
            {
                "method": method,
                "request_method": req.get("method"),
                "url": url,
                "post_data": req.get("postData"),
                "status": resp.get("status"),
            }
        )
    network_path.write_text(json.dumps(relevant, indent=2))
    print(f"Network log:     {network_path} ({len(relevant)} relevant events)")

    # Verify the flash notice surfaced post-submit
    if "Signed in as seth@example.com" in post_source:
        print("OK   flash notice 'Signed in as seth@example.com' visible after submit")
        sys.exit(0)
    else:
        print("FAIL flash notice missing — partial dump follows:")
        print(post_source[:2000])
        sys.exit(2)
finally:
    driver.quit()
