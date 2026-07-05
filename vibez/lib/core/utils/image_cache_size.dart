import 'package:flutter/widgets.dart';

/// Decode cap for network thumbnails: converts a logical display size to
/// physical pixels so full-resolution art isn't decoded (and kept in memory)
/// for small tiles.
int thumbCacheWidth(BuildContext context, double logicalWidth) =>
    (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();
