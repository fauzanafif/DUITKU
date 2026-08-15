import 'package:flutter/material.dart';

import 'package:duitku/core/utils/json_utils.dart';

class AppSettings {
  const AppSettings({
    this.userName = '',
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
  });

  final String userName;
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

  bool get pinEnabled => pinHash != null && pinSalt != null;

  AppSettings copyWith({
    String? userName,
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
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'userName': userName,
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
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        userName: readString(json, 'userName', fallback: ''),
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
      );
}

const Object _unset = Object();
