// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'icon.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'theme.dart';
import 'tooltip.dart';

/// A material design "icon button".
///
/// An icon button is a picture printed on a [Material] widget that reacts to
/// touches by filling with color.
///
/// Use icon buttons on toolbars.
///
/// If the [onPressed] callback is not specified or null, then the button will
/// be disabled, will not react to touch.
class IconButton extends StatelessComponent {
  const IconButton({
    Key key,
    this.size: IconSize.s24,
    this.icon,
    this.colorTheme,
    this.color,
    this.onPressed,
    this.tooltip
  }) : super(key: key);

  final IconSize size;
  final String icon;
  final IconThemeColor colorTheme;
  final Color color;

  /// The callback that is invoked when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;
  final String tooltip;

  Widget build(BuildContext context) {
    Widget result = new Padding(
      padding: const EdgeDims.all(8.0),
      child: new Icon(
        size: size,
        icon: icon,
        colorTheme: colorTheme,
        color: onPressed != null ? color : Theme.of(context).disabledColor
      )
    );
    if (tooltip != null) {
      result = new Tooltip(
        message: tooltip,
        child: result
      );
    }
    return new InkResponse(
      onTap: onPressed,
      child: result
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$icon');
    if (onPressed == null)
      description.add('disabled');
    if (colorTheme != null)
      description.add('$colorTheme');
    if (tooltip != null)
      description.add('tooltip: "$tooltip"');
  }
}
