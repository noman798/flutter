// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class _ContactCategory extends StatelessComponent {
  _ContactCategory({ Key key, this.icon, this.children }) : super(key: key);

  final String icon;
  final List<Widget> children;

  Widget build(BuildContext context) {
    return new Container(
      padding: const EdgeDims.symmetric(vertical: 16.0),
      decoration: new BoxDecoration(
        border: new Border(bottom: new BorderSide(color: Theme.of(context).dividerColor))
      ),
      child: new DefaultTextStyle(
        style: Theme.of(context).text.subhead,
        child: new Row(
          children: <Widget>[
            new SizedBox(
              width: 72.0,
              child: new Icon(icon: icon, color: Theme.of(context).primaryColor)
            ),
            new Flexible(child: new Column(children: children))
          ]
        )
      )
    );
  }
}

class _ContactItem extends StatelessComponent {
  _ContactItem({ Key key, this.icon, this.lines }) : super(key: key) {
    assert(lines.length > 1);
  }

  final String icon;
  final List<String> lines;

  Widget build(BuildContext context) {
    List<Widget> columnChildren = lines.sublist(0, lines.length - 1).map((String line) => new Text(line)).toList();
    columnChildren.add(new Text(lines.last, style: Theme.of(context).text.caption));

    List<Widget> rowChildren = <Widget>[
      new Column(
        alignItems: FlexAlignItems.start,
        children: columnChildren
      )
    ];
    if (icon != null) {
      rowChildren.add(new SizedBox(
        width: 72.0,
        child: new Icon(icon: icon, color: Theme.of(context).disabledColor)
      ));
    }
    return new Padding(
      padding: const EdgeDims.symmetric(vertical: 16.0),
      child: new Row(
        justifyContent: FlexJustifyContent.spaceBetween,
        children: rowChildren
      )
    );
  }
}

class FlexibleSpaceDemo extends StatefulComponent {
  FlexibleSpaceDemoState createState() => new FlexibleSpaceDemoState();
}

class FlexibleSpaceDemoState extends State<FlexibleSpaceDemo> {
  final double appBarHeight = 256.0;
  final Key scrollableKey = new UniqueKey();

  Widget build(BuildContext context) {
    return new Theme(
      data: new ThemeData(
        brightness: ThemeBrightness.light,
        primarySwatch: Colors.indigo
      ),
      child: new Scaffold(
        appBarHeight: appBarHeight,
        scrollableKey: scrollableKey,
        appBarBehavior: AppBarBehavior.scroll,
        toolBar: new ToolBar(
          right: <Widget>[
            new IconButton(
              icon: 'content/create',
              tooltip: 'Search'
            ),
            new IconButton(
              icon: 'navigation/more_vert',
              tooltip: 'Show menu'
            )
          ],
          flexibleSpace: (BuildContext context) {
            return new FlexibleSpaceBar(
              title : new Text('Ali Connors'),
              image: new AssetImage(
                name: 'packages/flutter_gallery_assets/ali_connors.png',
                fit: ImageFit.cover,
                height: appBarHeight
              )
            );
          }
        ),
        body: new Block(
          scrollableKey: scrollableKey,
          padding: new EdgeDims.only(top: appBarHeight),
          children: <Widget>[
            new _ContactCategory(
              icon: 'communication/call',
              children: <Widget>[
                new _ContactItem(
                  icon: 'communication/message',
                  lines: <String>[
                    '(650) 555-1234',
                    'Mobile'
                  ]
                ),
                new _ContactItem(
                  icon: 'communication/message',
                  lines: <String>[
                    '(323) 555-6789',
                    'Work'
                  ]
                )
              ]
            ),
            new _ContactCategory(
              icon: 'communication/email',
              children: <Widget>[
                new _ContactItem(
                  lines: <String>[
                    'ali_connors@example.com',
                    'Personal'
                  ]
                ),
                new _ContactItem(
                  lines: <String>[
                    'aliconnors@example.com',
                    'Work'
                  ]
                )
              ]
            ),
            new _ContactCategory(
              icon: 'communication/location_on',
              children: <Widget>[
                new _ContactItem(
                  lines: <String>[
                    '2000 Main Street',
                    'San Francisco, CA',
                    'Home'
                  ]
                ),
                new _ContactItem(
                  lines: <String>[
                    '1600 Amphitheater Parkway',
                    'Mountain View, CA',
                    'Work'
                  ]
                ),
                new _ContactItem(
                  lines: <String>[
                    '126 Severyns Ave',
                    'Mountain View, CA',
                    'Jet Travel'
                  ]
                )
              ]
            )
          ]
        )
      )
    );
  }
}
