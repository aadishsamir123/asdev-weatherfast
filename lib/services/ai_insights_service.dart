import 'dart:convert';
import 'package:http/http.dart' as http;

class AIInsightsService {
  static const String _ollamaUrl = 'http://localhost:11434/api/generate';

  /// Generate weather insights using Ollama
  /// Requires: Ollama running locally with a model like 'mistral' or 'phi'
  Future<String> generateWeatherInsights({
    required String location,
    required String currentCondition,
    required int currentTemp,
    required int highTemp,
    required int lowTemp,
    required int humidity,
    required double windSpeed,
    required double uvIndex,
    required String forecastSummary,
  }) async {
    try {
      final prompt = _buildPrompt(
        location: location,
        currentCondition: currentCondition,
        currentTemp: currentTemp,
        highTemp: highTemp,
        lowTemp: lowTemp,
        humidity: humidity,
        windSpeed: windSpeed,
        uvIndex: uvIndex,
        forecastSummary: forecastSummary,
      );

      final response = await http
          .post(
            Uri.parse(_ollamaUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'mistral', // or 'phi', 'neural-chat', etc.
              'prompt': prompt,
              'stream': false,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final insights = data['response'] as String? ?? '';
        return insights.trim();
      } else {
        return _getDefaultInsights(
          currentCondition: currentCondition,
          currentTemp: currentTemp,
          highTemp: highTemp,
          forecastSummary: forecastSummary,
        );
      }
    } catch (e) {
      // AI insights generation failed, using defaults
      return _getDefaultInsights(
        currentCondition: currentCondition,
        currentTemp: currentTemp,
        highTemp: highTemp,
        forecastSummary: forecastSummary,
      );
    }
  }

  String _buildPrompt({
    required String location,
    required String currentCondition,
    required int currentTemp,
    required int highTemp,
    required int lowTemp,
    required int humidity,
    required double windSpeed,
    required double uvIndex,
    required String forecastSummary,
  }) {
    return '''You are a friendly weather expert. Provide 2-3 short, practical weather insights for $location based on this data:

Current: $currentCondition, $currentTemp°C
Today's High/Low: $highTemp°C / $lowTemp°C
Humidity: $humidity%
Wind: ${windSpeed.toStringAsFixed(1)} km/h
UV Index: ${uvIndex.toStringAsFixed(1)}
Next 7 days: $forecastSummary

Give specific, actionable recommendations for the day ahead. Be concise and friendly. Use bullet points.''';
  }

  String _getDefaultInsights({
    required String currentCondition,
    required int currentTemp,
    required int highTemp,
    required String forecastSummary,
  }) {
    final insights = <String>[];

    if (currentCondition.toLowerCase().contains('rain')) {
      insights.add('• Bring an umbrella—rain expected today');
      insights.add('• Roads may be slick; drive carefully');
    } else if (currentCondition.toLowerCase().contains('clear') ||
        currentCondition.toLowerCase().contains('sunny')) {
      insights.add('• Perfect day for outdoor activities');
      insights.add('• Apply sunscreen—strong UV');
    } else if (currentCondition.toLowerCase().contains('cloud')) {
      insights.add('• Mild conditions expected');
      insights.add('• Good day for a walk');
    }

    if (highTemp > 30) {
      insights.add('• Stay hydrated in the heat');
    } else if (highTemp < 5) {
      insights.add('• Bundle up for the cold');
    }

    if (insights.isEmpty) {
      insights.add('• Temperature: $highTemp°C');
      insights.add('• Condition: $currentCondition');
    }

    return insights.join('\n');
  }
}
