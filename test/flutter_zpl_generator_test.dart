import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator_platform_interface.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterZplGeneratorPlatform
    with MockPlatformInterfaceMixin
    implements FlutterZplGeneratorPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterZplGeneratorPlatform initialPlatform = FlutterZplGeneratorPlatform.instance;

  test('$MethodChannelFlutterZplGenerator is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterZplGenerator>());
  });

  test('getPlatformVersion', () async {
    FlutterZplGenerator flutterZplGeneratorPlugin = FlutterZplGenerator();
    MockFlutterZplGeneratorPlatform fakePlatform = MockFlutterZplGeneratorPlatform();
    FlutterZplGeneratorPlatform.instance = fakePlatform;

    expect(await flutterZplGeneratorPlugin.getPlatformVersion(), '42');
  });
}
