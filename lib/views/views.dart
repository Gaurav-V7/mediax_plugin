import 'package:flutter/cupertino.dart';

/// Returns a [Widget] that wraps the given [child] widget with a [Builder] which
/// provides the [MediaQuery] of the current context.
///
/// The [Padding] widget is used to add the current [MediaQuery]'s padding to the
/// [child] widget. This is useful when you want to ensure a widget is not
/// obscured by the notch or home indicator on iOS devices.
///
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
