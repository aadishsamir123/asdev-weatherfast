import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'weather_service.dart';
import 'package:intl/intl.dart';
import 'time_service.dart';
import 'services/global_data.dart';

class WeatherHome extends StatefulWidget {
  final Function(String) onLocationSelected; // Add this line

  const WeatherHome(
      {super.key, required this.onLocationSelected}); // Modify constructor

  @override
  _WeatherHomeState createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  Color get _appBarColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.black.withOpacity(0.2)
      : Colors.white.withOpacity(0.2);
  final _weatherService = WeatherService();
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  final _timeService = TimeService();
  static const Duration _transitionDuration = Duration(milliseconds: 800);
  String? _currentLocation;
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _forecastData; // Add this line
  DateTime? _localTime; // Changed type
  bool? _isDaytime; // Add this

  @override
  void initState() {
    super.initState();
    if (GlobalData.hasPreloaded && GlobalData.preloadedWeatherData != null) {
      // Use preloaded data
      setState(() {
        _weatherData = GlobalData.preloadedWeatherData;
        _forecastData = GlobalData.preloadedForecastData;
        _currentLocation = _weatherData?['location']?['name'];
        _localTime =
            DateTime.parse(_weatherData?['location']?['localtime'] ?? '');
        _isDaytime = _weatherData?['current']?['is_day'] == 1;
      });
      // Clear after use, to avoid outdated data
      GlobalData.hasPreloaded = false;
    } else {
      _fetchWeatherForCurrentLocation();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherForCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(
            'Location services are disabled. Please enable them in settings.');
        return;
      }

      // Check location permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          'Location permissions are permanently denied. Please enable them in app settings.',
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String coordinates = '${position.latitude},${position.longitude}';
      await _fetchWeather(coordinates);
    } catch (e) {
      _showError('Error fetching location: ${e.toString()}');
    }
  }

  Future<void> _fetchWeather(String locationQuery) async {
    try {
      final data = await _weatherService.fetchWeather(locationQuery);
      final forecastData = await _weatherService.fetchForecast(locationQuery);
      // Remove the call to findTimezoneByCoordinates and use tz_id directly:
      final tzId = data['location']['tz_id'];
      final timeData = await _timeService.getTimeForLocation(tzId);

      setState(() {
        _weatherData = data;
        _forecastData = forecastData;
        _currentLocation = data['location']['name'];
        _localTime = timeData['datetime'];
        _isDaytime = timeData['isDaytime'];
        print(
            'WeatherHome: _currentLocation set to $_currentLocation'); // Debug print
      });
      // Call the callback with the location name
      widget.onLocationSelected(_currentLocation!);
    } catch (e) {
      _showError('Error fetching weather data');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<Color> _getGradientColors(String? weatherText, bool? isDaytime) {
    if (isDaytime == null) {
      return [
        Colors.blue.shade200,
        Colors.blue.shade400,
      ];
    }

    if (!isDaytime) {
      return [
        Colors.grey.shade900,
        Colors.grey.shade800,
      ];
    }

    switch (weatherText?.toLowerCase()) {
      // Clear conditions
      case 'sunny':
      case 'clear':
        return [
          Colors.blue.shade300,
          Colors.lightBlue.shade200,
        ];

      // Cloudy conditions
      case 'partly cloudy':
      case 'cloudy':
      case 'overcast':
        return [
          Colors.grey.shade400,
          Colors.blueGrey.shade300,
        ];

      // Misty/Foggy conditions
      case 'mist':
      case 'fog':
      case 'freezing fog':
        return [
          Colors.grey.shade500,
          Colors.grey.shade300,
        ];

      // Rain conditions
      case 'patchy rain possible':
      case 'patchy rain nearby':
      case 'patchy light rain':
      case 'light rain':
      case 'moderate rain at times':
      case 'moderate rain':
      case 'heavy rain at times':
      case 'heavy rain':
      case 'light rain shower':
      case 'moderate or heavy rain shower':
      case 'torrential rain shower':
        return [
          Colors.blueGrey.shade700,
          Colors.blueGrey.shade400,
        ];

      // Snow conditions
      case 'patchy snow possible':
      case 'blowing snow':
      case 'patchy light snow':
      case 'light snow':
      case 'patchy moderate snow':
      case 'moderate snow':
      case 'patchy heavy snow':
      case 'heavy snow':
      case 'light snow showers':
      case 'moderate or heavy snow showers':
        return [
          Colors.grey.shade300,
          Colors.grey.shade100,
        ];

      // Mixed precipitation
      case 'patchy sleet possible':
      case 'light sleet':
      case 'moderate or heavy sleet':
      case 'light sleet showers':
      case 'moderate or heavy sleet showers':
        return [
          Colors.blueGrey.shade600,
          Colors.grey.shade400,
        ];

      // Freezing conditions
      case 'patchy freezing drizzle possible':
      case 'freezing drizzle':
      case 'heavy freezing drizzle':
      case 'light freezing rain':
      case 'moderate or heavy freezing rain':
        return [
          Colors.indigo.shade300,
          Colors.blueGrey.shade200,
        ];

      // Ice conditions
      case 'ice pellets':
      case 'light showers of ice pellets':
      case 'moderate or heavy showers of ice pellets':
        return [
          Colors.lightBlue.shade100,
          Colors.grey.shade200,
        ];

      // Thunder conditions
      case 'thundery outbreaks possible':
      case 'patchy light rain with thunder':
      case 'moderate or heavy rain with thunder':
      case 'patchy light snow with thunder':
      case 'moderate or heavy snow with thunder':
        return [
          Colors.deepPurple.shade700,
          Colors.grey.shade600,
        ];

      // Blizzard
      case 'blizzard':
        return [
          Colors.grey.shade200,
          Colors.grey.shade400,
        ];

      // Default case
      default:
        return [
          Colors.blue.shade200,
          Colors.blue.shade400,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherText = _weatherData?['current']?['condition']?['text'];
    final gradientColors = _getGradientColors(weatherText, _isDaytime);

    return Scaffold(
      extendBody: true, // Make the body extend behind the navigation bar
      extendBodyBehindAppBar: true, // Make the body extend behind the app bar
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('WeatherFast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _fetchWeatherForCurrentLocation,
            tooltip: 'Use Current Location',
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: _transitionDuration,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16.0),
                Expanded(
                  child: _weatherData == null
                      ? const Center(child: CircularProgressIndicator())
                      : SmartRefresher(
                          enablePullDown: true,
                          header: const WaterDropHeader(),
                          controller: _refreshController,
                          onRefresh: () async {
                            try {
                              await _fetchWeather(_currentLocation ?? '');
                              _refreshController.refreshCompleted();
                            } catch (e) {
                              _refreshController.refreshFailed();
                            }
                          },
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: 8.0),
                                _buildLocationCard(),
                                const SizedBox(height: 8.0),
                                _buildWeatherDetails(),
                                _buildAdviceCard(),
                                const SizedBox(height: 16.0),
                                _buildHourlyForecastCard(),
                                const SizedBox(height: 8.0),
                              ],
                            ),
                          ),
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    final hours = _forecastData?['forecast']?['forecastday']?[0]?['hour'] ?? [];

    // Get location's local time from API
    final locationTime =
        DateTime.parse(_weatherData?['location']?['localtime'] ?? '');

    // Filter hours to only show hours after the location's current time
    final futureHours = hours.where((hour) {
      final hourTime = DateTime.parse(hour['time']);
      return hourTime.isAfter(locationTime);
    }).toList();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: futureHours.length,
        itemBuilder: (context, index) {
          final hourData = futureHours[index];
          // Format time in location's timezone
          final time =
              DateFormat('h a').format(DateTime.parse(hourData['time']));
          final temp = hourData['temp_c'];
          final iconUrl = 'https:${hourData['condition']['icon']}';

          return Card(
            elevation: 1,
            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4.0),
                  Image.network(
                    iconUrl,
                    width: 40,
                    height: 40,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${temp.round()}°C',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TypeAheadField<String>(
      suggestionsCallback: (pattern) {
        if (pattern.isEmpty) {
          return [];
        } else {
          return _weatherService.searchLocations(pattern);
        }
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            hintText: 'Search for a location...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
          ),
        );
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion),
        );
      },
      onSelected: (suggestion) {
        _searchController.text = suggestion;
        _fetchWeather(suggestion);
      },
    );
  }

  // Add this getter for consistent transparency
  Color get _cardBackgroundColor =>
      Theme.of(context).colorScheme.surface.withValues(alpha: 0.8);

  IconData _getAdviceIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'sunny':
        return FontAwesomeIcons.glasses; // Sunglasses for sunny weather
      case 'clear':
        return Icons.snooze_rounded; // Moon for clear night
      case 'partly cloudy':
        return FontAwesomeIcons.personWalking; // Walking icon for nice weather
      case 'cloudy':
        return FontAwesomeIcons.house; // House icon for staying cozy
      case 'overcast':
        return FontAwesomeIcons.shirt; // Clothing icon for jacket advice
      case 'mist':
      case 'fog':
      case 'freezing fog':
        return FontAwesomeIcons.smog; // Fog icon for visibility warning
      case 'patchy rain possible':
      case 'patchy rain nearby':
      case 'light rain':
      case 'moderate rain':
      case 'heavy rain':
        return FontAwesomeIcons.umbrella; // Umbrella for rain
      case 'patchy snow possible':
      case 'patchy snow nearby':
      case 'light snow':
      case 'moderate snow':
      case 'heavy snow':
        return FontAwesomeIcons.snowflake; // Snowflake for snow
      case 'thundery outbreaks possible':
      case 'patchy light rain with thunder':
      case 'moderate or heavy rain with thunder':
        return FontAwesomeIcons.boltLightning; // Lightning icon for thunder
      case 'blizzard':
        return FontAwesomeIcons.wind; // Wind icon for blizzard
      case 'freezing drizzle':
      case 'heavy freezing drizzle':
      case 'light freezing rain':
        return FontAwesomeIcons.temperatureEmpty; // Freezing temperature icon
      case 'ice pellets':
        return FontAwesomeIcons.triangleExclamation; // Warning icon for ice
      default:
        return FontAwesomeIcons.circleInfo; // Default info icon
    }
  }

  Widget _buildAdviceCard() {
    final weather = _weatherData?['current'];
    final weatherText =
        weather?['condition']['text']; // Weather condition (e.g., fog, rain)
    String action = '';
    switch (weatherText?.toLowerCase()) {
      case 'sunny':
        action = 'Wear sunglasses and enjoy the sunshine!';
        break;
      case 'clear':
        action = 'Have a good night\'s rest!';
        break;
      case 'partly cloudy':
        action = 'It\'s partly cloudy, a perfect time for a walk!';
        break;
      case 'cloudy':
        action = 'Stay cozy indoors or enjoy a peaceful cloudy day outside.';
        break;
      case 'overcast':
        action = 'It\'s overcast; you might want a light jacket!';
        break;
      case 'mist':
        action = 'Drive carefully, and stay safe in the mist.';
        break;
      case 'patchy rain possible':
      case 'patchy rain nearby':
        action = 'Carry an umbrella, just in case it rains!';
        break;
      case 'patchy snow possible':
      case 'patchy snow nearby':
        action = 'Dress warmly; light snow might be on its way.';
        break;
      case 'patchy sleet possible':
      case 'patchy sleet nearby':
        action = 'Stay cautious; roads might be slippery with sleet.';
        break;
      case 'patchy freezing drizzle possible':
      case 'patchy freezing drizzle nearby':
        action = 'Watch out for icy patches on roads and sidewalks.';
        break;
      case 'thundery outbreaks possible':
        action = 'Be prepared for thunderstorms; stay indoors if you can.';
        break;
      case 'blowing snow':
        action =
            'Avoid traveling if possible; blowing snow can reduce visibility.';
        break;
      case 'blizzard':
        action = 'Stay indoors and keep warm during the blizzard.';
        break;
      case 'fog':
        action = 'Drive with caution; visibility is reduced in fog.';
        break;
      case 'freezing fog':
        action = 'Take extra care; freezing fog can make surfaces slippery.';
        break;
      case 'patchy light drizzle':
      case 'light drizzle':
        action = 'A drizzle is expected; you might need a light raincoat.';
        break;
      case 'freezing drizzle':
      case 'heavy freezing drizzle':
        action = 'Avoid walking or driving on icy roads.';
        break;
      case 'patchy light rain':
      case 'light rain':
        action = 'Carry an umbrella for the light rain.';
        break;
      case 'moderate rain at times':
      case 'moderate rain':
        action = 'A good raincoat or umbrella is necessary.';
        break;
      case 'heavy rain at times':
      case 'heavy rain':
        action = 'Stay dry; heavy rain is expected!';
        break;
      case 'light freezing rain':
      case 'moderate or heavy freezing rain':
        action = 'Stay indoors if possible; freezing rain is hazardous.';
        break;
      case 'light sleet':
      case 'moderate or heavy sleet':
        action = 'Be careful; sleet can make traveling difficult.';
        break;
      case 'patchy light snow':
      case 'light snow':
        action = 'Wear warm clothes; it\'s a snowy day!';
        break;
      case 'patchy moderate snow':
      case 'moderate snow':
        action = 'Snowfall expected; drive carefully and stay warm.';
        break;
      case 'patchy heavy snow':
      case 'heavy snow':
        action = 'Stay safe in heavy snow conditions.';
        break;
      case 'ice pellets':
      case 'light showers of ice pellets':
      case 'moderate or heavy showers of ice pellets':
        action = 'Ice pellets may occur; avoid unnecessary travel.';
        break;
      case 'light rain shower':
        action = 'Light rain showers expected; grab an umbrella.';
        break;
      case 'moderate or heavy rain shower':
        action = 'It\'s rainy; dress accordingly and stay dry.';
        break;
      case 'torrential rain shower':
        action = 'Severe rain expected; avoid outdoor activities.';
        break;
      case 'light sleet showers':
      case 'moderate or heavy sleet showers':
        action = 'Sleet showers are possible; travel carefully.';
        break;
      case 'light snow showers':
      case 'moderate or heavy snow showers':
        action = 'Snow showers expected; dress warmly.';
        break;
      case 'patchy light rain with thunder':
        action = 'Thunderstorms with rain are expected; stay indoors.';
        break;
      case 'moderate or heavy rain with thunder':
        action = 'Heavy thunderstorms likely; avoid outdoor activities.';
        break;
      case 'patchy light snow with thunder':
      case 'moderate or heavy snow with thunder':
        action = 'Snow with thunderstorms is unusual; stay safe and warm.';
        break;
      case 'windy':
        action =
            'It\'s quite windy outside; secure loose objects and hold onto your hat!';
        break;
      case 'hot':
        action =
            'Temperatures are scorching; stay in the shade or indoors and drink plenty of water.';
        break;
      case 'cold':
        action =
            'It\'s really cold today; wear extra layers before heading out.';
        break;
      case 'hail':
        action = 'Hail is falling; find immediate shelter to avoid damage.';
        break;
      case 'dust storm':
        action =
            'Visibility is low due to dust; consider staying inside for safety.';
        break;
      case 'sand storm':
        action =
            'A sand storm is ongoing; close windows and limit outdoor time.';
        break;
      case 'hazy':
        action = 'The weather is hazy; reduce strenuous activities outdoors.';
        break;
      default:
        action =
            'There\'s no advice available for the current conditions right now.';
    }

    // At the end of the switch statements or after assigning action:
    if (_isDaytime == false) {
      action = 'Have a good night\'s rest.';
    }

    // Generate current advice
    String currentAdvice = action; // Use the existing 'action' variable

    // Analyze future weather to generate future advice
    String futureAdvice =
        'Hmm. There doesn\'t seem to be any weather information available. Stay safe and be prepared!';
    if (_forecastData != null) {
      // Get forecast for the next few hours
      final hours =
          _forecastData?['forecast']?['forecastday']?[0]?['hour'] ?? [];
      if (hours.isNotEmpty) {
        DateTime now = DateTime.now();
        // Find the forecast for 3 hours from now
        DateTime targetTime = now.add(const Duration(hours: 3));
        Map<String, dynamic>? futureHour;
        for (var hourData in hours) {
          DateTime hourTime = DateTime.parse(hourData['time']);
          if (hourTime.hour == targetTime.hour) {
            futureHour = hourData;
            break;
          }
        }
        if (futureHour != null) {
          String futureCondition = futureHour['condition']['text'];
          // Generate future advice based on futureCondition
          futureAdvice = _generateAdvice(futureCondition.toLowerCase());
        }
      }
    }

    return Card(
      elevation: 2.0,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      color: _cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _getAdviceIcon(weatherText), // Use the new icon mapping
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentAdvice,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    futureAdvice,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateAdvice(String condition) {
    switch (condition) {
      case 'sunny':
        return 'It will be sunny soon; plan outdoor activities and wear sunglasses!';
      case 'clear':
        return 'Expect a clear night; perfect for stargazing.';
      case 'partly cloudy':
        return 'Partly cloudy skies ahead; enjoy the mild weather.';
      case 'cloudy':
        return 'Cloudy skies expected; a calm day awaits.';
      case 'overcast':
        return 'Overcast weather coming up; a cozy day indoors might be nice.';
      case 'mist':
        return 'Misty conditions are expected; drive carefully.';
      case 'patchy rain possible':
      case 'patchy rain nearby':
        return 'Rain might arrive soon; carry an umbrella just in case.';
      case 'patchy snow possible':
        return 'Light snow might occur; dress warmly.';
      case 'patchy sleet possible':
        return 'Sleet is possible; roads may get slippery.';
      case 'patchy freezing drizzle possible':
        return 'Freezing drizzle might occur; stay cautious.';
      case 'thundery outbreaks possible':
        return 'Thunderstorms are possible; stay indoors if you can.';
      case 'blowing snow':
        return 'Blowing snow ahead; travel may become difficult.';
      case 'blizzard':
        return 'Blizzard conditions expected; avoid unnecessary trips.';
      case 'fog':
        return 'Foggy conditions are likely; drive with extra care.';
      case 'freezing fog':
        return 'Freezing fog may occur; surfaces could be slippery.';
      case 'patchy light drizzle':
      case 'light drizzle':
        return 'Light drizzle expected; consider a raincoat.';
      case 'freezing drizzle':
      case 'heavy freezing drizzle':
        return 'Freezing drizzle ahead; avoid driving if possible.';
      case 'patchy light rain':
      case 'light rain':
        return 'Light rain is expected in some time; an umbrella might come in handy.';
      case 'moderate rain at times':
      case 'moderate rain':
        return 'Moderate rain expected; dress for wet weather.';
      case 'heavy rain at times':
      case 'heavy rain':
        return 'Heavy rain forecasted; plan to stay dry.';
      case 'light freezing rain':
      case 'moderate or heavy freezing rain':
        return 'Freezing rain coming up; avoid outdoor travel.';
      case 'light sleet':
      case 'moderate or heavy sleet':
        return 'Sleet is likely; roads may be hazardous.';
      case 'patchy light snow':
      case 'light snow':
        return 'Light snow expected; stay warm.';
      case 'patchy moderate snow':
      case 'moderate snow':
        return 'Snowfall is on the way; drive cautiously.';
      case 'patchy heavy snow':
      case 'heavy snow':
        return 'Heavy snow expected; consider staying indoors.';
      case 'ice pellets':
      case 'light showers of ice pellets':
      case 'moderate or heavy showers of ice pellets':
        return 'Ice pellets likely; take precautions if traveling.';
      case 'light rain shower':
        return 'Light rain showers ahead; carry an umbrella.';
      case 'moderate or heavy rain shower':
        return 'Rain showers expected; dress for the weather.';
      case 'torrential rain shower':
        return 'Torrential rain expected; stay indoors and stay safe.';
      case 'light sleet showers':
      case 'moderate or heavy sleet showers':
        return 'Sleet showers forecasted; be cautious on the roads.';
      case 'light snow showers':
      case 'moderate or heavy snow showers':
        return 'Snow showers expected; dress in warm layers.';
      case 'patchy light rain with thunder':
        return 'Thunderstorms with light rain are possible; stay safe indoors.';
      case 'moderate or heavy rain with thunder':
        return 'Thunderstorms with heavy rain expected; avoid outdoor activities.';
      case 'patchy light snow with thunder':
      case 'moderate or heavy snow with thunder':
        return 'Snow with thunderstorms is unusual; prepare for extreme conditions.';
      case 'windy':
        return 'Strong winds are expected soon; secure loose objects and be cautious outdoors.';
      case 'hot':
        return 'Temperatures will soar; keep cool, stay hydrated, and limit sun exposure.';
      case 'cold':
        return 'A cold spell is on its way; prepare warm clothing and heating.';
      case 'hail':
        return 'Possible hail later; keep your vehicle and valuables protected.';
      case 'dust storm':
        return 'Dust storm approaching; shut windows and doors to minimize indoor dust.';
      case 'sand storm':
        return 'Sand storm coming; avoid unnecessary travel and protect your face and eyes.';
      case 'hazy':
        return 'It might get hazy soon; restrict outdoor activity if you have breathing issues.';
      default:
        return 'There\'s no advice available for the future conditions right now.';
    }
  }

  Widget _buildWeatherDetails() {
    // Get weather data
    final weather = _weatherData?['current'];
    final weatherText =
        weather?['condition']['text']; // Weather condition (e.g., fog, rain)
    final temperature = weather?['temp_c']; // Current temperature

    // Example FontAwesome icon mapping for weather conditions
    IconData weatherIcon;
    switch (weatherText?.toLowerCase()) {
      case 'clear':
        weatherIcon = FontAwesomeIcons.moon; // Sun icon
        break;
      case 'sunny':
        weatherIcon = FontAwesomeIcons.solidSun; // Solid sun icon
        break;
      case 'partly cloudy':
        weatherIcon = FontAwesomeIcons.cloudSun; // Cloud with sun icon
        break;
      case 'cloudy':
        weatherIcon = FontAwesomeIcons.cloud; // Cloud icon
        break;
      case 'overcast':
        weatherIcon = FontAwesomeIcons.cloudMeatball; // Overcast icon
        break;
      case 'mist':
        weatherIcon = FontAwesomeIcons.water; // Mist icon
        break;
      case 'fog':
        weatherIcon = FontAwesomeIcons.smog; // Fog (smog) icon
        break;
      case 'patchy rain possible':
      case 'patchy rain nearby':
      case 'light rain':
      case 'moderate rain':
      case 'heavy rain':
      case 'light rain shower':
      case 'moderate or heavy rain shower':
        weatherIcon = FontAwesomeIcons.cloudRain; // Cloud with rain icon
        break;
      case 'patchy snow possible':
      case 'light snow':
      case 'moderate snow':
      case 'heavy snow':
      case 'light snow showers':
      case 'moderate or heavy snow showers':
        weatherIcon = FontAwesomeIcons.snowflake; // Snowflake icon
        break;
      case 'patchy sleet possible':
      case 'light sleet':
      case 'moderate or heavy sleet':
        weatherIcon = FontAwesomeIcons.cloudRain; // Sleet icon
        break;
      case 'freezing drizzle':
      case 'patchy freezing drizzle possible':
      case 'light freezing rain':
        weatherIcon =
            FontAwesomeIcons.temperatureQuarter; // Freezing drizzle icon
        break;
      case 'thundery outbreaks possible':
      case 'patchy light rain with thunder':
      case 'moderate or heavy rain with thunder':
        weatherIcon = FontAwesomeIcons.bolt; // Lightning icon
        break;
      case 'blizzard':
        weatherIcon = FontAwesomeIcons.wind; // Blizzard icon
        break;
      case 'ice pellets':
      case 'light showers of ice pellets':
      case 'moderate or heavy showers of ice pellets':
        weatherIcon = FontAwesomeIcons.solidCircle; // Ice pellets icon
        break;
      default:
        weatherIcon = FontAwesomeIcons.cloudSun; // Default cloud with sun icon
        break;
    }

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          surfaceTintColor:
              Theme.of(context).colorScheme.surfaceTint, // Material You support
          elevation: 2.0,
          color: _cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left: Weather icon from FontAwesome
                Icon(
                  weatherIcon,
                  size: 60,
                  color: Theme.of(context)
                      .colorScheme
                      .primary, // Dynamic icon color
                ),
                // Right: Weather details (City name, temperature, and weather status)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${temperature ?? 0}°C',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weatherText ?? 'Weather Unavailable',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHourlyForecastCard() {
    return Card(
      elevation: 2.0,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      color: _cardBackgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Hourly Forecast',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: _buildHourlyForecast(),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method after the other build methods
  Widget _buildLocationCard() {
    final cityName = _currentLocation ?? 'Unknown';
    final localDateTime = _localTime ?? DateTime.now(); // Use DateTime directly
    final formattedDate = DateFormat('EEEE, MMMM d').format(localDateTime);
    final formattedTime = DateFormat('h:mm a').format(localDateTime);

    return Card(
      elevation: 2.0,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      color: _cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  cityName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
