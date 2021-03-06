// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'basic.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'routes.dart';

/// A modal route that replaces the entire screen.
abstract class PageRoute<T> extends ModalRoute<T> {
  PageRoute({
    Completer<T> completer,
    RouteSettings settings: const RouteSettings()
  }) : super(completer: completer, settings: settings);
  bool get opaque => true;
  bool get barrierDismissable => false;
  bool canTransitionTo(TransitionRoute nextRoute) => nextRoute is PageRoute;
  bool canTransitionFrom(TransitionRoute nextRoute) => nextRoute is PageRoute;

  AnimationController createAnimationController() {
    AnimationController controller = super.createAnimationController();
    if (settings.isInitialRoute)
      controller.value = 1.0;
    return controller;
  }

  /// Subclasses can override this method to customize how heroes are inserted.
  void insertHeroOverlayEntry(OverlayEntry entry, Object tag, OverlayState overlay) {
    overlay.insert(entry);
  }
}
