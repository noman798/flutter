// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _introText =
  "Tooltips are short identifying messages that briefly appear in response to "
  "a long press. Tooltip messages are also used by services that make Flutter "
  "apps accessible, like screen readers.";

class TooltipDemo extends StatelessComponent {
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text('Tooltip')
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Column(
            alignItems: FlexAlignItems.stretch,
            children: <Widget>[
              new Text(_introText, style: theme.text.subhead),
              new Row(
                children: <Widget>[
                  new Text('Long press the ', style: theme.text.subhead),
                  new Tooltip(
                    message: 'call icon',
                    child: new Icon(
                      size: IconSize.s18,
                      icon: 'communication/call',
                      color: theme.primaryColor
                    )
                  ),
                  new Text(' icon', style: theme.text.subhead)
                ]
              ),
              new Center(
                child: new IconButton(
                  size: IconSize.s48,
                  icon: 'communication/call',
                  color: theme.primaryColor,
                  tooltip: 'place a phone call',
                  onPressed: () {
                    Scaffold.of(context).showSnackBar(new SnackBar(
                       content: new Text('That was an ordinary tap')
                    ));
                  }
                )
              )
            ]
            .map((Widget widget) {
              return new Padding(
                padding: const EdgeDims.only(top: 16.0, left: 16.0, right: 16.0),
                child: widget
              );
            })
            .toList()
          );
        }
      )
    );
  }
}
