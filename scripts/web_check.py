"""Web 端冒烟验证:打开页面,断言 UI 已渲染(非空白画布)并输出控制台日志。

用法: python scripts/web_check.py [BASE_URL]
依赖 devenv 环境(python venv 含 playwright,系统 chromium)。
"""

import hashlib
import shutil
import sys

from playwright.sync_api import sync_playwright

BASE = sys.argv[1] if len(sys.argv) > 1 else 'http://localhost:8080'


def digest(data):
    return hashlib.sha256(data).hexdigest()[:16]


with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=True,
        executable_path=shutil.which('chromium'),
        args=['--no-sandbox'],
    )
    page = browser.new_page()
    logs = []
    page.on('console', lambda m: logs.append(f'[{m.type}] {m.text}'))
    page.on('pageerror', lambda e: logs.append(f'[pageerror] {e}'))
    page.goto(BASE, wait_until='domcontentloaded')
    page.wait_for_selector('flutter-view', timeout=15000)
    page.wait_for_timeout(10000)
    shot1 = page.screenshot(full_page=True)
    page.wait_for_timeout(1000)
    shot2 = page.screenshot(full_page=True)
    page.wait_for_timeout(1000)
    shot3 = page.screenshot(full_page=True)
    body = page.locator('body').inner_text().strip()
    print('--- BODY TEXT ---')
    print(body if body else '(empty)')
    print('--- CONSOLE ---')
    print('\n'.join(logs) if logs else '(no logs)')
    errors = [l for l in logs if l.startswith('[error]') or l.startswith('[pageerror]')]
    browser.close()

    settled = digest(shot1) == digest(shot2) or digest(shot2) == digest(shot3)
    rendered = settled and len(shot1) > 15000
    print(
        f'--- RESULT: rendered={rendered} '
        f'(shots={len(shot1)}B/{len(shot2)}B/{len(shot3)}B, '
        f'1==2:{digest(shot1) == digest(shot2)}, 2==3:{digest(shot2) == digest(shot3)})'
    )
    if errors:
        print('FAIL: console errors')
        sys.exit(1)
    if not rendered:
        print('FAIL: page not stably rendered')
        sys.exit(1)
    print('OK')
