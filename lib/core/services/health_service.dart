import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  // Health data types we want to access
  static final List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WORKOUT,
  ];

  // Request authorization for health data
  Future<bool> requestAuthorization() async {
    try {
      final permissions = types.map((type) => HealthDataAccess.READ).toList();
      final authorized = await _health.requestAuthorization(types, permissions: permissions);
      return authorized;
    } catch (e) {
      print('Error requesting health authorization: $e');
      return false;
    }
  }

  // Check if authorization has been granted
  Future<bool> hasPermissions() async {
    try {
      final permissions = await _health.hasPermissions(types);
      return permissions ?? false;
    } catch (e) {
      print('Error checking health permissions: $e');
      return false;
    }
  }

  // Get health data for a date range
  Future<List<HealthDataPoint>> getHealthData({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: endTime,
      );
      return healthData;
    } catch (e) {
      print('Error getting health data: $e');
      return [];
    }
  }

  // Get today's step count
  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );

      int totalSteps = 0;
      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
        }
      }
      
      return totalSteps;
    } catch (e) {
      print('Error getting steps: $e');
      return 0;
    }
  }

  // Get heart rate data
  Future<List<HealthDataPoint>> getHeartRateData({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startTime,
        endTime: endTime,
      );
      return healthData;
    } catch (e) {
      print('Error getting heart rate: $e');
      return [];
    }
  }

  // Get calories burned today
  Future<double> getTodayCalories() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: now,
      );

      double totalCalories = 0;
      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          totalCalories += (data.value as NumericHealthValue).numericValue;
        }
      }
      
      return totalCalories;
    } catch (e) {
      print('Error getting calories: $e');
      return 0;
    }
  }

  // Get today's distance in meters
  Future<double> getTodayDistance() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_DELTA],
        startTime: startOfDay,
        endTime: now,
      );

      double totalDistance = 0;
      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          totalDistance += (data.value as NumericHealthValue).numericValue;
        }
      }
      
      return totalDistance;
    } catch (e) {
      print('Error getting distance: $e');
      return 0;
    }
  }

  // Get last night's sleep duration in hours
  Future<double> getLastNightSleep() async {
    final now = DateTime.now();
    final startOfYesterday = DateTime(now.year, now.month, now.day - 1, 18, 0);
    final endOfToday = DateTime(now.year, now.month, now.day, 12, 0);
    
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: startOfYesterday,
        endTime: endOfToday,
      );

      double totalSleepMinutes = 0;
      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          totalSleepMinutes += (data.value as NumericHealthValue).numericValue;
        }
      }
      
      return totalSleepMinutes / 60; // Convert to hours
    } catch (e) {
      print('Error getting sleep: $e');
      return 0;
    }
  }

  // Get average heart rate today
  Future<int> getTodayAverageHeartRate() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startOfDay,
        endTime: now,
      );

      if (healthData.isEmpty) return 0;

      double totalHeartRate = 0;
      int count = 0;
      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          totalHeartRate += (data.value as NumericHealthValue).numericValue;
          count++;
        }
      }
      
      return count > 0 ? (totalHeartRate / count).round() : 0;
    } catch (e) {
      print('Error getting heart rate: $e');
      return 0;
    }
  }

  // Get today's workout count
  Future<int> getTodayWorkoutCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startOfDay,
        endTime: now,
      );

      return healthData.length;
    } catch (e) {
      print('Error getting workouts: $e');
      return 0;
    }
  }
}
