import 'package:flutter_test/flutter_test.dart';

class TestBootstrap {
  static void init() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }
}
