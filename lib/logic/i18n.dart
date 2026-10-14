enum LanguagePref { system, vi, en, ja }

const supportedLanguages = ['vi', 'en', 'ja'];

String resolveLanguage(LanguagePref pref, String deviceLanguage) {
  if (pref != LanguagePref.system) return pref.name;
  final code = deviceLanguage.toLowerCase().split(RegExp('[-_]')).first;
  return supportedLanguages.contains(code) ? code : 'en';
}
