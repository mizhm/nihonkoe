import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/logic/i18n.dart';

void main() {
  test('resolveLanguage follows the device unless the user picked one', () {
    expect(resolveLanguage(LanguagePref.system, 'vi'), 'vi');
    expect(resolveLanguage(LanguagePref.system, 'ja'), 'ja');
    expect(resolveLanguage(LanguagePref.system, 'fr'), 'en');
    expect(resolveLanguage(LanguagePref.ja, 'vi'), 'ja');
  });
}
