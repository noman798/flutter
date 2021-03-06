// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_behavior.dart';
import 'scrollable.dart';
import 'virtual_viewport.dart';

/// A vertically scrollable grid.
///
/// Requires that delegate places its children in row-major order.
class ScrollableGrid extends Scrollable {
  ScrollableGrid({
    Key key,
    double initialScrollOffset,
    ScrollListener onScroll,
    SnapOffsetCallback snapOffsetCallback,
    this.delegate,
    this.children
  }) : super(
    key: key,
    initialScrollOffset: initialScrollOffset,
    // TODO(abarth): Support horizontal offsets. For horizontally scrolling
    // grids. For horizontally scrolling grids, we'll probably need to use a
    // delegate that places children in column-major order.
    scrollDirection: Axis.vertical,
    onScroll: onScroll,
    snapOffsetCallback: snapOffsetCallback
  );

  final GridDelegate delegate;
  final Iterable<Widget> children;

  ScrollableState createState() => new _ScrollableGridState();
}

class _ScrollableGridState extends ScrollableState<ScrollableGrid> {
  ScrollBehavior createScrollBehavior() => new OverscrollBehavior();
  ExtentScrollBehavior get scrollBehavior => super.scrollBehavior;

  void _handleExtentsChanged(double contentExtent, double containerExtent) {
    setState(() {
      scrollTo(scrollBehavior.updateExtents(
        contentExtent: contentExtent,
        containerExtent: containerExtent,
        scrollOffset: scrollOffset
      ));
    });
  }

  Widget buildContent(BuildContext context) {
    return new GridViewport(
      startOffset: scrollOffset,
      delegate: config.delegate,
      onExtentsChanged: _handleExtentsChanged,
      children: config.children
    );
  }
}

class GridViewport extends VirtualViewport with VirtualViewportIterableMixin {
  GridViewport({
    this.startOffset,
    this.delegate,
    this.onExtentsChanged,
    this.children
  });

  final double startOffset;
  final GridDelegate delegate;
  final ExtentsChangedCallback onExtentsChanged;
  final Iterable<Widget> children;

  // TODO(abarth): Support horizontal scrolling;
  Axis get scrollDirection => Axis.vertical;

  RenderGrid createRenderObject() => new RenderGrid(delegate: delegate);

  _GridViewportElement createElement() => new _GridViewportElement(this);
}

// TODO(abarth): This function should go somewhere more general.
// See https://github.com/dart-lang/collection/pull/16
int _lowerBound(List sortedList, var value, { int begin: 0 }) {
  int current = begin;
  int count = sortedList.length - current;
  while (count > 0) {
    int step = count >> 1;
    int test = current + step;
    if (sortedList[test] < value) {
      current = test + 1;
      count -= step + 1;
    } else {
      count = step;
    }
  }
  return current;
}

class _GridViewportElement extends VirtualViewportElement<GridViewport> {
  _GridViewportElement(GridViewport widget) : super(widget);

  RenderGrid get renderObject => super.renderObject;

  int get materializedChildBase => _materializedChildBase;
  int _materializedChildBase;

  int get materializedChildCount => _materializedChildCount;
  int _materializedChildCount;

  double get startOffsetBase => _startOffsetBase;
  double _startOffsetBase;

  double get startOffsetLimit =>_startOffsetLimit;
  double _startOffsetLimit;

  void updateRenderObject(GridViewport oldWidget) {
    renderObject.delegate = widget.delegate;
    super.updateRenderObject(oldWidget);
  }

  double _contentExtent;
  double _containerExtent;
  GridSpecification _specification;

  void layout(BoxConstraints constraints) {
    _specification = renderObject.specification;
    double contentExtent = _specification.gridSize.height;
    double containerExtent = renderObject.size.height;

    int materializedRowBase = math.max(0, _lowerBound(_specification.rowOffsets, widget.startOffset) - 1);
    int materializedRowLimit = math.min(_specification.rowCount, _lowerBound(_specification.rowOffsets, widget.startOffset + containerExtent));

    _materializedChildBase = (materializedRowBase * _specification.columnCount).clamp(0, renderObject.virtualChildCount);
    _materializedChildCount = (materializedRowLimit * _specification.columnCount).clamp(0, renderObject.virtualChildCount) - _materializedChildBase;
    _startOffsetBase = _specification.rowOffsets[materializedRowBase];
    _startOffsetLimit = _specification.rowOffsets[materializedRowLimit] - containerExtent;

    super.layout(constraints);

    if (contentExtent != _contentExtent || containerExtent != _containerExtent) {
      _contentExtent = contentExtent;
      _containerExtent = containerExtent;
      widget.onExtentsChanged(_contentExtent, _containerExtent);
    }
  }
}
