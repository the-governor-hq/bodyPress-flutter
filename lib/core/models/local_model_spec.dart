/// Specification and registry for downloadable on-device LLM models.
///
/// Each [LocalModelSpec] describes a quantised model that the app knows how
/// to download, verify, and run. The [LocalModelRegistry] collects all
/// validated models and is surfaced in the debug panel for selection.
library;

/// Immutable descriptor for one downloadable on-device model.
class LocalModelSpec {
  /// Machine identifier (e.g. `"smollm2-360m-instruct-q8_0"`).
  final String id;

  /// Human-friendly label (e.g. `"SmolLM2 360M (Q8)"`).
  final String displayName;

  /// Model family (e.g. `"smollm2"`, `"gemma"`, `"phi"`).
  final String family;

  /// Quantization level (e.g. `"Q4_0"`, `"Q4_K_M"`, `"Q8_0"`).
  final String quantization;

  /// Expected file size on disk in bytes.
  final int fileSizeBytes;

  /// Minimum recommended device RAM in bytes to load this model.
  final int minRamBytes;

  /// CDN or direct-download URL for the model file.
  ///
  /// Empty while CDN provisioning is pending — checked at download time.
  final String downloadUrl;

  /// SHA-256 hex digest of the model file for integrity verification.
  ///
  /// Empty while download validation is pending.
  final String sha256;

  /// File format: `"gguf"`, `"onnx"`, `"tflite"`, etc.
  final String format;

  const LocalModelSpec({
    required this.id,
    required this.displayName,
    required this.family,
    required this.quantization,
    required this.fileSizeBytes,
    required this.minRamBytes,
    required this.downloadUrl,
    required this.sha256,
    this.format = 'gguf',
  });

  /// Human-readable file size (e.g. `"1.4 GB"`, `"386 MB"`).
  String get fileSizeDisplay {
    const gb = 1024 * 1024 * 1024;
    const mb = 1024 * 1024;
    if (fileSizeBytes >= gb) {
      return '${(fileSizeBytes / gb).toStringAsFixed(1)} GB';
    }
    return '${(fileSizeBytes / mb).toStringAsFixed(0)} MB';
  }

  /// Human-readable minimum RAM (e.g. `"4 GB"`).
  String get minRamDisplay {
    const gb = 1024 * 1024 * 1024;
    return '${(minRamBytes / gb).toStringAsFixed(0)} GB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LocalModelSpec && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LocalModelSpec($id, $fileSizeDisplay)';
}

/// Registry of validated on-device models, ordered by file size.
///
/// Add new models here **after** testing on target hardware. Each entry
/// should include real SHA-256 hashes and CDN URLs once provisioned.
abstract class LocalModelRegistry {
  LocalModelRegistry._();

  // ── Tier 1: Tiny — low-RAM devices (≤ 4 GB RAM, budget phones) ──────────

  static const smolLM2_360m = LocalModelSpec(
    id: 'smollm2-360m-instruct-q8_0',
    displayName: 'SmolLM2 360M Instruct (Q8)',
    family: 'smollm2',
    quantization: 'Q8_0',
    fileSizeBytes: 386 * 1024 * 1024, // ~386 MB
    minRamBytes: 2 * 1024 * 1024 * 1024, // 2 GB
    downloadUrl: '', // TODO(cdn): set when CDN is provisioned
    sha256: '', // TODO(cdn): compute after download validation
    format: 'gguf',
  );

  // ── Tier 2: Small — mainstream devices (4–6 GB RAM) ─────────────────────

  static const gemma2b_q4 = LocalModelSpec(
    id: 'gemma-2b-it-q4_0',
    displayName: 'Gemma 2B Instruct (Q4)',
    family: 'gemma',
    quantization: 'Q4_0',
    fileSizeBytes: 1395 * 1024 * 1024, // ~1.4 GB
    minRamBytes: 4 * 1024 * 1024 * 1024, // 4 GB
    downloadUrl: '',
    sha256: '',
    format: 'gguf',
  );

  static const phi3Mini_q4 = LocalModelSpec(
    id: 'phi-3-mini-4k-instruct-q4_K_M',
    displayName: 'Phi-3 Mini 4K (Q4_K_M)',
    family: 'phi',
    quantization: 'Q4_K_M',
    fileSizeBytes: 2300 * 1024 * 1024, // ~2.3 GB
    minRamBytes: 4 * 1024 * 1024 * 1024,
    downloadUrl: '',
    sha256: '',
    format: 'gguf',
  );

  // ── Tier 3: Medium — flagship devices (8+ GB RAM) ──────────────────────

  static const gemma7b_q4 = LocalModelSpec(
    id: 'gemma-7b-it-q4_K_M',
    displayName: 'Gemma 7B Instruct (Q4_K_M)',
    family: 'gemma',
    quantization: 'Q4_K_M',
    fileSizeBytes: 4500 * 1024 * 1024, // ~4.5 GB
    minRamBytes: 8 * 1024 * 1024 * 1024, // 8 GB
    downloadUrl: '',
    sha256: '',
    format: 'gguf',
  );

  /// All known models, ordered by file size ascending (smallest first).
  static const List<LocalModelSpec> all = [
    smolLM2_360m,
    gemma2b_q4,
    phi3Mini_q4,
    gemma7b_q4,
  ];

  /// Recommended default model for first-time users (smallest viable model).
  static const defaultModel = smolLM2_360m;

  /// Find a model by [id], or `null` if not in the registry.
  static LocalModelSpec? byId(String id) {
    for (final model in all) {
      if (model.id == id) return model;
    }
    return null;
  }
}
