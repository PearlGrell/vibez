import 'package:flutter/widgets.dart';

int thumbCacheWidth(BuildContext context, double logicalWidth) =>
    (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();
