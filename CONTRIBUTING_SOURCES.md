# Contributing a BLE Signal Source

BodyPress ships an **extensible plugin system** for BLE signal hardware.
Adding a new source requires **one Dart file + one registration line** — no changes to the framework, database, or UI code.

> **First source:** `Ads1299Source` (TI ADS1299 8-Ch EEG, EAREEG boards).
> Use it as a working reference throughout this guide.

---

## Table of Contents

1. [Architecture overview](#architecture-overview)
2. [Step-by-step guide](#step-by-step-guide)
3. [The `BleSourceProvider` interface](#the-blesourceprovider-interface)
4. [Starter template](#starter-template)
5. [Parsing BLE notifications](#parsing-ble-notifications)
6. [Lifecycle hooks](#lifecycle-hooks)
7. [Registration](#registration)
8. [Testing your source](#testing-your-source)
9. [PR checklist](#pr-checklist)

---

## Architecture overview

```
┌─────────────────────────┐
│   SourceBrowserScreen   │  Lists all registered sources
└──────────┬──────────────┘
           │ tap
┌──────────▼──────────────┐
│   LiveSignalScreen      │  Scan → Pick → Connect → Stream
└──────────┬──────────────┘
           │ delegates to
┌──────────▼──────────────┐
│   BleSourceService      │  Generic scan/connect/notify engine
└──────────┬──────────────┘
           │ calls provider.parseNotification()
┌──────────▼──────────────┐
│   BleSourceProvider     │  YOUR CODE — parse bytes → SignalSample
└─────────────────────────┘
```

**Key files:**

| File                                                      | Purpose                                                                                                                               |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/core/services/ble_source_provider.dart`              | Core abstractions: `BleSourceProvider`, `BleSourceRegistry`, `BleSourceService`, `SignalSample`, `ChannelDescriptor`, `SignalSession` |
| `lib/core/services/sources/ads1299_source.dart`           | Reference implementation — ADS1299 8-Ch EEG                                                                                           |
| `lib/core/services/sources/source_registry_init.dart`     | One-stop registration — add your source here                                                                                          |
| `lib/core/widgets/live_signal_chart.dart`                 | Multi-channel real-time waveform widget (auto-adapts to any channel count)                                                            |
| `lib/features/sources/screens/source_browser_screen.dart` | Source browser UI                                                                                                                     |
| `lib/features/sources/screens/live_signal_screen.dart`    | Live scan + stream UI                                                                                                                 |

---

## Step-by-step guide

### 1. Create your source file

```
lib/core/services/sources/my_device_source.dart
```

### 2. Implement `BleSourceProvider`

Fill in **identity**, **BLE UUIDs**, **channel layout**, and **parsing** (see [interface reference](#the-blesourceprovider-interface) and [template](#starter-template) below).

### 3. Register it

Open `lib/core/services/sources/source_registry_init.dart`:

```dart
import 'my_device_source.dart';

void registerAllSources(BleSourceRegistry registry) {
  registry.register(Ads1299Source());
  registry.register(MyDeviceSource());   // ← add this
}
```

### 4. Run & test

```bash
flutter run          # hot-reload picks up the new source instantly
flutter analyze      # must stay at 0 errors / 0 warnings
```

Your source will appear in the **Source Browser** (`/sources`) and the full scan → connect → stream flow works out of the box.

---

## The `BleSourceProvider` interface

Every source **must** override these members:

### Identity

| Member            | Type           | Example                                                                                            |
| ----------------- | -------------- | -------------------------------------------------------------------------------------------------- |
| `id`              | `String`       | `'ads1299'` — unique machine key                                                                   |
| `displayName`     | `String`       | `'ADS1299 8-Ch EEG'`                                                                               |
| `description`     | `String`       | One-liner for the source browser card                                                              |
| `icon`            | `IconData`     | `Icons.psychology_alt`                                                                             |
| `advertisedNames` | `List<String>` | `['EAREEG']` — matched case-insensitively. Empty list = match any device exposing the service UUID |

### BLE identifiers

| Member                     | Type     | Example                                                        |
| -------------------------- | -------- | -------------------------------------------------------------- |
| `serviceUuid`              | `String` | `'0000fe42-8e22-4541-9d4c-21edae82ed19'`                       |
| `notifyCharacteristicUuid` | `String` | Same UUID on single-characteristic designs, or a different one |

### Channel layout

| Member               | Type                      | Example                               |
| -------------------- | ------------------------- | ------------------------------------- |
| `channelDescriptors` | `List<ChannelDescriptor>` | 8 descriptors with label, unit, scale |
| `sampleRateHz`       | `double`                  | `250`                                 |

Each `ChannelDescriptor` has:

```dart
ChannelDescriptor(
  label: 'Fp1',        // display label
  unit: 'µV',          // axis unit
  defaultScale: 100,   // ±range for autoscale (null = auto-detect)
)
```

### Data parsing

| Member              | Signature                                         | Notes                                                                        |
| ------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------- |
| `parseNotification` | `SignalSample? parseNotification(List<int> data)` | Return `null` for malformed data. Must return exactly `channelCount` values. |

### Lifecycle hooks (optional)

| Member                          | When called                              | Use case                   |
| ------------------------------- | ---------------------------------------- | -------------------------- |
| `onConnected(device, services)` | After GATT discovery, before subscribing | Send start/config commands |
| `onDisconnecting(device)`       | Before disconnect                        | Send stop commands         |

---

## Starter template

Copy this skeleton and fill in the `TODO` sections:

```dart
import 'package:flutter/material.dart';
import '../ble_source_provider.dart';

class MyDeviceSource extends BleSourceProvider {
  // ── Identity ──────────────────────────────────────────────────────
  @override
  String get id => 'my_device';                   // TODO: unique id

  @override
  String get displayName => 'My Device Name';      // TODO: display name

  @override
  String get description => 'Short description.';  // TODO: description

  @override
  IconData get icon => Icons.sensors;              // TODO: pick an icon

  @override
  List<String> get advertisedNames => ['MYDEV'];   // TODO: BLE advertised names

  // ── BLE identifiers ──────────────────────────────────────────────
  @override
  String get serviceUuid => 'TODO-SERVICE-UUID';

  @override
  String get notifyCharacteristicUuid => 'TODO-NOTIFY-UUID';

  // ── Channel layout ───────────────────────────────────────────────
  @override
  List<ChannelDescriptor> get channelDescriptors => [
    // TODO: one descriptor per channel
    ChannelDescriptor(label: 'Ch 1', unit: 'µV', defaultScale: 100),
    ChannelDescriptor(label: 'Ch 2', unit: 'µV', defaultScale: 100),
  ];

  @override
  double get sampleRateHz => 250; // TODO: actual sample rate

  // ── Data parsing ─────────────────────────────────────────────────
  @override
  SignalSample? parseNotification(List<int> data) {
    // TODO: Parse the raw BLE bytes into channel values.
    //
    // Tips:
    // - Check data.length first, return null if too short
    // - Read bytes in the order your hardware sends them
    // - Convert to physical units (µV, mV, etc.)
    // - Return a SignalSample with exactly channelCount values
    //
    // Example for 2-channel, 16-bit little-endian:
    if (data.length < 4) return null;

    final ch1 = (data[1] << 8 | data[0]).toSigned(16).toDouble();
    final ch2 = (data[3] << 8 | data[2]).toSigned(16).toDouble();

    return SignalSample(
      time: DateTime.now(),
      channels: [ch1, ch2],
    );
  }
}
```

---

## Parsing BLE notifications

### Common byte layouts

**24-bit big-endian two's complement** (ADS1299):

```dart
int raw = (data[offset] << 16) | (data[offset + 1] << 8) | data[offset + 2];
if (raw >= 0x800000) raw -= 0x1000000; // sign extension
double uv = 1000000.0 * vRef * (raw / 16777215);
```

**16-bit little-endian signed** (many IMU / PPG boards):

```dart
int raw = (data[offset + 1] << 8) | data[offset];
double value = raw.toSigned(16).toDouble();
```

**12-bit packed** (some ADCs):

```dart
int raw = ((data[offset] & 0x0F) << 8) | data[offset + 1];
if (raw >= 0x800) raw -= 0x1000;
```

### Tips

- Always validate `data.length` before indexing.
- If notifications can carry multiple samples per packet, emit them in a loop.
- Round to reasonable precision: `double.parse(value.toStringAsFixed(2))`.
- The `SignalSample.time` should normally be `DateTime.now()` — the system timestamps on reception. If the device includes a sequence counter, you can reconstruct hardware-precise times.

---

## Lifecycle hooks

Some devices need a BLE write command to start streaming. Override `onConnected`:

```dart
@override
Future<void> onConnected(
  BluetoothDevice device,
  List<BluetoothService> services,
) async {
  // Find the write characteristic
  final svc = services.firstWhere(
    (s) => s.uuid.str128.toLowerCase() == serviceUuid.toLowerCase(),
  );
  final writeChar = svc.characteristics.firstWhere(
    (c) => c.uuid.str128.toLowerCase() == _writeUuid.toLowerCase(),
  );

  // Send a "start streaming" command
  await writeChar.write([0x01], withoutResponse: true);
}
```

Similarly `onDisconnecting` for a "stop streaming" command.

---

## Registration

The file `source_registry_init.dart` is the **single entry point** where all sources are wired in:

```dart
import '../ble_source_provider.dart';
import 'ads1299_source.dart';
import 'my_device_source.dart';

void registerAllSources(BleSourceRegistry registry) {
  registry.register(Ads1299Source());
  registry.register(MyDeviceSource());
}
```

This function runs once at startup via the Riverpod `bleSourceRegistryProvider`.
No other file needs changes — the **Source Browser**, **Live Signal** screen, and **`SignalSession`** persistence all work generically with any registered provider.

---

## Testing your source

### Unit-test `parseNotification`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bodypress_flutter/core/services/sources/my_device_source.dart';

void main() {
  final source = MyDeviceSource();

  test('parses valid notification', () {
    final data = [0x00, 0x80, 0xFF, 0x7F]; // example bytes
    final sample = source.parseNotification(data);
    expect(sample, isNotNull);
    expect(sample!.channels.length, source.channelCount);
  });

  test('returns null for short data', () {
    expect(source.parseNotification([0x01]), isNull);
  });

  test('channel descriptors match expected count', () {
    expect(source.channelDescriptors.length, source.channelCount);
  });
}
```

### Integration testing on device

1. Install on a physical Android/iOS device (BLE is not available on emulators).
2. Open **Source Browser** → tap your source → scan → pick device → connect.
3. Verify:
   - All channels display in the live chart
   - Values are in the expected physical range
   - Disconnecting cleanly returns to idle state
   - Recording captures samples and stores a `SignalSession`

### BLE emulator option

For development without hardware, consider [ble_peripheral](https://pub.dev/packages/ble_peripheral) or [nRF Connect](https://www.nordicsemi.com/Products/Development-tools/nRF-Connect-for-mobile) on a second phone to broadcast synthetic notifications.

---

## PR checklist

Before submitting your pull request:

- [ ] Source file created in `lib/core/services/sources/`
- [ ] Extends `BleSourceProvider` with all required overrides
- [ ] Registered in `source_registry_init.dart`
- [ ] `flutter analyze` reports 0 errors / 0 warnings on your files
- [ ] `parseNotification` handles malformed/short data gracefully (returns `null`)
- [ ] Channel count in `channelDescriptors` matches `parseNotification` output
- [ ] Unit tests for `parseNotification` (valid data + edge cases)
- [ ] Tested on real hardware (or documented BLE emulator setup)
- [ ] Header doc-comment on the class with protocol summary (BLE UUIDs, byte format, voltage formula)
- [ ] No unrelated changes

---

## Questions?

Open an issue or discussion on the repository — we'll help you get your source working.

Happy hacking! 🧠⚡
