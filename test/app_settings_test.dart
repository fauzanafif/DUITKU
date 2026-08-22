import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/data/models/app_settings.dart';

void main() {
  test('profilePhotoBase64 survives a JSON round-trip', () {
    const settings = AppSettings(
      userName: 'Budi',
      profilePhotoBase64: 'ZmFrZS1pbWFnZS1ieXRlcw==',
    );

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.profilePhotoBase64, 'ZmFrZS1pbWFnZS1ieXRlcw==');
    expect(restored.userName, 'Budi');
  });

  test('profilePhotoBase64 defaults to null when absent', () {
    final restored = AppSettings.fromJson(const {'userName': 'Budi'});
    expect(restored.profilePhotoBase64, isNull);
  });

  test('copyWith(profilePhotoBase64: null) clears an existing photo', () {
    const withPhoto = AppSettings(profilePhotoBase64: 'abc123');
    final cleared = withPhoto.copyWith(profilePhotoBase64: null);
    expect(cleared.profilePhotoBase64, isNull);
  });

  test('copyWith without touching profilePhotoBase64 keeps the existing value',
      () {
    const withPhoto = AppSettings(profilePhotoBase64: 'abc123');
    final updated = withPhoto.copyWith(userName: 'Baru');
    expect(updated.profilePhotoBase64, 'abc123');
    expect(updated.userName, 'Baru');
  });
}
