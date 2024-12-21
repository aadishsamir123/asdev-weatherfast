import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'settings_screen.dart';
import 'detail_screen.dart';
import 'weather_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherFast());
}

class WeatherFast extends StatelessWidget {
  const WeatherFast({super.key});

  @override
  Widget build(BuildContext context) {
    const defaultSeedColor = Colors.blue;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightColorScheme = lightDynamic ??
            ColorScheme.fromSeed(
                seedColor: defaultSeedColor, brightness: Brightness.light);
        final darkColorScheme = darkDynamic ??
            ColorScheme.fromSeed(
                seedColor: defaultSeedColor, brightness: Brightness.dark);

        return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
          ),
          themeMode: ThemeMode.system,
          home: const WeatherTabs(),
        );
      },
    );
  }
}

class WeatherTabs extends StatefulWidget {
  const WeatherTabs({Key? key}) : super(key: key);

  @override
  _WeatherTabsState createState() => _WeatherTabsState();
}

class _WeatherTabsState extends State<WeatherTabs> {
  int _selectedIndex = 0;
  String? _currentLocation;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Callback to update the current location from WeatherHome
  void _updateLocation(String location) {
    // print('WeatherTabs: _updateLocation called with $location'); // Debug print
    setState(() {
      _currentLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    // print(

    // 'WeatherTabs: Building with _currentLocation = $_currentLocation'); // Debug print

    List<Widget> widgetOptions = <Widget>[
      WeatherHome(
        onLocationSelected: _updateLocation,
      ),
      DetailScreen(
        key: ValueKey(_currentLocation), // Add this line to force rebuild
        location: _currentLocation,
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.list_rounded), label: 'Details'),
          NavigationDestination(
              icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
