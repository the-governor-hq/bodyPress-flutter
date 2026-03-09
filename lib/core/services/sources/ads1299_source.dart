import 'package:flutter/material.dart';

import '../ble_source_provider.dart';

/// ADS1299 8-channel EEG source provider.
///
/// Supports devices like the EAREEG board that use the TI ADS1299 ADC
/// and stream 8 channels of 24-bit EEG data over BLE.
///
/// ### Protocol
/// - BLE service UUID: `0000fe42-8e22-4541-9d4c-21edae82ed19`
/// - Notification characteristic: same UUID (single-characteristic design)
/// - Each notification: 24 bytes → 8 channels × 3 bytes (big-endian, 24-bit
///   two's complement)
/// - Voltage formula: `µV = 1_000_000 × 4.5 × (raw_signed / 16_777_215)`
///
/// ### Adding your own source
/// Copy this file, change the [id], UUIDs, channel layout, and
/// [parseNotification] logic. Register in `source_registry_init.dart`.
class Ads1299Source extends BleSourceProvider {
  // ── Identity ────────────────────────────────────────────────────────

  @override
  String get id => 'ads1299';

  @override
  String get displayName => 'ADS1299 8-Ch EEG';

  @override
  String get description =>
      'TI ADS1299 EEG front-end — 8 channels, 24-bit, 250 SPS. '
      'Compatible with EAREEG and similar open-hardware boards.';

  @override
  IconData get icon => Icons.psychology_alt;

  @override
  List<String> get advertisedNames => ['EAREEG'];

  // ── BLE identifiers ────────────────────────────────────────────────

  @override
  String get serviceUuid => '0000fe42-8e22-4541-9d4c-21edae82ed19';

  @override
  String get notifyCharacteristicUuid => '0000fe42-8e22-4541-9d4c-21edae82ed19';

  // ── Channel layout ─────────────────────────────────────────────────

  /// Standard 10-20 electrode labels for an 8-channel montage.
  /// Adjust if your board uses a different montage.
  static const _labels = ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'];

  @override
  List<ChannelDescriptor> get channelDescriptors => List.generate(
    8,
    (i) => ChannelDescriptor(
      label: _labels[i],
      unit: 'µV',
      defaultScale: 100, // ±100 µV autoscale window
    ),
  );

  @override
  double get sampleRateHz => 250;

  // ── Data parsing ───────────────────────────────────────────────────

  /// Reference voltage (V) of the ADS1299.
  static const double _vRef = 4.5;

  /// Full-scale positive value for 24-bit ADC.
  static const int _fullScale = 16777215; // 2^24 - 1

  /// Midpoint for unsigned→signed conversion (bit 23 set).
  static const int _signBit = 0x800000; // 2^23

  @override
  SignalSample? parseNotification(List<int> data) {
    // Each notification must contain at least 8 × 3 = 24 bytes.
    if (data.length < 24) return null;

    final channels = <double>[];
    for (var i = 0; i < 8; i++) {
      final offset = i * 3;
      // Big-endian 24-bit unsigned assembly.
      int raw =
          (data[offset] << 16) | (data[offset + 1] << 8) | data[offset + 2];

      // Two's complement sign extension to signed 24-bit.
      if (raw >= _signBit) {
        raw -= _fullScale + 1; // 2^24
      }

      // Convert to microvolts.
      final uv = 1000000.0 * _vRef * (raw / _fullScale);
      channels.add(double.parse(uv.toStringAsFixed(2)));
    }

    return SignalSample(time: DateTime.now(), channels: channels);
  }
}
