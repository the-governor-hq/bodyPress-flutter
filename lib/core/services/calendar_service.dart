import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

class CalendarService {
  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();

  // Request calendar permissions
  Future<bool> requestPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendar.requestPermissions();
      return permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
    } catch (e) {
      print('Error requesting calendar permissions: $e');
      return false;
    }
  }

  // Check if we have calendar permissions
  Future<bool> hasPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendar.hasPermissions();
      return permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
    } catch (e) {
      print('Error checking calendar permissions: $e');
      return false;
    }
  }

  // Get all calendars
  Future<List<Calendar>> getCalendars() async {
    try {
      final calendarsResult = await _deviceCalendar.retrieveCalendars();
      return calendarsResult.data ?? [];
    } catch (e) {
      print('Error getting calendars: $e');
      return [];
    }
  }

  // Get events from a date range
  Future<List<Event>> getEvents({
    required String calendarId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final eventsResult = await _deviceCalendar.retrieveEvents(
        calendarId,
        RetrieveEventsParams(startDate: startDate, endDate: endDate),
      );
      return eventsResult.data ?? [];
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  // Get today's events from all calendars
  Future<List<Event>> getTodayEvents() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final calendars = await getCalendars();
    final List<Event> allEvents = [];

    for (var calendar in calendars) {
      if (calendar.id != null) {
        final events = await getEvents(
          calendarId: calendar.id!,
          startDate: startOfDay,
          endDate: endOfDay,
        );
        allEvents.addAll(events);
      }
    }

    // Sort by start time
    allEvents.sort((a, b) {
      if (a.start == null || b.start == null) return 0;
      return a.start!.compareTo(b.start!);
    });

    return allEvents;
  }

  // Create a new event
  Future<String?> createEvent({
    required String calendarId,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    try {
      final event = Event(
        calendarId,
        title: title,
        description: description,
        start: tz.TZDateTime.from(startTime, tz.local),
        end: tz.TZDateTime.from(endTime, tz.local),
        location: location,
      );

      final createEventResult = await _deviceCalendar.createOrUpdateEvent(event);
      return createEventResult?.data;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  // Delete an event
  Future<bool> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    try {
      final deleteResult = await _deviceCalendar.deleteEvent(calendarId, eventId);
      return deleteResult.isSuccess;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }
}
