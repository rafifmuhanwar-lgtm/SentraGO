import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kunci SharedPreferences
class SettingsKeys {
  static const notifyNewOrder = 'notify_new_order';
  static const notifyChat = 'notify_chat';
  static const notifyPromo = 'notify_promo';
  static const vibrateOnOrder = 'vibrate_on_order';
  static const showOnlineStatus = 'show_online_status';
  static const saveBatteryMode = 'save_battery_mode';
}

/// Model settings yang bisa diubah
class AppSettings {
  final bool notifyNewOrder;
  final bool notifyChat;
  final bool notifyPromo;
  final bool vibrateOnOrder;
  final bool showOnlineStatus;
  final bool saveBatteryMode;

  const AppSettings({
    this.notifyNewOrder = true,
    this.notifyChat = true,
    this.notifyPromo = false,
    this.vibrateOnOrder = true,
    this.showOnlineStatus = true,
    this.saveBatteryMode = false,
  });

  AppSettings copyWith({
    bool? notifyNewOrder,
    bool? notifyChat,
    bool? notifyPromo,
    bool? vibrateOnOrder,
    bool? showOnlineStatus,
    bool? saveBatteryMode,
  }) {
    return AppSettings(
      notifyNewOrder: notifyNewOrder ?? this.notifyNewOrder,
      notifyChat: notifyChat ?? this.notifyChat,
      notifyPromo: notifyPromo ?? this.notifyPromo,
      vibrateOnOrder: vibrateOnOrder ?? this.vibrateOnOrder,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      saveBatteryMode: saveBatteryMode ?? this.saveBatteryMode,
    );
  }
}

/// Service untuk baca/tulis settings ke SharedPreferences
class SettingsService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AppSettings load() {
    return AppSettings(
      notifyNewOrder: _prefs.getBool(SettingsKeys.notifyNewOrder) ?? true,
      notifyChat: _prefs.getBool(SettingsKeys.notifyChat) ?? true,
      notifyPromo: _prefs.getBool(SettingsKeys.notifyPromo) ?? false,
      vibrateOnOrder: _prefs.getBool(SettingsKeys.vibrateOnOrder) ?? true,
      showOnlineStatus: _prefs.getBool(SettingsKeys.showOnlineStatus) ?? true,
      saveBatteryMode: _prefs.getBool(SettingsKeys.saveBatteryMode) ?? false,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setBool(SettingsKeys.notifyNewOrder, settings.notifyNewOrder);
    await _prefs.setBool(SettingsKeys.notifyChat, settings.notifyChat);
    await _prefs.setBool(SettingsKeys.notifyPromo, settings.notifyPromo);
    await _prefs.setBool(SettingsKeys.vibrateOnOrder, settings.vibrateOnOrder);
    await _prefs.setBool(SettingsKeys.showOnlineStatus, settings.showOnlineStatus);
    await _prefs.setBool(SettingsKeys.saveBatteryMode, settings.saveBatteryMode);
  }
}

/// Riverpod: settingsService init
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final service = SettingsService();
  // Init dipanggil di main.dart setelah runApp
  return service;
});

/// Riverpod: state settings (auto-init + persist)
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    // Load dari SharedPreferences — init sudah dipanggil di main
    final service = ref.read(settingsServiceProvider);
    return service.load();
  }

  Future<void> update(AppSettings newSettings) async {
    state = newSettings;
    final service = ref.read(settingsServiceProvider);
    await service.save(newSettings);
  }

  Future<void> setVibrateOnOrder(bool value) async {
    await update(state.copyWith(vibrateOnOrder: value));
  }

  Future<void> setNotifyNewOrder(bool value) async {
    await update(state.copyWith(notifyNewOrder: value));
  }

  Future<void> setNotifyChat(bool value) async {
    await update(state.copyWith(notifyChat: value));
  }

  Future<void> setNotifyPromo(bool value) async {
    await update(state.copyWith(notifyPromo: value));
  }

  Future<void> setShowOnlineStatus(bool value) async {
    await update(state.copyWith(showOnlineStatus: value));
  }

  Future<void> setSaveBatteryMode(bool value) async {
    await update(state.copyWith(saveBatteryMode: value));
  }
}
