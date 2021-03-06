// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class AdaptedListItem extends StatelessComponent {
  AdaptedListItem({ Key key, this.name }) : super(key: key);

  final String name;

  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Container(
          width: 32.0,
          height: 32.0,
          margin: const EdgeDims.all(8.0),
          decoration: new BoxDecoration(
            backgroundColor: Colors.lightBlueAccent[100]
          )
        ),
        new Text(name)
      ]
    );
  }
}

class AdaptedGridItem extends StatelessComponent {
  AdaptedGridItem({ Key key, this.name }) : super(key: key);

  final String name;

  Widget build(BuildContext context) {
    return new Card(
      child: new Column(
        children: <Widget>[
          new Flexible(
            child: new Container(
              decoration: new BoxDecoration(
                backgroundColor: Colors.lightBlueAccent[100]
              )
            )
          ),
          new Container(
            margin: const EdgeDims.only(left: 8.0),
            child: new Row(
              children: <Widget>[
                new Flexible(
                  child: new Text(name)
                ),
                new IconButton(
                  icon: 'navigation/more_vert'
                )
              ]
            )
          )
        ]
      )
    );
  }
}

const double _kListItemExtent = 50.0;
const double _kMaxTileWidth = 150.0;
const double _kGridViewBreakpoint = 450.0;

class AdaptiveContainer extends StatelessComponent {
  AdaptiveContainer({ Key key, this.names }) : super(key: key);

  final List<String> names;

  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < _kGridViewBreakpoint) {
      return new ScrollableList(
        itemExtent: _kListItemExtent,
        children: names.map((String name) => new AdaptedListItem(name: name))
      );
    } else {
      return new ScrollableGrid(
        delegate: new MaxTileWidthGridDelegate(maxTileWidth: _kMaxTileWidth),
        children: names.map((String name) => new AdaptedGridItem(name: name))
      );
    }
  }
}

List<String> _initNames() {
  List<String> names = <String>[];
  for (int i = 0; i < 30; i++)
    names.add('Item $i');
  return names;
}

final List<String> _kNames = _initNames();

void main() {
  runApp(new MaterialApp(
    title: 'Media Query Example',
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) {
        return new Scaffold(
          toolBar: new ToolBar(
            center: new Text('Media Query Example')
          ),
          body: new Material(child: new AdaptiveContainer(names: _kNames))
        );
      }
    }
  ));
}
