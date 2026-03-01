import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/service_providers.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  late final _permissionService = ref.read(permissionServiceProvider);
  late final _healthService = ref.read(healthServiceProvider);
  bool _isLoading = false;

  final List<PermissionItem> _permissions = [
    PermissionItem(
      icon: Icons.location_on,
      title: 'Location Access',
      description: 'Track your workouts and activities',
      color: Colors.blue,
    ),
    PermissionItem(
      icon: Icons.favorite,
      title: 'Health Data',
      description: 'Monitor your fitness metrics',
      color: Colors.red,
    ),
    PermissionItem(
      icon: Icons.calendar_today,
      title: 'Calendar Access',
      description: 'Schedule your workout sessions',
      color: Colors.green,
    ),
  ];

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      // Request standard permissions with timeout
      await _permissionService.requestAllPermissions().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Permission request timed out');
          return {};
        },
      );

      // Request health permissions with timeout
      await _healthService.requestAuthorization().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Health permission request timed out');
          return false;
        },
      );

      // Navigate to home screen
      if (mounted) {
        context.go('/journal');
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Welcome to',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                'BodyPress',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We need a few permissions to provide you with the best experience',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView.builder(
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final permission = _permissions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: permission.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              permission.icon,
                              color: permission.color,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            permission.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            permission.description,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermissions,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Grant Permissions'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
