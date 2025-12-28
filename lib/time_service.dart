import 'dart:convert';
import 'package:http/http.dart' as http;
import 'time_utils.dart';

class TimeService {
  Future<Map<String, dynamic>> getTimeForLocation(String timezone) async {
    await TimeUtils.initialize();
    final localNow = TimeUtils.getLocalTime(timezone);
    final isDaytime = localNow.hour >= 6 && localNow.hour < 18;
    return {
      'datetime': localNow,
      'isDaytime': isDaytime,
    };
  }

  Future<String> findTimezoneByCoordinates(double lat, double lon) async {
    try {
      final url =
          'http://api.geonames.org/timezoneJSON?lat=$lat&lng=$lon&username=geonames';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['timezoneId'];
      } else {
        throw Exception('Failed to find timezone');
      }
    } catch (e) {
      throw Exception('Error finding timezone: $e');
    }
  }
}
