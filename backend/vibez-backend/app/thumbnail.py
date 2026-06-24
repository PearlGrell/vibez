import re

_LH3_SIZE_RE = re.compile(r'=w\d+-h\d+')

def get_best_thumbnail(thumbnails, size=544):
    if not thumbnails:
        return ""
    try:
        best = max(thumbnails, key=lambda t: t.get("width", 0) * t.get("height", 0), default=None)
        if best:
            url = best.get("url", "")
            return upscale_thumbnail(url, size)
    except Exception:
        pass
    if isinstance(thumbnails, list) and thumbnails:
        url = thumbnails[0].get("url", "") if isinstance(thumbnails[0], dict) else ""
        return upscale_thumbnail(url, size)
    return ""


def upscale_thumbnail(url, size=544):
    if not url:
        return url
    if "lh3.googleusercontent.com" in url:
        return _LH3_SIZE_RE.sub(f'=w{size}-h{size}', url)
    return url
