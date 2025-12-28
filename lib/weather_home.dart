import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'services/global_data.dart';
import 'time_service.dart';
import 'ui/animated_weather_backdrop.dart';
import 'weather_service.dart';

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key, required this.onLocationSelected});

  final Function(String) onLocationSelected;

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  final _weatherService = WeatherService();
  final _timeService = TimeService();
  final TextEditingController _searchController = TextEditingController();

  String? _currentLocation;
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _forecastData;
  DateTime? _localTime;
  bool? _isDaytime;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    if (GlobalData.hasPreloaded && GlobalData.preloadedWeatherData != null) {
      setState(() {
        _weatherData = GlobalData.preloadedWeatherData;
        _forecastData = GlobalData.preloadedForecastData;
        _currentLocation = _weatherData?['location']?['name'];
        _localTime =
            DateTime.tryParse(_weatherData?['location']?['localtime'] ?? '');
        _isDaytime = _weatherData?['current']?['is_day'] == 1;
      });
      GlobalData.hasPreloaded = false;
    } else {
      _fetchWeatherForCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherForCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Enable them in Settings.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError('Location permission denied. Enable it to auto-locate you.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final coords = '${position.latitude},${position.longitude}';
      await _fetchWeather(coords);
    } catch (e) {
      _showError('Unable to fetch location weather. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onRefresh() async {
    if (_currentLocation != null) {
      await _fetchWeather(_currentLocation!);
    } else {
      await _fetchWeatherForCurrentLocation();
    }
  }

  Future<void> _fetchWeather(String location) async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);

    try {
      final weather = await _weatherService.fetchWeather(location);
      final forecast = await _weatherService.fetchForecast(location);

      DateTime? localTime;
      bool? isDaytime;
      final tz = weather['location']?['tz_id'] as String?;
      if (tz != null && tz.isNotEmpty) {
        final timeData = await _timeService.getTimeForLocation(tz);
        localTime = timeData['datetime'] as DateTime?;
        isDaytime = timeData['isDaytime'] as bool?;
      }

      if (!mounted) return;
      final locationName = weather['location']?['name'] as String?;
      setState(() {
        _weatherData = weather;
        _forecastData = forecast;
        _currentLocation = locationName;
        _localTime = localTime;
        _isDaytime = isDaytime;
      });
      // Notify parent of location change
      if (locationName != null && locationName.isNotEmpty) {
        widget.onLocationSelected(locationName);
      }
    } catch (e) {
      if (mounted) _showError('Failed to load weather: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _openSearchSheet() {
    final media = MediaQuery.of(context);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: media.viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search a place',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: Navigator.of(context).pop,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TypeAheadField<String>(
                  suggestionsCallback: (pattern) {
                    if (pattern.isEmpty) return [];
                    return _weatherService.searchLocations(pattern);
                  },
                  builder: (context, controller, focusNode) {
                    _searchController.text = controller.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'City, region, or coordinates',
                        prefixIcon: Icon(Icons.search),
                      ),
                    );
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(suggestion),
                    );
                  },
                  onSelected: (suggestion) {
                    Navigator.of(context).pop();
                    _fetchWeather(suggestion);
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final condition =
        _weatherData?['current']?['condition']?['text'] ?? 'Clear';
    final isDaytime = _isDaytime ?? true;
    final temp = _weatherData?['current']?['temp_c'];
    final today =
        _firstOrNull(_forecastData?['forecast']?['forecastday'] as List?)
            as Map?;
    final maxToday = today?['day']?['maxtemp_c'];
    final minToday = today?['day']?['mintemp_c'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentLocation ?? 'Loading location…',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_localTime != null)
              Text(
                '${DateFormat('EEEE, MMM d').format(_localTime!)} • ${DateFormat('h:mm a').format(_localTime!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search location',
            onPressed: _openSearchSheet,
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Use current location',
            onPressed: _fetchWeatherForCurrentLocation,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          AnimatedWeatherBackdrop(
            condition: condition,
            isDaytime: isDaytime,
            height: 360,
            intensity: 0.65,
          ),
          SafeArea(
            child: RefreshIndicator.adaptive(
              onRefresh: _onRefresh,
              displacement: 32,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: _weatherData == null
                        ? _buildLoadingCard()
                        : _buildHeroCard(
                            condition: condition,
                            temp: temp,
                            high: maxToday,
                            low: minToday,
                          ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: _buildMetricsGrid(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildHourlyStrip(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildDailyForecast(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildInsights(),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
          if (_isRefreshing)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Chip(
                  label: const Text('Updating weather…'),
                  avatar: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.9),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading the sky for you…'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required String condition,
    required dynamic temp,
    required dynamic high,
    required dynamic low,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final localDateTime = _localTime ?? DateTime.now();
    final isDaytime = _isDaytime ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Card(
            elevation: 3,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _iconForCondition(condition),
                        size: 32,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              condition,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              DateFormat('EEE, MMM d • h:mm a')
                                  .format(localDateTime),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(isDaytime ? 'Daytime' : 'Night'),
                        avatar: Icon(
                          isDaytime
                              ? Icons.wb_sunny_rounded
                              : Icons.nights_stay,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        temp != null ? '${temp.round()}°' : '--',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'H ${high != null ? high.round() : '--'}°  ·  L ${low != null ? low.round() : '--'}°',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _insightForWeather(condition),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    if (_weatherData == null) return const SizedBox.shrink();
    final current = _weatherData!['current'];
    final items = [
      _MetricTile(
        label: 'Feels like',
        value: '${current['feelslike_c']?.round() ?? '--'}°',
        icon: Icons.thermostat,
      ),
      _MetricTile(
        label: 'Humidity',
        value: '${current['humidity'] ?? '--'}%',
        icon: Icons.water_drop,
      ),
      _MetricTile(
        label: 'Wind',
        value:
            '${current['wind_kph']?.round() ?? '--'} km/h ${current['wind_dir'] ?? ''}',
        icon: Icons.air,
      ),
      _MetricTile(
        label: 'Air Quality',
        value: current['aqi'] != null && current['aqi'] > 0
            ? '${current['aqi']} - ${current['air_quality_text'] ?? ''}'
            : 'N/A',
        icon: Icons.air_outlined,
      ),
      _MetricTile(
        label: 'Visibility',
        value: '${current['vis_km']?.toStringAsFixed(1) ?? '--'} km',
        icon: Icons.remove_red_eye,
      ),
      _MetricTile(
        label: 'Precip chance',
        value:
            '${_forecastData?['forecast']?['forecastday']?.first?['day']?['daily_chance_of_rain'] ?? '--'}%',
        icon: Icons.umbrella,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map((item) => SizedBox(
                width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
                child: item,
              ))
          .toList(),
    );
  }

  Widget _buildHourlyStrip() {
    final hours = _forecastData?['forecast']?['forecastday']?[0]?['hour'] ?? [];
    if (hours.isEmpty) return const SizedBox.shrink();

    final locationTime =
        DateTime.tryParse(_weatherData?['location']?['localtime'] ?? '') ??
            DateTime.now();

    final futureHours = hours
        .where((hour) {
          final hourTime = DateTime.parse(hour['time']);
          return hourTime.isAfter(locationTime);
        })
        .take(12)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Next hours',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: futureHours.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final hourData = futureHours[index];
                final time =
                    DateFormat('h a').format(DateTime.parse(hourData['time']));
                final temp = hourData['temp_c'];
                final condition = hourData['condition']['text'] as String;
                final precip = hourData['chance_of_rain'] ??
                    hourData['chance_of_snow'] ??
                    '--';

                return _ForecastChip(
                  label: time,
                  value: '${temp.round()}°',
                  icon: _iconForCondition(condition),
                  caption: '$precip% precip',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast() {
    final days = _forecastData?['forecast']?['forecastday'] as List?;
    if (days == null || days.isEmpty) return const SizedBox.shrink();

    final list = days.skip(1).take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Next 6 days',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...list.map((day) {
            final date = DateTime.parse(day['date']);
            final hi = day['day']['maxtemp_c'];
            final lo = day['day']['mintemp_c'];
            final condition = day['day']['condition']['text'] as String;
            final rain = day['day']['daily_chance_of_rain'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DailyTile(
                label: DateFormat('EEE, MMM d').format(date),
                hi: hi,
                lo: lo,
                icon: _iconForCondition(condition),
                subtitle: '$rain% precip',
              ),
            );
          })
        ],
      ),
    );
  }

  Widget _buildInsights() {
    final condition =
        _weatherData?['current']?['condition']?['text'] ?? 'Weather';
    final advice = _insightForWeather(condition);
    final futureAdvice = _futureInsight();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Today’s suggestion',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(advice, style: Theme.of(context).textTheme.bodyLarge),
              if (futureAdvice != null) ...[
                const SizedBox(height: 10),
                Text(
                  futureAdvice,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  String _insightForWeather(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain')) return 'Grab a light shell and keep moving.';
    if (lower.contains('snow')) return 'Layer up and mind slick paths.';
    if (lower.contains('storm') || lower.contains('thunder')) {
      return 'Stay indoors; lightning risk.';
    }
    if (lower.contains('clear') || lower.contains('sunny')) {
      return 'Great light outside. Sunglasses recommended.';
    }
    if (lower.contains('cloud')) {
      return 'Soft clouds today—perfect walking weather.';
    }
    return 'Stay comfortable and check again in a few hours.';
  }

  String? _futureInsight() {
    final hours = _forecastData?['forecast']?['forecastday']?[0]?['hour'] ?? [];
    if (hours.isEmpty) return null;

    final now = _localTime ?? DateTime.now();
    final target = now.add(const Duration(hours: 3));
    Map<String, dynamic>? futureHour;
    for (final hour in hours) {
      final time = DateTime.parse(hour['time']);
      if (time.hour == target.hour) {
        futureHour = hour;
        break;
      }
    }
    if (futureHour == null) return null;
    final cond = (futureHour['condition']['text'] as String).toLowerCase();
    if (cond.contains('rain')) {
      return 'Rain likely in ~3 hours. Keep an umbrella nearby.';
    }
    if (cond.contains('snow')) {
      return 'Snow later today—plan travel with extra time.';
    }
    if (cond.contains('storm') || cond.contains('thunder')) {
      return 'Storm window in a few hours. Wrap up outdoor tasks soon.';
    }
    return 'Next few hours stay steady—good time to be outside.';
  }

  IconData _iconForCondition(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('storm') || lower.contains('thunder')) {
      return Icons.flash_on_rounded;
    }
    if (lower.contains('rain') || lower.contains('drizzle')) {
      return Icons.umbrella_rounded;
    }
    if (lower.contains('snow') || lower.contains('sleet')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('cloud') || lower.contains('overcast')) {
      return Icons.cloud_rounded;
    }
    if (lower.contains('fog') ||
        lower.contains('mist') ||
        lower.contains('haze')) {
      return Icons.water_rounded;
    }
    return Icons.wb_sunny_rounded;
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastChip extends StatelessWidget {
  const _ForecastChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: SizedBox(
        width: 120,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Row(
                children: [
                  Icon(icon, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyTile extends StatelessWidget {
  const _DailyTile({
    required this.label,
    required this.hi,
    required this.lo,
    required this.icon,
    required this.subtitle,
  });

  final String label;
  final dynamic hi;
  final dynamic lo;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: Text(
          '${hi != null ? hi.round() : '--'}° / ${lo != null ? lo.round() : '--'}°',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

dynamic _firstOrNull(List? list) {
  if (list == null || list.isEmpty) return null;
  return list.first;
}
