import 'package:flutter/material.dart';

import 'package:duitku/core/utils/json_utils.dart';

class AppSettings {
  const AppSettings({
    this.userName = '',
    this.profilePhotoBase64,
    this.currencyCode = 'IDR',
    this.themeMode = ThemeMode.system,
    this.onboardingCompleted = false,
    this.allowNegativeBalance = false,
    this.pinHash,
    this.pinSalt,
    this.biometricEnabled = false,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.payday = 1,
    this.allocationEnabled = false,
    this.allocationNeedsPercent = 50,
    this.allocationWantsPercent = 30,
    this.allocationSavingsPercent = 20,
    this.allocationNeedsCategoryId,
    this.allocationWantsCategoryId,
    this.allocationSavingsCategoryId,
  });

  final String userName;

  /// Base64-encoded JPEG thumbnail (resized/compressed by the picker before
  /// encoding), so it stays small enough to live inline in the settings
  /// JSON blob alongside everything else.
  final String? profilePhotoBase64;

  final String currencyCode;
  final ThemeMode themeMode;
  final bool onboardingCompleted;
  final bool allowNegativeBalance;

  /// Salted SHA-256 digest of the PIN. The raw PIN is never persisted.
  final String? pinHash;
  final String? pinSalt;
  final bool biometricEnabled;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  /// Day of the month (1-31) salary usually arrives. Defines the "month"
  /// cycle used everywhere (Dashboard, Laporan, Budget, filters) instead of
  /// the calendar month. Default 1 keeps calendar-month behavior.
  final int payday;

  final bool allocationEnabled;
  final double allocationNeedsPercent;
  final double allocationWantsPercent;
  final double allocationSavingsPercent;
  final String? allocationNeedsCategoryId;
  final String? allocationWantsCategoryId;
  final String? allocationSavingsCategoryId;

  bool get pinEnabled => pinHash != null && pinSalt != null;

  AppSettings copyWith({
    String? userName,
    Object? profilePhotoBase64 = _unset,
    String? currencyCode,
    ThemeMode? themeMode,
    bool? onboardingCompleted,
    bool? allowNegativeBalance,
    Object? pinHash = _unset,
    Object? pinSalt = _unset,
    bool? biometricEnabled,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? payday,
    bool? allocationEnabled,
    double? allocationNeedsPercent,
    double? allocationWantsPercent,
    double? allocationSavingsPercent,
    Object? allocationNeedsCategoryId = _unset,
    Object? allocationWantsCategoryId = _unset,
    Object? allocationSavingsCategoryId = _unset,
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
      profilePhotoBase64: profilePhotoBase64 == _unset
          ? this.profilePhotoBase64
          : profilePhotoBase64 as String?,
      currencyCode: currencyCode ?? this.currencyCode,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      allowNegativeBalance: allowNegativeBalance ?? this.allowNegativeBalance,
      pinHash: pinHash == _unset ? this.pinHash : pinHash as String?,
      pinSalt: pinSalt == _unset ? this.pinSalt : pinSalt as String?,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      payday: (payday ?? this.payday).clamp(1, 31),
      allocationEnabled: allocationEnabled ?? this.allocationEnabled,
      allocationNeedsPercent:
          allocationNeedsPercent ?? this.allocationNeedsPercent,
      allocationWantsPercent:
          allocationWantsPercent ?? this.allocationWantsPercent,
      allocationSavingsPercent:
          allocationSavingsPercent ?? this.allocationSavingsPercent,
      allocationNeedsCategoryId: allocationNeedsCategoryId == _unset
          ? this.allocationNeedsCategoryId
          : allocationNeedsCategoryId as String?,
      allocationWantsCategoryId: allocationWantsCategoryId == _unset
          ? this.allocationWantsCategoryId
          : allocationWantsCategoryId as String?,
      allocationSavingsCategoryId: allocationSavingsCategoryId == _unset
          ? this.allocationSavingsCategoryId
          : allocationSavingsCategoryId as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'profilePhotoBase64': profilePhotoBase64,
        'currencyCode': currencyCode,
        'themeMode': themeMode.name,
        'onboardingCompleted': onboardingCompleted,
        'allowNegativeBalance': allowNegativeBalance,
        'pinHash': pinHash,
        'pinSalt': pinSalt,
        'biometricEnabled': biometricEnabled,
        'reminderEnabled': reminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'payday': payday,
        'allocationEnabled': allocationEnabled,
        'allocationNeedsPercent': allocationNeedsPercent,
        'allocationWantsPercent': allocationWantsPercent,
        'allocationSavingsPercent': allocationSavingsPercent,
        'allocationNeedsCategoryId': allocationNeedsCategoryId,
        'allocationWantsCategoryId': allocationWantsCategoryId,
        'allocationSavingsCategoryId': allocationSavingsCategoryId,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        userName: readString(json, 'userName', fallback: ''),
        profilePhotoBase64: readNullableString(json, 'profilePhotoBase64'),
        currencyCode: readString(json, 'currencyCode', fallback: 'IDR'),
        themeMode: readEnum(json, 'themeMode', ThemeMode.values, ThemeMode.system),
        onboardingCompleted: readBool(json, 'onboardingCompleted'),
        allowNegativeBalance: readBool(json, 'allowNegativeBalance'),
        pinHash: readNullableString(json, 'pinHash'),
        pinSalt: readNullableString(json, 'pinSalt'),
        biometricEnabled: readBool(json, 'biometricEnabled'),
        reminderEnabled: readBool(json, 'reminderEnabled'),
        reminderHour: readInt(json, 'reminderHour', fallback: 20),
        reminderMinute: readInt(json, 'reminderMinute'),
        payday: readInt(json, 'payday', fallback: 1).clamp(1, 31),
        allocationEnabled: readBool(json, 'allocationEnabled'),
        allocationNeedsPercent:
            readDouble(json, 'allocationNeedsPercent', fallback: 50),
        allocationWantsPercent:
            readDouble(json, 'allocationWantsPercent', fallback: 30),
        allocationSavingsPercent:
            readDouble(json, 'allocationSavingsPercent', fallback: 20),
        allocationNeedsCategoryId:
            readNullableString(json, 'allocationNeedsCategoryId'),
        allocationWantsCategoryId:
            readNullableString(json, 'allocationWantsCategoryId'),
        allocationSavingsCategoryId:
            readNullableString(json, 'allocationSavingsCategoryId'),
      );
}

const Object _unset = Object();
