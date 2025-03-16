import 'package:flutter/cupertino.dart';

Widget mediaQuery({required Widget child}) {
  return Builder(builder: (BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: mediaQuery.padding.left,
        right: mediaQuery.padding.right,
        top: mediaQuery.padding.top,
        bottom: mediaQuery.padding.bottom,
      ),
      child: child,
    );
  });
}
