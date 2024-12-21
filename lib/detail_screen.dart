import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import 'weather_service.dart';

class DetailScreen extends StatefulWidget {
  final String? location;

  const DetailScreen({Key? key, required this.location}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _fetchForecast();
    }
  }

  Future<void> _fetchForecast() async {
    try {
      final data = await _weatherService.fetchForecast(widget.location!);
      setState(() {
        _weatherData = data;
      });
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  Widget _buildForecastList() {
    final forecastDays = _weatherData!['forecast']['forecastday'];
    return SizedBox(
      height: 150,
      child: Row(
        children: List.generate(
          forecastDays.length,
          (index) {
            final day = forecastDays[index];
            final date = DateTime.parse(day['date']);
            final weekday = _getDayName(date.weekday);

            return Expanded(
              child: Card(
                elevation: 2,
                surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                color: Theme.of(context).colorScheme.surface,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        weekday,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      BoxedIcon(
                        _getWeatherIcon(day['day']['condition']['code']),
                        size: 35,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day['day']['maxtemp_c'].round()}°',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${day['day']['mintemp_c'].round()}°',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${day['day']['daily_chance_of_rain']}% rain',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  IconData _getWeatherIcon(int code) {
    if (code == 1000) return WeatherIcons.day_sunny;
    if (code >= 1003 && code <= 1009) return WeatherIcons.day_cloudy;
    if (code >= 1180 && code <= 1201) return WeatherIcons.rain;
    if (code >= 1210 && code <= 1225) return WeatherIcons.snow;
    if (code >= 1273 && code <= 1282) return WeatherIcons.thunderstorm;
    return WeatherIcons.day_sunny;
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            BoxedIcon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.location == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Details')),
        body: const Center(
            child: Text('Please select a location in the Home tab')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Details for ${widget.location}'),
      ),
      body: _weatherData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildForecastList(),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                  children: [
                    _buildDetailCard(
                      'UV Index',
                      _weatherData!['current']['uv'].toString(),
                      WeatherIcons.day_sunny,
                    ),
                    _buildDetailCard(
                      'Precipitation',
                      '${_weatherData!['current']['precip_mm']} mm',
                      WeatherIcons.rain,
                    ),
                    _buildDetailCard(
                      'Wind Direction',
                      _weatherData!['current']['wind_dir'],
                      WeatherIcons.strong_wind,
                    ),
                    _buildDetailCard(
                      'Pressure',
                      '${_weatherData!['current']['pressure_mb']} mb',
                      WeatherIcons.barometer,
                    ),
                    _buildDetailCard(
                      'Visibility',
                      '${_weatherData!['current']['vis_km']} km',
                      WeatherIcons.fog,
                    ),
                    _buildDetailCard(
                      'Moon Phase',
                      _weatherData!['forecast']['forecastday'][0]['astro']
                          ['moon_phase'],
                      WeatherIcons.moon_alt_waxing_crescent_3,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
