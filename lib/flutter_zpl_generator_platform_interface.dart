import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_zpl_generator_method_channel.dart';

abstract class FlutterZplGeneratorPlatform extends PlatformInterface {
  /// Constructs a FlutterZplGeneratorPlatform.
  FlutterZplGeneratorPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterZplGeneratorPlatform _instance = MethodChannelFlutterZplGenerator();

  /// The default instance of [FlutterZplGeneratorPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterZplGenerator].
  static FlutterZplGeneratorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterZplGeneratorPlatform] when
  /// they register themselves.
  static set instance(FlutterZplGeneratorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
