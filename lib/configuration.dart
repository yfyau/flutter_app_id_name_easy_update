import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_application_id/custom_exceptions.dart';
import 'package:yaml/yaml.dart';

class PlatformConfiguration extends Equatable {
  const PlatformConfiguration({
    this.id,
    this.name,
  });

  static PlatformConfiguration? fromYamlMap(dynamic map) {
    if (map == null) {
      return null;
    }
    if (map is! YamlMap) {
      throw InvalidFormatException();
    }
    return PlatformConfiguration(id: map[_ID_KEY], name: map[_NAME_KEY]);
  }

  static const String _ID_KEY = 'id';
  static const String _NAME_KEY = 'name';

  final String? id;
  final String? name;

  @override
  List<Object?> get props => [id, name];
}

class Configuration extends Equatable {
  const Configuration({
    this.android,
    this.ios,
  });

  static const String _FLUTTER_APPLICATION_ID_KEY = 'flutter_application_id';
  static const String _IOS_KEY = 'ios';
  static const String _ANDROID_KEY = 'android';
  final PlatformConfiguration? android;
  final PlatformConfiguration? ios;

  static YamlMap _loadYaml(String data) {
    try {
      final dynamic loadedObject = loadYaml(data);

      if (loadedObject is! YamlMap) throw InvalidFormatException();

      return loadedObject;
    } catch (e) {
      throw InvalidFormatException();
    }
  }

  static Configuration fromString(String data) {
    final yamlMap = _loadYaml(data);

    if (!yamlMap.containsKey(_FLUTTER_APPLICATION_ID_KEY) ||
        !(yamlMap[_FLUTTER_APPLICATION_ID_KEY] is YamlMap)) {
      throw NoConfigFoundException();
    }
    return Configuration(
        android: PlatformConfiguration.fromYamlMap(
            yamlMap[_FLUTTER_APPLICATION_ID_KEY][_ANDROID_KEY]),
        ios: PlatformConfiguration.fromYamlMap(
            yamlMap[_FLUTTER_APPLICATION_ID_KEY][_IOS_KEY]));
  }

  static Future<Configuration> fromFile(File file) async {
    return Configuration.fromString(await file.readAsString());
  }

  @override
  List<Object?> get props => [android, ios];
}
