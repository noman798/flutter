// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class IconsDemo extends StatefulComponent {
  IconsDemoState createState() => new IconsDemoState();
}

class IconsDemoState extends State<IconsDemo> {
  static final List<Map<int, Color>> iconColorSwatches = <Map<int, Color>>[
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey
  ];

  int iconColorIndex = 2;
  double iconOpacity = 1.0;

  Color get iconColor => iconColorSwatches[iconColorIndex][400];

  void handleIconButtonPress() {
    setState(() {
      iconColorIndex = (iconColorIndex + 1) % iconColorSwatches.length;
    });
  }

  Widget buildIconButton(IconSize size, String name, bool enabled) {
    return new IconButton(
      size: size,
      icon: name,
      color: iconColor,
      tooltip: "${enabled ? 'enabled' : 'disabled'} $name icon button",
      onPressed: enabled ? handleIconButtonPress : null
    );
  }

  Widget buildSizeLabel(int size, TextStyle style) {
    return new SizedBox(
      height: size.toDouble() + 16.0, // to match an IconButton's padded height
      child: new Center(
        child: new Text('$size', style: style)
      )
    );
  }

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle = theme.text.subhead.copyWith(color: theme.text.caption.color);

    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text('Icons')
      ),
      body: new IconTheme(
        data: new IconThemeData(opacity: iconOpacity),
        child: new Padding(
          padding: const EdgeDims.all(24.0),
          child: new Column(
            children: <Widget>[
              new Row(
                justifyContent: FlexJustifyContent.spaceBetween,
                alignItems: FlexAlignItems.center,
                children: <Widget>[
                  new Flexible(
                    flex: 0,
                    child: new Column(
                      alignItems: FlexAlignItems.center,
                      children: <Widget>[
                        new Text('Size', style: textStyle),
                        buildSizeLabel(18, textStyle),
                        buildSizeLabel(24, textStyle),
                        buildSizeLabel(36, textStyle),
                        buildSizeLabel(48, textStyle)
                      ]
                    )
                  ),
                  new Flexible(
                    child: new Column(
                      alignItems: FlexAlignItems.center,
                      children: <Widget>[
                        new Text('Enabled', style: textStyle),
                        buildIconButton(IconSize.s18, 'action/face', true),
                        buildIconButton(IconSize.s24, 'action/alarm', true),
                        buildIconButton(IconSize.s36, 'action/home', true),
                        buildIconButton(IconSize.s48, 'action/android', true)
                      ]
                    )
                  ),
                  new Flexible(
                    child: new Column(
                      alignItems: FlexAlignItems.center,
                      children: <Widget>[
                        new Text('Disabled', style: textStyle),
                        buildIconButton(IconSize.s18, 'action/face', false),
                        buildIconButton(IconSize.s24, 'action/alarm', false),
                        buildIconButton(IconSize.s36, 'action/home', false),
                        buildIconButton(IconSize.s48, 'action/android', false)
                      ]
                    )
                  )
                ]
              ),
              new Flexible(
                child: new Center(
                  child: new IconTheme(
                    data: new IconThemeData(opacity: 1.0),
                    child: new Row(
                      justifyContent: FlexJustifyContent.center,
                      children: <Widget>[
                        new Icon(
                          icon: 'image/brightness_7',
                          color: iconColor.withAlpha(0x33) // 0.2 * 255 = 0x33
                        ),
                        new Slider(
                          value: iconOpacity,
                          min: 0.2,
                          max: 1.0,
                          activeColor: iconColor,
                          onChanged: (double newValue) {
                            setState(() {
                              iconOpacity = newValue;
                            });
                          }
                        ),
                        new Icon(
                          icon: 'image/brightness_7',
                          color: iconColor.withAlpha(0xFF)
                        ),
                      ]
                    )
                  )
                )
              )
            ]
          )
        )
      )
    );
  }
}
