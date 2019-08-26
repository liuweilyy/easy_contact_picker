import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_contact_picker/easy_contact_picker.dart';

void main() {
  const MethodChannel channel = MethodChannel('plugins.flutter.io/easy_contact_picker');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

}
