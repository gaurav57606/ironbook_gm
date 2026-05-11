import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../test_helper.dart';
import '../helpers/mock_factory.dart';

class TestBootstrap {
  static void init() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Register common fallbacks
    try {
      registerFallbackValue(Duration.zero);
      registerFallbackValue(const Offset(0, 0));
      MockFactory.registerFallbacks();
    } catch (_) {}
  }
  
  static Future<void> setupFullEnvironment() async {
    init();
    await TestHelper.setupHive();
  }
}
