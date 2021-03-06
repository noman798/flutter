// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'icon.dart';
import 'icon_button.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'list_item.dart';
import 'material.dart';
import 'theme.dart';

const Duration _kMenuDuration = const Duration(milliseconds: 300);
const double _kBaselineOffsetFromBottom = 20.0;
const double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuHorizontalPadding = 16.0;
const double _kMenuItemHeight = 48.0;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuVerticalPadding = 8.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuScreenPadding = 8.0;

class PopupMenuItem<T> extends StatelessComponent {
  PopupMenuItem({
    Key key,
    this.value,
    this.enabled: true,
    this.hasDivider: false,
    this.child
  }) : super(key: key);

  final T value;
  final bool enabled;
  final bool hasDivider;
  final Widget child;

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    TextStyle style = theme.text.subhead;
    if (!enabled)
      style = style.copyWith(color: theme.disabledColor);

    Widget item = new DefaultTextStyle(
      style: style,
      child: new Baseline(
        baseline: _kMenuItemHeight - _kBaselineOffsetFromBottom,
        child: child
      )
    );
    if (!enabled) {
      final bool isDark = theme.brightness == ThemeBrightness.dark;
      item = new IconTheme(
        data: new IconThemeData(opacity: isDark ? 0.5 : 0.38),
        child: item
      );
    }

    return new MergeSemantics(
      child: new Container(
        height: _kMenuItemHeight,
        padding: const EdgeDims.symmetric(horizontal: _kMenuHorizontalPadding),
        decoration: !hasDivider ? null : new BoxDecoration(
          border: new Border(bottom: new BorderSide(color: theme.dividerColor))
        ),
        child: item
      )
    );
  }
}

class CheckedPopupMenuItem<T> extends PopupMenuItem<T> {
  CheckedPopupMenuItem({
    Key key,
    T value,
    checked: false,
    bool enabled: true,
    Widget child
  }) : super(
    key: key,
    value: value,
    enabled: enabled,
    child: new ListItem(
      enabled: enabled,
      left: new Icon(icon: checked ? 'action/done' : null),
      primary: child
    )
  );
}

class _PopupMenu<T> extends StatelessComponent {
  _PopupMenu({
    Key key,
    this.route
  }) : super(key: key);

  final _PopupMenuRoute<T> route;

  Widget build(BuildContext context) {
    double unit = 1.0 / (route.items.length + 1.5); // 1.0 for the width and 0.5 for the last item's fade.
    List<Widget> children = <Widget>[];

    for (int i = 0; i < route.items.length; ++i) {
      final double start = (i + 1) * unit;
      final double end = (start + 1.5 * unit).clamp(0.0, 1.0);
      CurvedAnimation opacity = new CurvedAnimation(
        parent: route.animation,
        curve: new Interval(start, end)
      );
      final bool enabled = route.items[i].enabled;
      Widget item = route.items[i];
      if (route.initialValue != null && route.initialValue == route.items[i].value) {
        item = new Container(
          decoration: new BoxDecoration(backgroundColor: Theme.of(context).highlightColor),
          child: item
        );
      }
      children.add(new FadeTransition(
        opacity: opacity,
        child: new InkWell(
          onTap: enabled ? () { Navigator.pop(context, route.items[i].value); } : null,
          child: item
        )
      ));
    }

    final CurveTween opacity = new CurveTween(curve: new Interval(0.0, 1.0 / 3.0));
    final CurveTween width = new CurveTween(curve: new Interval(0.0, unit));
    final CurveTween height = new CurveTween(curve: new Interval(0.0, unit * route.items.length));

    Widget child = new ConstrainedBox(
      constraints: new BoxConstraints(
        minWidth: _kMenuMinWidth,
        maxWidth: _kMenuMaxWidth
      ),
      child: new IntrinsicWidth(
        stepWidth: _kMenuWidthStep,
        child: new Block(
          children: children,
          padding: const EdgeDims.symmetric(
            vertical: _kMenuVerticalPadding
          )
        )
      )
    );

    return new AnimatedBuilder(
      animation: route.animation,
      builder: (BuildContext context, Widget child) {
        return new Opacity(
          opacity: opacity.evaluate(route.animation),
          child: new Material(
            type: MaterialType.card,
            elevation: route.elevation,
            child: new Align(
              alignment: const FractionalOffset(1.0, 0.0),
              widthFactor: width.evaluate(route.animation),
              heightFactor: height.evaluate(route.animation),
              child: child
            )
          )
        );
      },
      child: child
    );
  }
}

class _PopupMenuRouteLayout extends OneChildLayoutDelegate {
  _PopupMenuRouteLayout(this.position, this.selectedIndex);

