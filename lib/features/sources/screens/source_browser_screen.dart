import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/ble_source_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/app_theme.dart';

/// Browse all registered BLE signal sources and launch a live session.
///
/// Each source is rendered as a card showing its name, description, channel
/// count, and icon. Tapping a card navigates to the live signal screen
/// which handles scan → connect → stream.
class SourceBrowserScreen extends ConsumerWidget {
  const SourceBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(bleSourceRegistryProvider);
    final sources = registry.providers;

    return Scaffold(
      backgroundColor: AppTheme.midnight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Signal Sources',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.moonbeam,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.moonbeam,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: sources.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: sources.length + 1, // +1 for the "add your own" card
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index < sources.length) {
                  return _SourceCard(source: sources[index]);
                }
                return _buildContributeCard(context);
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sensors_off_rounded,
            size: 48,
            color: AppTheme.fog.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No sources registered',
            style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.fog),
          ),
          const SizedBox(height: 8),
          Text(
            'Community sources will appear here.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.fog.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.deepSea.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.aurora.withValues(alpha: 0.2),
          width: 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.aurora.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.aurora.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add your own source',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.aurora,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Implement BleSourceProvider and register it in '
                  'source_registry_init.dart',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.fog.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  final BleSourceProvider source;

  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/sources/${source.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.tidePool,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.shimmer.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.glow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                source.icon,
                color: AppTheme.glow.withValues(alpha: 0.8),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.displayName,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.moonbeam,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    source.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.fog,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Badges
                  Row(
                    children: [
                      _Badge(
                        label: '${source.channelCount} ch',
                        color: AppTheme.glow,
                      ),
                      const SizedBox(width: 6),
                      _Badge(
                        label: '${source.sampleRateHz.toInt()} Hz',
                        color: AppTheme.starlight,
                      ),
                      if (source.advertisedNames.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Badge(
                          label: source.advertisedNames.first,
                          color: AppTheme.aurora,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.fog.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.8),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
