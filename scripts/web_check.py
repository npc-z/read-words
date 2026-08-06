"""Web 端冒烟验证:打开页面,断言应用 UI 实际渲染(非白屏/非错误态/非卡死)。

判定依据(替代不可读的 canvas 文本):
- 稳定渲染:连续截图一致
- 应用 UI 出现:底部右侧存在主色(FAB/按钮,M3 primary ≈ #4B5C92)
- 无错误态:不存在红色图标像素(#F44336 错误图标)
- 无控制台错误 / 无 pageerror

用法: python scripts/web_check.py [BASE_URL]
依赖 devenv 环境(python venv 含 playwright + pillow,系统 chromium)。
"""

import hashlib
import shutil
import sys

from PIL import Image
from playwright.sync_api import sync_playwright

BASE = sys.argv[1] if len(sys.argv) > 1 else 'http://localhost:8080'

# M3 seed #2563EB 的派生色(实测):FAB=primaryContainer (219,225,255),
# 主按钮=primary (75,92,146)。任一出现即应用 UI 已渲染。
FAB_COLOR = (219, 225, 255)
BTN_COLOR = (75, 92, 146)
TOL = 40
RED = (244, 67, 67)


def close(a, b, tol=TOL):
    return all(abs(x - y) <= tol for x, y in zip(a, b))


def analyze(path):
    img = Image.open(path).convert('RGB')
    px = img.load()
    w, h = img.size
    fab = btn = err = 0
    for y in range(0, h, 3):
        for x in range(0, w, 3):
            c = px[x, y]
            if c is None:
                continue
            if x > w * 0.75 and y > h * 0.8 and close(c, FAB_COLOR):
                fab += 1
            elif 0.3 * w < x < 0.7 * w and 0.5 * h < y < 0.75 * h and close(c, BTN_COLOR):
                btn += 1
            elif close(c, RED):
                err += 1
    return fab, btn, err


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

    for i, data in enumerate([shot1, shot2, shot3]):
        with open(f'/tmp/web_check_{i}.png', 'wb') as f:
            f.write(data)

    fab_px, btn_px, err_px = analyze('/tmp/web_check_1.png')
    settled = digest(shot1) == digest(shot2) or digest(shot2) == digest(shot3)
    rendered = settled and len(shot1) > 15000
    print(
        f'--- RESULT: rendered={rendered} fab={fab_px} btn={btn_px} error_red={err_px} '
        f'(shots={len(shot1)}B/{len(shot2)}B/{len(shot3)}B, '
        f'1==2:{digest(shot1) == digest(shot2)}, 2==3:{digest(shot2) == digest(shot3)})'
    )
    if errors:
        print('FAIL: console errors')
        sys.exit(1)
    if not rendered:
        print('FAIL: page not stably rendered')
        sys.exit(1)
    if fab_px < 60 or btn_px < 30:
        print('FAIL: app UI not rendered (FAB/button pixels missing)')
        sys.exit(1)
    if err_px > 20:
        print('FAIL: error-state red pixels present')
        sys.exit(1)
    print('OK')
