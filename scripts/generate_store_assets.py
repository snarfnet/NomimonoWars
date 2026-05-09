from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import random

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "NomimonoWars" / "Assets.xcassets" / "AppIcon.appiconset"
SCREENSHOT_DIR = ROOT / "screenshots"

BG = (7, 13, 15)
PANEL = (28, 39, 42)
PANEL_2 = (20, 29, 31)
TEXT = (238, 248, 240)
SUB = (150, 170, 166)
LIME = (189, 245, 50)
CYAN = (61, 224, 237)
INK = (5, 8, 8)
LINE = (255, 255, 255, 30)


def font(size, bold=False):
    names = ["YuGothB.ttc" if bold else "YuGothM.ttc", "meiryob.ttc" if bold else "meiryo.ttc", "NotoSansJP-VF.ttf"]
    for name in names:
        path = Path("C:/Windows/Fonts") / name
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw, xy, label, size, fill=TEXT, bold=False, anchor=None, spacing=4):
    draw.multiline_text(xy, label, font=font(size, bold), fill=fill, anchor=anchor, spacing=spacing)


def fit_text(draw, label, max_width, size, bold=False, min_size=24):
    while size >= min_size:
        f = font(size, bold)
        box = draw.multiline_textbbox((0, 0), label, font=f, spacing=6)
        if box[2] - box[0] <= max_width:
            return f
        size -= 2
    return font(min_size, bold)


