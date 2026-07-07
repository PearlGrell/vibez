String hiResThumbnail(String url, {int size = 600}) {
  if (url.isEmpty) return url;
  return url
      .replaceAll(RegExp(r'=w\d+-h\d+'), '=w$size-h$size')
      .replaceAll(RegExp(r'=s\d+'), '=s$size');
}
