import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String? _apiKey = 'WeatherAPI API Key';
  final String _baseUrl = 'https://api.weatherapi.com/v1';

  Future<Map<String, dynamic>> fetchWeather(String location) async {
    final url = Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$location');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Map<String, dynamic>> fetchForecast(String location) async {
    final url =
        Uri.parse('$_baseUrl/forecast.json?key=$_apiKey&q=$location&days=14');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load forecast data');
    }
  }

  Future<List<String>> searchLocations(String query) async {
    final url = Uri.parse('$_baseUrl/search.json?key=$_apiKey&q=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List results = jsonDecode(response.body);
      return results.map<String>((item) => item['name']).toList();
    } else {
      throw Exception('Failed to fetch location suggestions');
    }
  }
}
