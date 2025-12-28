import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String _geoUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  final String _weatherUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Fetch current weather and forecast for a location
  /// Returns data compatible with the app's existing UI expectations
  Future<Map<String, dynamic>> fetchWeather(String location) async {
    try {
      // First, get coordinates for the location
      final coords = await _getLocationCoordinates(location);
      if (coords == null) {
        throw Exception('Location not found');
      }

      // Fetch weather data for those coordinates
      final weatherData = await _fetchWeatherData(coords['lat'], coords['lon']);

      // Transform to match expected format
      return {
        'location': {
          'name': coords['name'],
          'region': coords['region'] ?? '',
          'country': coords['country'] ?? '',
          'lat': coords['lat'],
          'lon': coords['lon'],
        },
        'current': {
          'temp_c': weatherData['current']['temperature_2m'],
          'temp_f': (weatherData['current']['temperature_2m'] * 9 / 5) + 32,
          'condition': {
            'text':
                _getWeatherDescription(weatherData['current']['weather_code']),
            'icon': _getWeatherIcon(weatherData['current']['weather_code']),
          },
          'humidity': weatherData['current']['relative_humidity_2m'],
          'wind_kph': weatherData['current']['wind_speed_10m'],
          'wind_degree': weatherData['current']['wind_direction_10m'],
          'pressure_mb': weatherData['current']['pressure_msl'],
          'vis_km': weatherData['current'].containsKey('visibility')
              ? weatherData['current']['visibility'] / 1000
              : 10,
        },
      };
    } catch (e) {
      throw Exception('Failed to load weather data: $e');
    }
  }

  /// Fetch 14-day forecast for a location
  Future<Map<String, dynamic>> fetchForecast(String location) async {
    try {
      final coords = await _getLocationCoordinates(location);
      if (coords == null) {
        throw Exception('Location not found');
      }

      final weatherData = await _fetchWeatherData(coords['lat'], coords['lon']);

      // Transform daily forecast to match expected format
      final List<dynamic> forecastDays = [];
      final List<String> dates =
          List<String>.from(weatherData['daily']['time']);
      final List<int> weatherCodes =
          List<int>.from(weatherData['daily']['weather_code']);
      final List<double> maxTemps =
          List<double>.from(weatherData['daily']['temperature_2m_max']);
      final List<double> minTemps =
          List<double>.from(weatherData['daily']['temperature_2m_min']);
      final List<int> precipProb =
          List<int>.from(weatherData['daily']['precipitation_probability_max']);

      for (int i = 0; i < dates.length && i < 14; i++) {
        forecastDays.add({
          'date': dates[i],
          'day': {
            'maxtemp_c': maxTemps[i],
            'maxtemp_f': (maxTemps[i] * 9 / 5) + 32,
            'mintemp_c': minTemps[i],
            'mintemp_f': (minTemps[i] * 9 / 5) + 32,
            'condition': {
              'text': _getWeatherDescription(weatherCodes[i]),
              'icon': _getWeatherIcon(weatherCodes[i]),
            },
            'daily_chance_of_rain': precipProb[i],
          },
        });
      }

      return {
        'location': coords,
        'forecast': {
          'forecastday': forecastDays,
        },
      };
    } catch (e) {
      throw Exception('Failed to load forecast data: $e');
    }
  }

  /// Search for locations by name
  Future<List<String>> searchLocations(String query) async {
    if (query.isEmpty) return [];

    try {
      final url =
          Uri.parse('$_geoUrl?name=$query&count=10&language=en&format=json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] == null || (data['results'] as List).isEmpty) {
          return [];
        }
        return (data['results'] as List)
            .map<String>((item) => '${item['name']}, ${item['country']}')
            .toList();
      } else {
        throw Exception('Failed to fetch location suggestions');
      }
    } catch (e) {
      throw Exception('Failed to search locations: $e');
    }
  }

  /// Get coordinates for a location name
  Future<Map<String, dynamic>?> _getLocationCoordinates(String location) async {
    try {
      final url =
          Uri.parse('$_geoUrl?name=$location&count=1&language=en&format=json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] == null || (data['results'] as List).isEmpty) {
          return null;
        }
        final result = data['results'][0];
        return {
          'name': result['name'],
          'region': result['admin1'],
          'country': result['country'],
          'lat': result['latitude'],
          'lon': result['longitude'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch weather data from Open-Meteo API
  Future<Map<String, dynamic>> _fetchWeatherData(double lat, double lon) async {
    final url = Uri.parse('$_weatherUrl?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m,wind_direction_10m,pressure_msl'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,time'
        '&timezone=auto');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch weather data');
    }
  }

  /// Convert WMO weather code to human-readable description
  String _getWeatherDescription(int code) {
    // WMO Weather interpretation codes
    if (code == 0) return 'Clear sky';
    if (code == 1 || code == 2) return 'Mostly clear';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Foggy';
    if (code == 51 || code == 53 || code == 55) return 'Drizzle';
    if (code == 61 || code == 63 || code == 65) return 'Rain';
    if (code == 71 || code == 73 || code == 75) return 'Snow';
    if (code == 77) return 'Snow grains';
    if (code == 80 || code == 81 || code == 82) return 'Rain showers';
    if (code == 85 || code == 86) return 'Snow showers';
    if (code == 95 || code == 96 || code == 99) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Convert WMO weather code to icon URL
  String _getWeatherIcon(int code) {
    // Return emoji-like representations or icon codes
    if (code == 0) return '☀️'; // Clear
    if (code == 1 || code == 2) return '⛅'; // Mostly clear
    if (code == 3) return '☁️'; // Overcast
    if (code == 45 || code == 48) return '🌫️'; // Foggy
    if (code == 51 || code == 53 || code == 55) return '🌧️'; // Drizzle
    if (code == 61 || code == 63 || code == 65) return '🌧️'; // Rain
    if (code == 71 || code == 73 || code == 75) return '❄️'; // Snow
    if (code == 77) return '❄️'; // Snow grains
    if (code == 80 || code == 81 || code == 82) return '🌦️'; // Rain showers
    if (code == 85 || code == 86) return '❄️'; // Snow showers
    if (code == 95 || code == 96 || code == 99) return '⛈️'; // Thunderstorm
    return '❓';
  }
}
