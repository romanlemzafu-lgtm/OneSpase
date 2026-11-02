import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/account_slot.dart';

class AccountVault {
  static const _slotsKey = 'onespase_account_slots_v1';
  static const _tokenPrefix = 'onespase_refresh_';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<AccountSlot>> loadSlots() async {
    final raw = await _storage.read(key: _slotsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => AccountSlot.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .where((slot) => slot.userId.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAccount({
    required AccountSlot slot,
    required String refreshToken,
  }) async {
    final existing = [...await loadSlots()];
    existing.removeWhere((item) => item.userId == slot.userId);
    existing.insert(0, slot);
    await _storage.write(
      key: _slotsKey,
      value: jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
    await _storage.write(
      key: '$_tokenPrefix${slot.userId}',
      value: refreshToken,
    );
  }

  Future<String?> refreshTokenFor(String userId) =>
      _storage.read(key: '$_tokenPrefix$userId');

  Future<void> removeAccount(String userId) async {
    final existing = [...await loadSlots()]
      ..removeWhere((item) => item.userId == userId);
    await _storage.write(
      key: _slotsKey,
      value: jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
    await _storage.delete(key: '$_tokenPrefix$userId');
  }
}
