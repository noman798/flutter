// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/http.dart' as http;

import 'package:mojo/core.dart' as core;
import 'package:mojo_services/mojo/asset_bundle/asset_bundle.mojom.dart';

import 'fetch.dart';
import 'image_cache.dart';
import 'image_decoder.dart';
import 'image_resource.dart';
import 'binding.dart';

abstract class AssetBundle {
  ImageResource loadImage(String key);
  Future<String> loadString(String key);
  Future<core.MojoDataPipeConsumer> load(String key);
  String toString() => '$runtimeType@$hashCode()';
}

class NetworkAssetBundle extends AssetBundle {
  NetworkAssetBundle(Uri baseUrl) : _baseUrl = baseUrl;

  final Uri _baseUrl;

  String _urlFromKey(String key) => _baseUrl.resolve(key).toString();

  Future<core.MojoDataPipeConsumer> load(String key) async {
    return (await fetchUrl(_urlFromKey(key))).body;
  }

  ImageResource loadImage(String key) => imageCache.load(_urlFromKey(key));

  Future<String> loadString(String key) async {
    return (await http.get(_urlFromKey(key))).body;
  }

  String toString() => '$runtimeType@$hashCode($_baseUrl)';
}

abstract class CachingAssetBundle extends AssetBundle {
  final Map<String, ImageResource> imageResourceCache =
    <String, ImageResource>{};
  final Map<String, Future<String>> _stringCache =
    <String, Future<String>>{};

  Future<ImageInfo> fetchImage(String key) async {
    return new ImageInfo(image: await decodeImageFromDataPipe(await load(key)));
  }

  ImageResource loadImage(String key) {
    return imageResourceCache.putIfAbsent(key, () {
      return new ImageResource(fetchImage(key));
    });
  }

  Future<String> _fetchString(String key) async {
    core.MojoDataPipeConsumer pipe = await load(key);
    ByteData data = await core.DataPipeDrainer.drainHandle(pipe);
    return new String.fromCharCodes(new Uint8List.view(data.buffer));
  }

  Future<String> loadString(String key) {
    return _stringCache.putIfAbsent(key, () => _fetchString(key));
  }
}

class MojoAssetBundle extends CachingAssetBundle {
  MojoAssetBundle(this._bundle);

  factory MojoAssetBundle.fromNetwork(String relativeUrl) {
    AssetBundleProxy bundle = new AssetBundleProxy.unbound();
    _fetchAndUnpackBundle(relativeUrl, bundle);
    return new MojoAssetBundle(bundle);
  }

  static Future _fetchAndUnpackBundle(String relativeUrl, AssetBundleProxy bundle) async {
    core.MojoDataPipeConsumer bundleData = (await fetchUrl(relativeUrl)).body;
    AssetUnpackerProxy unpacker = new AssetUnpackerProxy.unbound();
    shell.connectToService("mojo:asset_bundle", unpacker);
    unpacker.ptr.unpackZipStream(bundleData, bundle);
    unpacker.close();
  }

  AssetBundleProxy _bundle;

  Future<core.MojoDataPipeConsumer> load(String key) async {
    return (await _bundle.ptr.getAsStream(key)).assetData;
  }
}

AssetBundle _initRootBundle() {
  try {
    AssetBundleProxy bundle = new AssetBundleProxy.fromHandle(
      new core.MojoHandle(ui.takeRootBundleHandle())
    );
    return new MojoAssetBundle(bundle);
  } catch (e) {
    return null;
  }
}

final AssetBundle rootBundle = _initRootBundle();
