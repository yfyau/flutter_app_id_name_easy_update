import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_application_id/custom_exceptions.dart';
import 'package:flutter_application_id/file_updater/rules/xml.dart';

import 'configuration.dart';
import 'constants.dart';
import 'file_updater/file_updater.dart';
import 'file_updater/rules/gradle.dart';
import 'file_updater/rules/pbxproj.dart';
import 'file_updater/rules/plist.dart';

const String fileOption = 'file';
const String helpFlag = 'help';

Future<void> updateApplicationIdFromArguments(List<String> arguments) async {
  final parser = ArgParser(allowTrailingOptions: true);
  parser.addFlag(
    helpFlag,
    abbr: 'h',
    help: 'Usage help',
    negatable: false,
  );
  // Make default null to differentiate when it is explicitly set
  parser.addOption(
    fileOption,
    abbr: 'f',
    help: 'Config file (default: $DEFAULT_CONFIG_FILES)',
  );
  final argResults = parser.parse(arguments);

  if (argResults[helpFlag]) {
    stdout.writeln('Updates application id for iOS and Android');
    stdout.writeln(parser.usage);
    exit(0);
  }

  try {
    final config = await loadConfigFileFromArgResults(
      argResults,
      verbose: true,
    );

    await updateApplicationIdFromConfig(config);
  } catch (e) {
    if (e is InvalidFormatException) {
      stderr.writeln('Invalid configuration format.');
    } else {
      stderr.writeln(e);
    }
    exit(2);
  }
}

Future<void> updateAndroidApplicationIdFromConfig(Configuration config) async {
  if (config.android == null) return;

  if (config.android!.id != null) {
    stdout.writeln('Updating Android application Id');
    FileUpdater.updateFile(
      File(ANDROID_GRADLE_FILE),
      GradleString(
        ANDROID_APPID_KEY,
        config.android!.id!,
      ),
    );
  }
  if (config.android!.name != null) {
    stdout.writeln('Updating Android application name');
    FileUpdater.updateFile(
      File(ANDROID_MANIFEST_FILE),
      XmlAttribute(
        ANDROID_APPNAME_KEY,
        config.android!.name!,
      ),
    );
  }
}

Future<void> updateIosApplicationIdFromConfig(Configuration config) async {
  if (config.ios == null) return;

  if (config.ios!.id != null) {
    stdout.writeln('Updating iOS application Id');
    FileUpdater.updateFile(
      File(IOS_PBXPROJ_FILE),
      Pbxproj(
        IOS_APPID_KEY,
        config.ios!.id!,
      ),
    );
  }
  if (config.ios!.name != null) {
    stdout.writeln('Updating iOS application name');
    FileUpdater.updateFile(
      File(IOS_PLIST_FILE),
      Plist(
        IOS_APPNAME_KEY,
        config.ios!.name!,
      ),
    );
  }
}

Future<void> updateApplicationIdFromConfig(Configuration config) async {
  updateAndroidApplicationIdFromConfig(config);
  updateIosApplicationIdFromConfig(config);
}

Future<Configuration> loadConfigFileFromArgResults(
  ArgResults argResults, {
  bool verbose = false,
}) async {
  final config = await loadConfigFile(
    filePath: argResults[fileOption],
    verbose: verbose,
  );
  if (config != null) return config;

  for (String configFile in DEFAULT_CONFIG_FILES) {
    final defaultConfig = await loadConfigFile(
      filePath: configFile,
      verbose: verbose,
    );
    if (defaultConfig != null) return defaultConfig;
  }

  throw NoConfigFoundException();
}

Future<Configuration?> loadConfigFile({
  String? filePath,
  bool verbose = false,
}) async {
  if (filePath == null) return null;

  try {
    return Configuration.fromFile(File(filePath));
  } catch (e) {
    if (verbose) {
      stderr.writeln(e);
    }
    return null;
  }
}
