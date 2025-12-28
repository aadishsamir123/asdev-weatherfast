import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class TimeUtils {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      tzdata.initializeTimeZones();
      _initialized = true;
    }
  }

  static DateTime getLocalTime(String tzId) {
    final location = tz.getLocation(tzId);
    return tz.TZDateTime.now(location);
  }
}
