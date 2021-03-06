// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flx/bundle.dart';
import 'package:flx/signing.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'base/file_system.dart' show ensureDirectoryExists;
import 'globals.dart';
import 'toolchain.dart';
import 'zip.dart';

const String defaultMainPath = 'lib/main.dart';
const String defaultAssetBasePath = '.';
const String defaultMaterialAssetBasePath = 'packages/material_design_icons/icons';
const String defaultManifestPath = 'flutter.yaml';
const String defaultFlxOutputPath = 'build/app.flx';
const String defaultSnapshotPath = 'build/snapshot_blob.bin';
const String defaultPrivateKeyPath = 'privatekey.der';

const String _kSnapshotKey = 'snapshot_blob.bin';
Map<String, double> _kIconDensities = {
  'mdpi': 1.0,
  'hdpi' : 1.5,
  'xhdpi' : 2.0,
  'xxhdpi' : 3.0,
  'xxxhdpi' : 4.0
};
const List<String> _kThemes = const <String>['white', 'black'];
const List<int> _kSizes = const <int>[18, 24, 36, 48];

class _Asset {
  final String source;
  final String base;
  final String key;

  _Asset({ this.source, this.base, this.key });
}

Map<_Asset, List<_Asset>> _parseAssets(Map manifestDescriptor, String assetBase) {
  Map<_Asset, List<_Asset>> result = <_Asset, List<_Asset>>{};
  if (manifestDescriptor == null)
    return result;
  if (manifestDescriptor.containsKey('assets')) {
    for (String asset in manifestDescriptor['assets']) {
      _Asset baseAsset = new _Asset(base: assetBase, key: asset);
      List<_Asset> variants = <_Asset>[];
      result[baseAsset] = variants;
      // Find asset variants
      String assetPath = path.join(assetBase, asset);
      String assetFilename = path.basename(assetPath);
      Directory assetDir = new Directory(path.dirname(assetPath));
      List<FileSystemEntity> files = assetDir.listSync(recursive: true);
      for (FileSystemEntity entity in files) {
        if (path.basename(entity.path) == assetFilename &&
            FileSystemEntity.isFileSync(entity.path) &&
            entity.path != assetPath) {
          String key = path.relative(entity.path, from: assetBase);
          variants.add(new _Asset(base: assetBase, key: key));
        }
      }
    }
  }
  return result;
}

class _MaterialAsset extends _Asset {
  final String name;
  final String density;
  final String theme;
  final int size;

  _MaterialAsset(this.name, this.density, this.theme, this.size, String assetBase)
    : super(base: assetBase);

  String get source {
    List<String> parts = name.split('/');
    String category = parts[0];
    String subtype = parts[1];
    return '$category/drawable-$density/ic_${subtype}_${theme}_${size}dp.png';
  }

  String get key {
    List<String> parts = name.split('/');
    String category = parts[0];
    String subtype = parts[1];
    double devicePixelRatio = _kIconDensities[density];
    if (devicePixelRatio == 1.0)
      return '$category/ic_${subtype}_${theme}_${size}dp.png';
    else
      return '$category/${devicePixelRatio}x/ic_${subtype}_${theme}_${size}dp.png';
  }
}

Iterable/*<T>*/ _generateValues/*<T>*/(
  Map/*<String, T>*/ assetDescriptor,
  String key,
  Iterable/*<T>*/ defaults
) {
  return assetDescriptor.containsKey(key) ? /*<T>*/[assetDescriptor[key]] : defaults;
}

void _accumulateMaterialAssets(Map<_Asset, List<_Asset>> result, Map assetDescriptor, String assetBase) {
  String name = assetDescriptor['name'];
  for (String theme in _generateValues(assetDescriptor, 'theme', _kThemes)) {
    for (int size in _generateValues(assetDescriptor, 'size', _kSizes)) {
      _MaterialAsset main = new _MaterialAsset(name, 'mdpi', theme, size, assetBase);
      List<_Asset> variants = <_Asset>[];
      result[main] = variants;
      for (String density in _generateValues(assetDescriptor, 'density', _kIconDensities.keys)) {
        if (density == 'mdpi')
          continue;
        variants.add(new _MaterialAsset(name, density, theme, size, assetBase));
      }
    }
  }
}

Map<_Asset, List<_Asset>> _parseMaterialAssets(Map manifestDescriptor, String assetBase) {
  Map<_Asset, List<_Asset>> result = <_Asset, List<_Asset>>{};
  if (manifestDescriptor == null || !manifestDescriptor.containsKey('material-design-icons'))
    return result;
  for (Map assetDescriptor in manifestDescriptor['material-design-icons']) {
    _accumulateMaterialAssets(result, assetDescriptor, assetBase);
  }
  return result;
}

dynamic _loadManifest(String manifestPath) {
  if (manifestPath == null || !FileSystemEntity.isFileSync(manifestPath))
    return null;
  String manifestDescriptor = new File(manifestPath).readAsStringSync();
  return loadYaml(manifestDescriptor);
}

ZipEntry _createAssetEntry(_Asset asset) {
  String source = asset.source ?? asset.key;
  File file = new File('${asset.base}/$source');
  if (!file.existsSync()) {
    printError('Cannot find asset "$source" in directory "${path.absolute(asset.base)}".');
    return null;
  }
  return new ZipEntry.fromFile(asset.key, file);
}

