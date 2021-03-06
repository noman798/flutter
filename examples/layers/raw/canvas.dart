// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use the ui.Canvas interface to draw various shapes
// with gradients and transforms.

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';

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

  ui.Paint paint = new ui.Paint();
  canvas.drawPaint(new ui.Paint()..color = const ui.Color(0xFFFFFFFF));

  ui.Size size = paintBounds.size;
  ui.Point mid = size.center(ui.Point.origin);
  double radius = size.shortestSide / 2.0;

  canvas.save();
  canvas.translate(-mid.x/2.0, ui.window.size.height*2.0);
  canvas.clipRect(
      new ui.Rect.fromLTRB(0.0, -ui.window.size.height, ui.window.size.width, radius));

  canvas.translate(mid.x, mid.y);
  paint.color = const ui.Color.fromARGB(128, 255, 0, 255);
  canvas.rotate(math.PI/4.0);

  ui.Gradient yellowBlue = new ui.Gradient.linear(
    <ui.Point>[new ui.Point(-radius, -radius), new ui.Point(0.0, 0.0)],
    <ui.Color>[const ui.Color(0xFFFFFF00), const ui.Color(0xFF0000FF)]
  );
  canvas.drawRect(new ui.Rect.fromLTRB(-radius, -radius, radius, radius),
                  new ui.Paint()..shader = yellowBlue);

  // Scale x and y by 0.5.
  Float64List scaleMatrix = new Float64List.fromList(<double>[
      0.5, 0.0, 0.0, 0.0,
      0.0, 0.5, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0,
  ]);
  canvas.transform(scaleMatrix);
  paint.color = const ui.Color.fromARGB(128, 0, 255, 0);
  canvas.drawCircle(ui.Point.origin, radius, paint);

  canvas.restore();

  canvas.translate(0.0, 50.0);

  // A DrawLooper is a powerful painting primitive that lets you apply several
  // blending and filtering passes over a sequence of commands "in a loop". For
  // example, the looper below draws the circle tree times, once with a blur,
  // then with a gradient blend, and finally with just an offset.
  ui.LayerDrawLooperBuilder builder = new ui.LayerDrawLooperBuilder()
    ..addLayerOnTop(
        new ui.DrawLooperLayerInfo()
          ..setOffset(const ui.Offset(150.0, 0.0))
          ..setColorMode(ui.TransferMode.src)
          ..setPaintBits(ui.PaintBits.all),
        new ui.Paint()
          ..color = const ui.Color.fromARGB(128, 255, 255, 0)
          ..colorFilter = new ui.ColorFilter.mode(
              const ui.Color.fromARGB(128, 0, 0, 255),
              ui.TransferMode.srcIn
            )
          ..maskFilter = new ui.MaskFilter.blur(
              ui.BlurStyle.normal, 3.0, highQuality: true
            )
      )
    ..addLayerOnTop(
        new ui.DrawLooperLayerInfo()
          ..setOffset(const ui.Offset(75.0, 75.0))
          ..setColorMode(ui.TransferMode.src)
          ..setPaintBits(ui.PaintBits.shader),
        new ui.Paint()
          ..shader = new ui.Gradient.radial(
              new ui.Point(0.0, 0.0), radius/3.0,
              <ui.Color>[
                const ui.Color(0xFFFFFF00),
                const ui.Color(0xFFFF0000)
              ],
              null,
              ui.TileMode.mirror
            )
          // Since we're don't set ui.PaintBits.maskFilter, this has no effect.
          ..maskFilter = new ui.MaskFilter.blur(
              ui.BlurStyle.normal, 50.0, highQuality: true
            )
      )
    ..addLayerOnTop(
        new ui.DrawLooperLayerInfo()..setOffset(const ui.Offset(225.0, 75.0)),
        // Since this layer uses a DST color mode, this has no effect.
        new ui.Paint()..color = const ui.Color.fromARGB(128, 255, 0, 0)
      );
  paint.drawLooper = builder.build();
  canvas.drawCircle(ui.Point.origin, radius, paint);

  // When we're done issuing painting commands, we end the recording an receive
  // a Picture, which is an immutable record of the commands we've issued. You
  // can draw a Picture into another canvas or include it as part of a
  // composited scene.
  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  final double devicePixelRatio = ui.window.devicePixelRatio;
  ui.Rect sceneBounds = new ui.Rect.fromLTWH(
    0.0,
    0.0,
    ui.window.size.width * devicePixelRatio,
    ui.window.size.height * devicePixelRatio
  );
  Float64List deviceTransform = new Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  ui.SceneBuilder sceneBuilder = new ui.SceneBuilder(sceneBounds)
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();
  return sceneBuilder.build();
}

void beginFrame(Duration timeStamp) {
  ui.Rect paintBounds = ui.Point.origin & ui.window.size;
  ui.Picture picture = paint(paintBounds);
  ui.Scene scene = composite(picture, paintBounds);
  ui.window.render(scene);
}

void main() {
  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}
