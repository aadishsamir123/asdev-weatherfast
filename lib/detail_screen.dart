import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:weather_icons/weather_icons.dart';
import 'weather_service.dart';

class DetailScreen extends StatefulWidget {
  final String? location;

  const DetailScreen({Key? key, required this.location}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
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
      _controller.forward();
    } catch (e) {
      print('Error fetching weather data: $e');
    }
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

  IconData _getWeatherIcon(String weatherText) {
    switch (weatherText.toLowerCase()) {
      case 'clear':
        return FontAwesomeIcons.moon;
      case 'sunny':
        return FontAwesomeIcons.solidSun;
      case 'partly cloudy':
        return FontAwesomeIcons.cloudSun;
      case 'cloudy':
        return FontAwesomeIcons.cloud;
      case 'overcast':
        return FontAwesomeIcons.cloudMeatball;
      case 'mist':
        return FontAwesomeIcons.water;
      case 'fog':
        return FontAwesomeIcons.smog;
      case 'patchy rain possible':
      case 'patchy rain nearby':
      case 'light rain':
      case 'moderate rain':
      case 'heavy rain':
      case 'light rain shower':
      case 'moderate or heavy rain shower':
        return FontAwesomeIcons.cloudRain;
      case 'patchy snow possible':
      case 'light snow':
      case 'moderate snow':
      case 'heavy snow':
      case 'light snow showers':
      case 'moderate or heavy snow showers':
        return FontAwesomeIcons.snowflake;
      case 'patchy sleet possible':
      case 'light sleet':
      case 'moderate or heavy sleet':
        return FontAwesomeIcons.cloudRain; // For sleet
      case 'freezing drizzle':
      case 'patchy freezing drizzle possible':
      case 'light freezing rain':
        return FontAwesomeIcons.temperatureQuarter;
      case 'thundery outbreaks possible':
      case 'patchy light rain with thunder':
      case 'moderate or heavy rain with thunder':
        return FontAwesomeIcons.bolt;
      case 'blizzard':
        return FontAwesomeIcons.wind;
      case 'ice pellets':
      case 'light showers of ice pellets':
      case 'moderate or heavy showers of ice pellets':
        return FontAwesomeIcons.solidCircle;
      default:
        return FontAwesomeIcons.cloudSun;
    }
  }

  Widget _buildHeaderSection() {
    final current = _weatherData!['current'];
    final temperature = current['temp_c'].round();
    final description = current['condition']['text'];
    final placeName = widget.location ?? '';

    return Card(
      elevation: 2,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$temperature°C • $description',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            FaIcon(
              _getWeatherIcon(description),
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSection() {
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
            final conditionText = day['day']['condition']['text'];

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
                      FaIcon(
                        _getWeatherIcon(conditionText),
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

  Widget _buildDetailsSection() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
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
          _weatherData!['forecast']['forecastday'][0]['astro']['moon_phase'],
          WeatherIcons.moon_alt_waxing_crescent_3,
        ),
      ],
    );
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // Remove the AppBar
      body: SafeArea(
        child: _weatherData == null
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 8),
                      _buildForecastSection(),
                      _buildDetailsSection(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