  final ModalPosition position;
  final int selectedIndex;

  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: 0.0,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: constraints.maxHeight
    );
  }

  // Put the child wherever position specifies, so long as it will fit within the
  // specified parent size padded (inset) by 8. If necessary, adjust the child's
  // position so that it fits.
  Offset getPositionForChild(Size size, Size childSize) {
    double x = position?.left
      ?? (position?.right != null ? size.width - (position.right + childSize.width) : _kMenuScreenPadding);
    double y = position?.top
      ?? (position?.bottom != null ? size.height - (position.bottom - childSize.height) : _kMenuScreenPadding);

    if (selectedIndex != -1)
      y -= (_kMenuItemHeight * selectedIndex) + _kMenuVerticalPadding + _kMenuItemHeight / 2.0;

    if (x < _kMenuScreenPadding)
      x = _kMenuScreenPadding;
    else if (x + childSize.width > size.width - 2 * _kMenuScreenPadding)
      x = size.width - childSize.width - _kMenuScreenPadding;
    if (y < _kMenuScreenPadding)
      y = _kMenuScreenPadding;
    else if (y + childSize.height > size.height - 2 * _kMenuScreenPadding)
      y = size.height - childSize.height - _kMenuScreenPadding;
    return new Offset(x, y);
  }

  bool shouldRelayout(_PopupMenuRouteLayout oldDelegate) {
    return position != oldDelegate.position;
  }
}

class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    Completer<T> completer,
    this.position,
    this.items,
    this.initialValue,
    this.elevation
  }) : super(completer: completer);

  final ModalPosition position;
  final List<PopupMenuItem<T>> items;
  final dynamic initialValue;
  final int elevation;

  ModalPosition getPosition(BuildContext context) => null;

  Animation<double> createAnimation() {
    return new CurvedAnimation(
      parent: super.createAnimation(),
      reverseCurve: new Interval(0.0, _kMenuCloseIntervalEnd)
    );
  }

  Duration get transitionDuration => _kMenuDuration;
  bool get barrierDismissable => true;
  Color get barrierColor => null;

  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
    int selectedIndex = -1;
    if (initialValue != null) {
      for (int i = 0; i < items.length; i++)
        if (initialValue == items[i].value) {
          selectedIndex = i;
          break;
        }
    }
    final Size screenSize = MediaQuery.of(context).size;
    return new ConstrainedBox(
      constraints: new BoxConstraints(maxWidth: screenSize.width, maxHeight: screenSize.height),
      child: new CustomOneChildLayout(
        delegate: new _PopupMenuRouteLayout(position, selectedIndex),
        child: new _PopupMenu(route: this)
      )
    );
  }
}

/// Show a popup menu that contains the [items] at [position]. If [initialValue]
/// is specified then the first item with a matching value will be highlighted
/// and the value of [position] implies where the left, center point of the
/// highlighted item should appear. If [initialValue] is not specified then position
/// implies the menu's origin.
Future/*<T>*/ showMenu/*<T>*/({
  BuildContext context,
  ModalPosition position,
  List<PopupMenuItem/*<T>*/> items,
  dynamic/*=T*/ initialValue,
  int elevation: 8
}) {
  assert(context != null);
  assert(items != null && items.length > 0);
  Completer completer = new Completer/*<T>*/();
  Navigator.push(context, new _PopupMenuRoute/*<T>*/(
    completer: completer,
    position: position,
    items: items,
    initialValue: initialValue,
    elevation: elevation
  ));
  return completer.future;
}

/// A callback that is passed the value of the PopupMenuItem that caused
/// its menu to be dismissed.
typedef void PopupMenuItemSelected<T>(T value);

/// Displays a menu when pressed and calls [onSelected] when the menu is dismissed
/// because an item was selected. The value passed to [onSelected] is the value of
/// the selected menu item. If child is null then a standard 'navigation/more_vert'
/// icon is created.
class PopupMenuButton<T> extends StatefulComponent {
  PopupMenuButton({
    Key key,
    this.items,
    this.initialValue,
    this.onSelected,
    this.tooltip: 'Show menu',
    this.elevation: 8,
    this.child
  }) : super(key: key);

  final List<PopupMenuItem<T>> items;
  final T initialValue;
  final PopupMenuItemSelected<T> onSelected;
  final String tooltip;
  final int elevation;
  final Widget child;

  _PopupMenuButtonState<T> createState() => new _PopupMenuButtonState<T>();
}

class _PopupMenuButtonState<T> extends State<PopupMenuButton<T>> {
  void showButtonMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject();
    final Point topLeft = renderBox.localToGlobal(Point.origin);
    showMenu/*<T>*/(
      context: context,
      elevation: config.elevation,
      items: config.items,
      initialValue: config.initialValue,
      position: new ModalPosition(
        left: topLeft.x,
        top: topLeft.y + (config.initialValue != null ? renderBox.size.height / 2.0 : 0.0)
      )
    )
    .then((T value) {
      if (value != null && config.onSelected != null)
        config.onSelected(value);
    });
  }

  Widget build(BuildContext context) {
    if (config.child == null) {
      return new IconButton(
        icon: 'navigation/more_vert',
        tooltip: config.tooltip,
        onPressed: () { showButtonMenu(context); }
      );
    }
    return new InkWell(
      onTap: () { showButtonMenu(context); },
      child: config.child
    );
  }
}