ZipEntry _createAssetManifest(Map<_Asset, List<_Asset>> assets) {
  Map<String, List<String>> json = <String, List<String>>{};
  for (_Asset main in assets.keys) {
    List<String> variants = <String>[];
    for (_Asset variant in assets[main])
      variants.add(variant.key);
    json[main.key] = variants;
  }
  return new ZipEntry.fromString('AssetManifest.json', JSON.encode(json));
}

ZipEntry _createFontManifest(Map manifestDescriptor) {
  if (manifestDescriptor != null && manifestDescriptor.containsKey('fonts')) {
    return new ZipEntry.fromString('FontManifest.json', JSON.encode(manifestDescriptor['fonts']));
  } else {
    return null;
  }
}

/// Build the flx in the build/ directory and return `localBundlePath` on success.
Future<String> buildFlx(
  Toolchain toolchain, {
  String mainPath: defaultMainPath
}) async {
  int result;
  String localBundlePath = path.join('build', 'app.flx');
  String localSnapshotPath = path.join('build', 'snapshot_blob.bin');
  result = await build(
    toolchain,
    snapshotPath: localSnapshotPath,
    outputPath: localBundlePath,
    mainPath: mainPath
  );
  if (result == 0)
    return localBundlePath;
  else
    throw result;
}

/// The result from [buildInTempDir]. Note that this object should be disposed after use.
class DirectoryResult {
  final Directory directory;
  final String localBundlePath;

  DirectoryResult(this.directory, this.localBundlePath);

  /// Call this to delete the temporary directory.
  void dispose() {
    directory.deleteSync(recursive: true);
  }
}

Future<int> build(
  Toolchain toolchain, {
  String materialAssetBasePath: defaultMaterialAssetBasePath,
  String mainPath: defaultMainPath,
  String manifestPath: defaultManifestPath,
  String outputPath: defaultFlxOutputPath,
  String snapshotPath: defaultSnapshotPath,
  String privateKeyPath: defaultPrivateKeyPath,
  bool precompiledSnapshot: false
}) async {
  Map manifestDescriptor = _loadManifest(manifestPath);
  String assetBasePath = path.dirname(path.absolute(manifestPath));

  File snapshotFile;

  if (!precompiledSnapshot) {
    ensureDirectoryExists(snapshotPath);

    // In a precompiled snapshot, the instruction buffer contains script
    // content equivalents
    int result = await toolchain.compiler.compile(mainPath: mainPath, snapshotPath: snapshotPath);
    if (result != 0) {
      printError('Failed to run the Flutter compiler. Exit code: $result');
      return result;
    }

    snapshotFile = new File(snapshotPath);
  }

  return assemble(
      manifestDescriptor: manifestDescriptor,
      snapshotFile: snapshotFile,
      assetBasePath: assetBasePath,
      materialAssetBasePath: materialAssetBasePath,
      outputPath: outputPath,
      privateKeyPath: privateKeyPath
  );
}

Future<int> assemble({
  Map manifestDescriptor: const {},
  File snapshotFile,
  String assetBasePath: defaultAssetBasePath,
  String materialAssetBasePath: defaultMaterialAssetBasePath,
  String outputPath: defaultFlxOutputPath,
  String privateKeyPath: defaultPrivateKeyPath
}) async {
  printTrace('Building $outputPath');

  Map<_Asset, List<_Asset>> assets = _parseAssets(manifestDescriptor, assetBasePath);
  assets.addAll(_parseMaterialAssets(manifestDescriptor, materialAssetBasePath));

  ZipBuilder zipBuilder = new ZipBuilder();

  if (snapshotFile != null)
    zipBuilder.addEntry(new ZipEntry.fromFile(_kSnapshotKey, snapshotFile));

  for (_Asset asset in assets.keys) {
    ZipEntry assetEntry = _createAssetEntry(asset);
    if (assetEntry == null)
      return 1;
    else
      zipBuilder.addEntry(assetEntry);

    for (_Asset variant in assets[asset]) {
      ZipEntry variantEntry = _createAssetEntry(variant);
      if (variantEntry == null)
        return 1;
      else
        zipBuilder.addEntry(variantEntry);
    }
  }

  zipBuilder.addEntry(_createAssetManifest(assets));

  ZipEntry fontManifest = _createFontManifest(manifestDescriptor);
  if (fontManifest != null)
    zipBuilder.addEntry(fontManifest);

  AsymmetricKeyPair keyPair = keyPairFromPrivateKeyFileSync(privateKeyPath);
  printTrace('KeyPair from $privateKeyPath: $keyPair.');

  if (keyPair != null) {
    printTrace('Calling CipherParameters.seedRandom().');
    CipherParameters.get().seedRandom();
  }

  File zipFile = new File(outputPath.substring(0, outputPath.length - 4) + '.zip');
  printTrace('Encoding zip file to ${zipFile.path}');
  zipBuilder.createZip(zipFile, new Directory('build/flx'));
  List<int> zipBytes = zipFile.readAsBytesSync();

  ensureDirectoryExists(outputPath);

  printTrace('Creating flx at $outputPath.');
  Bundle bundle = new Bundle.fromContent(
    path: outputPath,
    manifest: manifestDescriptor,
    contentBytes: zipBytes,
    keyPair: keyPair
  );
  bundle.writeSync();

  printTrace('Built $outputPath.');

  return 0;
}
