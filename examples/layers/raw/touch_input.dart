// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to put some pixels on the screen using the raw
// interface to the engine.

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:sky_services/pointer/pointer.mojom.dart';

ui.Color color;

ui.Picture paint(ui.Rect paintBounds) {
  // First we create a PictureRecorder to record the commands we're going to
  // feed in the canvas. The PictureRecorder will eventually produce a Picture,
  // which is an immutable record of those commands.
  ui.PictureRecorder recorder = new ui.PictureRecorder();

  // Next, we create a canvas from the recorder. The canvas is an interface
  // which can receive drawing commands. The canvas interface is modeled after
  // the SkCanvas interface from Skia. The paintBounds establishes a "cull rect"
  // for the canvas, which lets the implementation discard any commands that
  // are entirely outside this rectangle.
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

  // The commands draw a circle in the center of the screen.
  ui.Size size = paintBounds.size;
  canvas.drawCircle(
    size.center(ui.Point.origin),
    size.shortestSide * 0.45,
    new ui.Paint()..color = color
  );

  // When we're done issuing painting commands, we end the recording an receive
  // a Picture, which is an immutable record of the commands we've issued. You
  // can draw a Picture into another canvas or include it as part of a
  // composited scene.
  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  // The device pixel ratio gives an approximate ratio of the size of pixels on
  // the device's screen to "normal" sized pixels. We commonly work in logical
  // pixels, which are then scalled by the device pixel ratio before being drawn
  // on the screen.
  final double devicePixelRatio = ui.window.devicePixelRatio;
  ui.Rect sceneBounds = new ui.Rect.fromLTWH(
      0.0,
      0.0,
      ui.window.size.width * devicePixelRatio,
      ui.window.size.height * devicePixelRatio
  );

  // This transform scales the x and y coordinates by the devicePixelRatio.
  Float64List deviceTransform = new Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;

  // We build a very simple scene graph with two nodes. The root node is a
  // transform that scale its children by the device pixel ratio. This transform
  // lets us paint in "logical" pixels which are converted to device pixels by
  // this scaling operation.
  ui.SceneBuilder sceneBuilder = new ui.SceneBuilder(sceneBounds)
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();

  // When we're done recording the scene, we call build() to obtain an immutable
  // record of the scene we've recorded.
  return sceneBuilder.build();
}

void beginFrame(Duration timeStamp) {
  ui.Rect paintBounds = ui.Point.origin & ui.window.size;
  // First, record a picture with our painting commands.
  ui.Picture picture = paint(paintBounds);
  // Second, include that picture in a scene graph.
  ui.Scene scene = composite(picture, paintBounds);
  // Third, instruct the engine to render that scene graph.
  ui.window.render(scene);
}

// Pointer input arrives as an array of bytes. The format for the data is
// defined by pointer.mojom, which generates serializes and parsers for a
// number of languages, including Dart, C++, Java, and Go.
void handlePointerPacket(ByteData serializedPacket) {
  // We wrap the byte data up into a Mojo Message object, which we then
  // deserialize according to the mojom definition.
  bindings.Message message = new bindings.Message(serializedPacket, <core.MojoHandle>[], serializedPacket.lengthInBytes, 0);
  PointerPacket packet = PointerPacket.deserialize(message);

  // The deserialized pointer packet contains a number of pointer movements,
  // which we iterate through and process.
  for (Pointer pointer in packet.pointers) {
    if (pointer.type == PointerType.down) {
      // If the pointer went down, we change the color of the circle to blue.
      color = const ui.Color(0xFF0000FF);
      // Rather than calling paint() synchronously, we ask the engine to
      // schedule a frame. The engine will call onBeginFrame when it is actually
      // time to produce the frame.
      ui.window.scheduleFrame();
    } else if (pointer.type == PointerType.up) {
      // Similarly, if the pointer went up, we change the color of the circle to
      // green and schedule a frame. It's harmless to call scheduleFrame many
      // times because the engine will ignore redundant requests up until the
      // point where the engine calls onBeginFrame, which signals the boundary
      // between one frame and another.
      color = const ui.Color(0xFF00FF00);
      ui.window.scheduleFrame();
    }
  }
}

// This function is the primary entry point to your application. The engine
// calls main() as soon as it has loaded your code.
void main() {
  color = const ui.Color(0xFF00FF00);
  // The engine calls onBeginFrame whenever it wants us to produce a frame.
  ui.window.onBeginFrame = beginFrame;
  // The engine calls onPointerPacket whenever it had updated information about
  // the pointers directed at our app.
  ui.window.onPointerPacket = handlePointerPacket;
  // Here we kick off the whole process by asking the engine to schedule a new
  // frame. The engine will eventually call onBeginFrame when it is time for us
  // to actually produce the frame.
  ui.window.scheduleFrame();
}
