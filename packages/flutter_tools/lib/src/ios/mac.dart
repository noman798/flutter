// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../artifacts.dart';
import '../base/context.dart';
import '../base/process.dart';
import '../globals.dart';
import '../services.dart';
import 'setup_xcodeproj.dart';

String get homeDirectory => path.absolute(Platform.environment['HOME']);

// TODO(devoncarew): Refactor functionality into XCode.

const int kXcodeRequiredVersionMajor = 7;
const int kXcodeRequiredVersionMinor = 2;

class XCode {
  static void initGlobal() {
    context[XCode] = new XCode();
  }

  bool get isInstalledAndMeetsVersionCheck => isInstalled && xcodeVersionSatisfactory;

  bool _isInstalled;
  bool get isInstalled {
    if (_isInstalled != null) {
      return _isInstalled;
    }

    _isInstalled = exitsHappy(<String>['xcode-select', '--print-path']);
    return _isInstalled;
  }

  /// Has the EULA been signed?
  bool get eulaSigned {
    if (!isInstalled)
      return false;

    try {
      ProcessResult result = Process.runSync('/usr/bin/xcrun', <String>['clang']);
      if (result.stdout != null && result.stdout.contains('license'))
        return false;
      if (result.stderr != null && result.stderr.contains('license'))
        return false;
      return true;
    } catch (error) {
      return false;
    }
  }

  bool _xcodeVersionSatisfactory;
  bool get xcodeVersionSatisfactory {
    if (_xcodeVersionSatisfactory != null)
      return _xcodeVersionSatisfactory;

    try {
      String output = runSync(<String>['xcodebuild', '-version']);
      RegExp regex = new RegExp(r'Xcode ([0-9.]+)');

      String version = regex.firstMatch(output).group(1);
      List<String> components = version.split('.');

      int major = int.parse(components[0]);
      int minor = components.length == 1 ? 0 : int.parse(components[1]);

      _xcodeVersionSatisfactory = _xcodeVersionCheckValid(major, minor);
    } catch (error) {
      _xcodeVersionSatisfactory = false;
    }

    return _xcodeVersionSatisfactory;
  }
}

bool _xcodeVersionCheckValid(int major, int minor) {
  if (major > kXcodeRequiredVersionMajor)
    return true;

  if (major == kXcodeRequiredVersionMajor)
    return minor >= kXcodeRequiredVersionMinor;

  return false;
}

Future<bool> buildIOSXcodeProject(ApplicationPackage app, { bool buildForDevice }) async {
  String flutterProjectPath = Directory.current.path;

  if (xcodeProjectRequiresUpdate()) {
    printTrace('Initializing the Xcode project.');
    if ((await setupXcodeProjectHarness(flutterProjectPath)) != 0) {
      printError('Could not initialize the Xcode project.');
      return false;
    }
  } else {
   updateXcodeLocalProperties(flutterProjectPath);
  }

  if (!_validateEngineRevision(app))
    return false;

  if (!_checkXcodeVersion())
    return false;

  // Before the build, all service definitions must be updated and the dylibs
  // copied over to a location that is suitable for Xcodebuild to find them.

  await _addServicesToBundle(new Directory(app.localPath));

  List<String> commands = <String>[
    '/usr/bin/env', 'xcrun', 'xcodebuild', '-target', 'Runner', '-configuration', 'Release'
  ];

  if (buildForDevice) {
    commands.addAll(<String>['-sdk', 'iphoneos', '-arch', 'arm64']);
  } else {
    commands.addAll(<String>['-sdk', 'iphonesimulator', '-arch', 'x86_64']);
  }

  try {
    runCheckedSync(commands, workingDirectory: app.localPath);
    return true;
  } catch (error) {
    return false;
  }
}

final RegExp _xcodeVersionRegExp = new RegExp(r'Xcode (\d+)\..*');
final String _xcodeRequirement = 'Xcode 7.0 or greater is required to develop for iOS.';

bool _checkXcodeVersion() {
  if (!Platform.isMacOS)
    return false;
  try {
    String version = runCheckedSync(<String>['xcodebuild', '-version']);
    Match match = _xcodeVersionRegExp.firstMatch(version);
    if (int.parse(match[1]) < 7) {
      printError('Found "${match[0]}". $_xcodeRequirement');
      return false;
    }
  } catch (e) {
    printError('Cannot find "xcodebuid". $_xcodeRequirement');
    return false;
  }
  return true;
}

bool _validateEngineRevision(ApplicationPackage app) {
  String skyRevision = ArtifactStore.engineRevision;
  String iosRevision = _getIOSEngineRevision(app);

  if (iosRevision != skyRevision) {
    printError("Error: incompatible sky_engine revision.");
    printStatus('sky_engine revision: $skyRevision, iOS engine revision: $iosRevision');
    return false;
  } else {
    printTrace('sky_engine revision: $skyRevision, iOS engine revision: $iosRevision');
    return true;
  }
}

String _getIOSEngineRevision(ApplicationPackage app) {
  File revisionFile = new File(path.join(app.localPath, 'REVISION'));
  if (revisionFile.existsSync()) {
    return revisionFile.readAsStringSync().trim();
  } else {
    return null;
  }
}

Future _addServicesToBundle(Directory bundle) async {
  List<Map<String, String>> services = [];
  printTrace("Trying to resolve native pub services.");

  // Step 1: Parse the service configuration yaml files present in the service
  //         pub packages.
  await parseServiceConfigs(services);
  printTrace("Found ${services.length} service definition(s).");

  // Step 2: Copy framework dylibs to the correct spot for xcodebuild to pick up.
  Directory frameworksDirectory = new Directory(path.join(bundle.path, "Frameworks"));
  await _copyServiceFrameworks(services, frameworksDirectory);

  // Step 3: Copy the service definitions manifest at the correct spot for
  //         xcodebuild to pick up.
  File manifestFile = new File(path.join(bundle.path, "ServiceDefinitions.json"));
  _copyServiceDefinitionsManifest(services, manifestFile);
}

Future _copyServiceFrameworks(List<Map<String, String>> services, Directory frameworksDirectory) async {
  printTrace("Copying service frameworks to '${path.absolute(frameworksDirectory.path)}'.");
  frameworksDirectory.createSync(recursive: true);
  for (Map<String, String> service in services) {
    String dylibPath = await getServiceFromUrl(service['ios-framework'], service['root'], service['name']);
    File dylib = new File(dylibPath);
    printTrace("Copying ${dylib.path} into bundle.");
    if (!dylib.existsSync()) {
      printError("The service dylib '${dylib.path}' does not exist.");
      continue;
    }
    // Shell out so permissions on the dylib are preserved.
    runCheckedSync(['/bin/cp', dylib.path, frameworksDirectory.path]);
  }
}

void _copyServiceDefinitionsManifest(List<Map<String, String>> services, File manifest) {
  printTrace("Creating service definitions manifest at '${manifest.path}'");
  List<Map<String, String>> jsonServices = services.map((Map<String, String> service) => {
    'name': service['name'],
    // Since we have already moved it to the Frameworks directory. Strip away
    // the directory and basenames.
    'framework': path.basenameWithoutExtension(service['ios-framework'])
  }).toList();
  Map<String, dynamic> json = { 'services' : jsonServices };
  manifest.writeAsStringSync(JSON.encode(json), mode: FileMode.WRITE, flush: true);
}
