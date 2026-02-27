import 'package:shared_preferences/shared_preferences.dart';

const String _onboardingPrefKey = 'has_seen_onboarding';

Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_onboardingPrefKey) ?? false);
}

Future<void> markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingPrefKey, true);
}