def gradient(size):
    bg_path = ROOT / "NomimonoWars" / "Assets.xcassets" / "GeneratedDrinkBackground.imageset" / "generated-drink-background.png"
    if bg_path.exists():
        src = Image.open(bg_path).convert("RGBA")
        src_ratio = src.width / src.height
        dst_ratio = size[0] / size[1]
        if src_ratio > dst_ratio:
            new_h = size[1]
            new_w = int(new_h * src_ratio)
        else:
            new_w = size[0]
            new_h = int(new_w / src_ratio)
        src = src.resize((new_w, new_h), Image.Resampling.LANCZOS)
        left = (new_w - size[0]) // 2
        top = (new_h - size[1]) // 2
        cropped = src.crop((left, top, left + size[0], top + size[1]))
        shade = Image.new("RGBA", size, (0, 0, 0, 126))
        lower = Image.new("RGBA", size, (0, 0, 0, 0))
        ld = ImageDraw.Draw(lower)
        ld.rectangle((0, int(size[1] * 0.42), size[0], size[1]), fill=(0, 0, 0, 88))
        return Image.alpha_composite(Image.alpha_composite(cropped, shade), lower)

    w, h = size
    img = Image.new("RGB", size, BG)
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / w * 0.35) + (y / h * 0.65)
            c = (
                int(7 + 8 * t),
                int(13 + 23 * t),
                int(15 + 18 * t),
            )
            px[x, y] = c
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(overlay)
    for i in range(-8, 12):
        y = int(h * 0.12 + i * h * 0.075)
        gd.line((-w * 0.25, y, w * 1.2, y - int(h * 0.38)), fill=(*CYAN, 18), width=max(2, w // 150))
        gd.line((-w * 0.35, y + int(h * 0.025), w * 1.1, y - int(h * 0.30)), fill=(*LIME, 14), width=max(2, w // 180))
    return Image.alpha_composite(img.convert("RGBA"), overlay)


def bubbles(draw, w, h):
    random.seed(11)
    for i in range(80):
        r = random.randint(4, 22)
        x = random.randint(-20, w + 20)
        y = random.randint(-20, h + 20)
        color = CYAN if i % 3 else LIME
        alpha = random.randint(18, 55)
        if i % 2:
            draw.ellipse((x, y, x + r, y + r), outline=(*color, alpha), width=max(1, r // 8))
        else:
            draw.ellipse((x, y, x + r, y + r), fill=(*color, alpha // 2))


def app_chrome(draw, w, h):
    top = int(h * 0.075)
    text(draw, (w // 2, top), "飲み物ウォーズ", int(w * 0.034), TEXT, True, "mm")
    draw.ellipse((int(w * 0.315), top - int(w * 0.017), int(w * 0.345), top + int(w * 0.013)), fill=LIME)


def card(draw, x, y, w, h, source, title, time, accent=CYAN):
    rounded(draw, (x, y, x + w, y + h), int(w * 0.045), (*PANEL, 238), (*LINE,), 2)
    pill_h = int(h * 0.17)
    rounded(draw, (x + 28, y + 26, x + 175, y + 26 + pill_h), pill_h // 2, accent)
    text(draw, (x + 102, y + 27 + pill_h // 2), source, int(w * 0.033), INK, True, "mm")
    text(draw, (x + w - 90, y + 33 + pill_h // 2), time, int(w * 0.031), SUB, True, "mm")
    f = fit_text(draw, title, w - 64, int(w * 0.055), True, int(w * 0.041))
    draw.multiline_text((x + 30, y + int(h * 0.36)), title, font=f, fill=TEXT, spacing=8)
    text(draw, (x + 36, y + h - 48), "読む", int(w * 0.028), SUB, True)
    draw.ellipse((x + w - 72, y + h - 78, x + w - 22, y + h - 28), fill=LIME)
    text(draw, (x + w - 47, y + h - 53), "↗", int(w * 0.038), INK, True, "mm")


def tabbar(draw, w, h, active=0):
    y = int(h * 0.865)
    margin = int(w * 0.07)
    gap = int(w * 0.025)
    bw = (w - margin * 2 - gap) // 2
    labels = [("速報", "●"), ("保存", "◆")]
    for i, (label, icon) in enumerate(labels):
        x = margin + i * (bw + gap)
        fill = LIME if i == active else PANEL
        fg = INK if i == active else SUB
        rounded(draw, (x, y, x + bw, y + int(h * 0.055)), int(h * 0.03), fill)
        text(draw, (x + bw // 2, y + int(h * 0.027)), label, int(w * 0.034), fg, True, "mm")


def screenshot(size, name, scene):
    w, h = size
    img = gradient(size)
    d = ImageDraw.Draw(img, "RGBA")
    bubbles(d, w, h)
    app_chrome(d, w, h)

    content_top = int(h * 0.12)
    mx = int(w * 0.06)

    if scene == 1:
        text(d, (mx, content_top), "DRINK RADAR", int(w * 0.027), LIME, True)
        text(d, (mx, content_top + int(h * 0.028)), "新作ドリンクを\n迎撃", int(w * 0.075), TEXT, True, spacing=4)
        rounded(d, (mx, content_top + int(h * 0.16), mx + int(w * 0.27), content_top + int(h * 0.195)), int(w * 0.025), (*PANEL, 245))
        text(d, (mx + int(w * 0.135), content_top + int(h * 0.178)), "新着 80本", int(w * 0.027), TEXT, True, "mm")
        tabs_y = content_top + int(h * 0.23)
        tab_w = (w - mx * 2 - int(w * 0.03) * 2) // 3
        for i, label in enumerate(["新商品", "ランキング", "ニュース"]):
            x = mx + i * (tab_w + int(w * 0.03))
            fill = LIME if i == 0 else PANEL
            fg = INK if i == 0 else SUB
            rounded(d, (x, tabs_y, x + tab_w, tabs_y + int(h * 0.075)), int(w * 0.035), fill)
            text(d, (x + tab_w // 2, tabs_y + int(h * 0.038)), label, int(w * 0.028), fg, True, "mm")
        y = tabs_y + int(h * 0.105)
        samples = [
            ("速報", "夏限定の炭酸ティーが登場\n爽快感と香りでSNS沸騰", "3分前", CYAN),
            ("新商品", "クラフトコーラ新作、全国コンビニで発売", "18分前", LIME),
        ]
        for s in samples:
            card(d, mx, y, w - mx * 2, int(h * 0.13), *s)
            y += int(h * 0.145)
    elif scene == 2:
        text(d, (mx, content_top), "RANKING", int(w * 0.03), LIME, True)
        text(d, (mx, content_top + int(h * 0.035)), "売れ筋の気配を\n一気にチェック", int(w * 0.07), TEXT, True, spacing=4)
        y = content_top + int(h * 0.18)
        for rank, label, color in [(1, "レモンスカッシュ系が急上昇", LIME), (2, "無糖コーヒーが安定人気", CYAN), (3, "ボトルティー新作が話題", (255, 114, 120)), (4, "エナジードリンク限定缶", (255, 210, 74))]:
            rounded(d, (mx, y, w - mx, y + int(h * 0.095)), int(w * 0.04), (*PANEL, 238), (*LINE,), 2)
            draw_rank = f"{rank}"
            d.ellipse((mx + 26, y + 28, mx + 92, y + 94), fill=color)
            text(d, (mx + 59, y + 61), draw_rank, int(w * 0.044), INK, True, "mm")
            text(d, (mx + 120, y + 32), label, int(w * 0.039), TEXT, True)
            text(d, (mx + 120, y + 78), "ランキング記事を追跡中", int(w * 0.024), SUB, True)
            y += int(h * 0.107)
    elif scene == 3:
        text(d, (mx, content_top), "BOOKMARKS", int(w * 0.03), LIME, True)
        text(d, (mx, content_top + int(h * 0.035)), "あとで読みたい記事を\n逃さない", int(w * 0.07), TEXT, True, spacing=4)
        y = content_top + int(h * 0.20)
        for i, title in enumerate(["気になる新作だけ保存", "発売日やレビューを見返す", "飲み比べ候補をまとめる"]):
            card(d, mx, y, w - mx * 2, int(h * 0.122), "保存", title, f"{i + 1}件目", LIME if i == 0 else CYAN)
            y += int(h * 0.137)
    elif scene == 4:
        text(d, (mx, content_top), "NEWS", int(w * 0.03), LIME, True)
        text(d, (mx, content_top + int(h * 0.035)), "飲料ニュースを\n軽快に流し読み", int(w * 0.07), TEXT, True, spacing=4)
        y = content_top + int(h * 0.21)
        for s in [
            ("NEWS", "PETボトル新作、初夏向けフレーバー拡充", "7分前", CYAN),
            ("市場", "健康志向の無糖飲料、前年比で伸長", "21分前", LIME),
            ("話題", "透明感のあるフルーツ炭酸が若年層に人気", "1時間前", (255, 114, 120)),
        ]:
            card(d, mx, y, w - mx * 2, int(h * 0.122), *s)
            y += int(h * 0.138)
    else:
        text(d, (mx, content_top), "FULL CHANGE", int(w * 0.03), LIME, True)
        text(d, (mx, content_top + int(h * 0.035)), "ボタンもカードも\n強く、読みやすく", int(w * 0.068), TEXT, True, spacing=4)
        y = content_top + int(h * 0.22)
        for label, color in [("新商品", LIME), ("ランキング", CYAN), ("ニュース", (255, 114, 120)), ("保存", (255, 210, 74))]:
            rounded(d, (mx, y, w - mx, y + int(h * 0.085)), int(w * 0.045), color)
            text(d, (w // 2, y + int(h * 0.043)), label, int(w * 0.04), INK, True, "mm")
            y += int(h * 0.105)

    tabbar(d, w, h, 0 if scene != 3 else 1)
    ad_h = int(h * 0.045)
    d.rectangle((0, h - ad_h, w, h), fill=(0, 0, 0, 255))
    text(d, (w // 2, h - ad_h // 2), "広告", int(w * 0.026), (150, 150, 150), True, "mm")
    img.convert("RGB").save(SCREENSHOT_DIR / name, quality=96)


def icon():
    out = ASSET_DIR / "AppIcon-1024.png"
    if out.exists():
        return
    size = 1024
    img = gradient((size, size))
    d = ImageDraw.Draw(img, "RGBA")
    bubbles(d, size, size)
    d.rounded_rectangle((118, 132, 906, 892), radius=210, fill=(12, 20, 22, 202), outline=(*LINE,), width=5)
    d.rounded_rectangle((318, 172, 706, 824), radius=118, fill=(225, 236, 226))
    d.rounded_rectangle((318, 172, 706, 824), radius=118, outline=(0, 0, 0, 90), width=7)
    d.rounded_rectangle((347, 205, 677, 362), radius=70, fill=CYAN)
    d.rounded_rectangle((372, 120, 652, 258), radius=58, fill=LIME)
    d.rounded_rectangle((401, 143, 623, 220), radius=36, fill=INK)
    d.polygon([(507, 384), (390, 594), (518, 560), (462, 795), (666, 490), (540, 528)], fill=(255, 232, 56))
    d.line((262, 705, 772, 275), fill=(*LIME, 130), width=20)
    d.line((248, 760, 802, 328), fill=(*CYAN, 95), width=12)
    img.convert("RGB").save(out, quality=98)


def main():
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    icon()
    sizes = {
        "iphone-6.9": (1290, 2796),
        "iphone-6.5": (1284, 2778),
        "iphone-5.5": (1242, 2208),
    }
    for prefix, size in sizes.items():
        for scene in range(1, 6):
            screenshot(size, f"{prefix}-{scene:02d}.jpg", scene)


if __name__ == "__main__":
    main()
