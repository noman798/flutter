// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'ink_well.dart';
import 'theme.dart';

/// Material List items are one to three lines of text optionally flanked by icons.
/// Icons are defined with the [left] and [right] parameters. The first line of text
/// is not optional and is specified with [primary]. The value of [secondary] will
/// occupy the space allocated for an aditional line of text, or two lines if
/// isThreeLine: true is specified. If dense: true is specified then the overall
/// height of this list item and the size of the DefaultTextStyles that wrap
/// the [primary] and [secondary] widget are reduced.
class ListItem extends StatelessComponent {
  ListItem({
    Key key,
    this.left,
    this.primary,
    this.secondary,
    this.right,
    this.isThreeLine: false,
    this.dense: false,
    this.enabled: true,
    this.onTap,
    this.onLongPress
  }) : super(key: key) {
    assert(primary != null);
    assert(isThreeLine ? secondary != null : true);
  }

  final Widget left;
  final Widget primary;
  final Widget secondary;
  final Widget right;
  final bool isThreeLine;
  final bool dense;
  final bool enabled;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;

  TextStyle primaryTextStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = theme.text.subhead;
    if (!enabled) {
      final Color color = theme.disabledColor;
      return dense ? style.copyWith(fontSize: 13.0, color: color) : style.copyWith(color: color);
    }
    return dense ? style.copyWith(fontSize: 13.0) : style;
  }

  TextStyle secondaryTextStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.text.caption.color;
    final TextStyle style = theme.text.body1;
    return dense ? style.copyWith(color: color, fontSize: 12.0) : style.copyWith(color: color);
  }

  Widget build(BuildContext context) {
    final bool isTwoLine = !isThreeLine && secondary != null;
    final bool isOneLine = !isThreeLine && !isTwoLine;
    double itemHeight;
    if (isOneLine)
      itemHeight = dense ? 48.0 : 56.0;
    else if (isTwoLine)
      itemHeight = dense ? 60.0 : 72.0;
    else
      itemHeight = dense ? 76.0 : 88.0;

    double iconMarginTop = 0.0;
    if (isThreeLine)
      iconMarginTop = dense ? 8.0 : 16.0;

    // Overall, the list item is a Row() with these children.
    final List<Widget> children = <Widget>[];

    if (left != null) {
      children.add(new Container(
        margin: new EdgeDims.only(right: 16.0, top: iconMarginTop),
        width: 40.0,
        child: new Align(
          alignment: new FractionalOffset(0.0, isThreeLine ? 0.0 : 0.5),
          child: left
        )
      ));
    }

    final Widget primaryLine = new DefaultTextStyle(
      style: primaryTextStyle(context),
      child: primary
    );
    Widget center = primaryLine;
    if (isTwoLine || isThreeLine) {
      center = new Column(
        justifyContent: FlexJustifyContent.collapse,
        alignItems: FlexAlignItems.start,
        children: <Widget>[
          primaryLine,
          new DefaultTextStyle(
            style: secondaryTextStyle(context),
            child: secondary
          )
        ]
      );
    }
    children.add(new Flexible(
      child: center
    ));

    if (right != null) {
      children.add(new Container(
        margin: new EdgeDims.only(left: 16.0, top: iconMarginTop),
        child: new Align(
          alignment: new FractionalOffset(1.0, isThreeLine ? 0.0 : 0.5),
          child: right
        )
      ));
    }

    return new InkWell(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      child: new Container(
        height: itemHeight,
        padding: const EdgeDims.symmetric(horizontal: 16.0),
        child: new Row(
          alignItems: FlexAlignItems.center,
          children: children
        )
      )
    );
  }
}
