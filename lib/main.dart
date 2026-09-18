import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mapa Ciclistas',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const StartScreen(),
    );
  }
}

// ============================================================
// CIUDADES
// ============================================================

class City {
  final String name;
  final LatLng location;

  const City({
    required this.name,
    required this.location,
  });
}

const List<City> cities = [
  City(
    name: 'Bogotá',
    location: LatLng(4.6097, -74.0817),
  ),
  City(
    name: 'Medellín',
    location: LatLng(6.2442, -75.5812),
  ),
  City(
    name: 'Cali',
    location: LatLng(3.4516, -76.5320),
  ),
  City(
    name: 'Barranquilla',
    location: LatLng(10.9685, -74.7813),
  ),
  City(
    name: 'Cartagena',
    location: LatLng(10.3910, -75.4794),
  ),
  City(
    name: 'Bucaramanga',
    location: LatLng(7.1193, -73.1227),
  ),
  City(
    name: 'Pereira',
    location: LatLng(4.8087, -75.6906),
  ),
  City(
    name: 'Manizales',
    location: LatLng(5.0703, -75.5138),
  ),
  City(
    name: 'Santa Marta',
    location: LatLng(11.2408, -74.1990),
  ),
  City(
    name: 'Cúcuta',
    location: LatLng(7.8891, -72.4967),
  ),
  City(
    name: 'Ibagué',
    location: LatLng(4.4389, -75.2322),
  ),
  City(
    name: 'Villavicencio',
    location: LatLng(4.1420, -73.6266),
  ),
];

// ============================================================
// PANTALLA INICIAL
// ============================================================

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    checkSavedCity();
  }

  Future<void> checkSavedCity() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCity = prefs.getString('selected_city');

    if (!mounted) return;

    if (savedCity == null) {
      // No hay ciudad guardada: mostrar selección.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CitySelectionScreen(),
        ),
      );
    } else {
      // Buscar la ciudad guardada.
      final city = cities.firstWhere(
        (city) => city.name == savedCity,
        orElse: () => cities.first,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OpenStreetMapScreen(
            selectedCity: city,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ============================================================
// SELECCIÓN DE CIUDAD
// ============================================================

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  City? selectedCity;

  Future<void> saveCity() async {
    if (selectedCity == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'selected_city',
      selectedCity!.name,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OpenStreetMapScreen(
          selectedCity: selectedCity!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu ciudad'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              '¿En qué ciudad vives?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Selecciona tu ciudad para mostrar el mapa de tu zona.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: cities.length,
                itemBuilder: (context, index) {

                  final city = cities[index];

                  return Card(
                    child: RadioListTile<City>(
                      title: Text(
                        city.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: city,
                      groupValue: selectedCity,
                      onChanged: (value) {
                        setState(() {
                          selectedCity = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: selectedCity == null
                    ? null
                    : saveCity,
                child: const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAPA
// ============================================================

class OpenStreetMapScreen extends StatefulWidget {
  final City selectedCity;

  const OpenStreetMapScreen({
    super.key,
    required this.selectedCity,
  });

  @override
  State<OpenStreetMapScreen> createState() =>
      _OpenStreetMapScreenState();
}

class _OpenStreetMapScreenState
    extends State<OpenStreetMapScreen> {

  final MapController _mapController = MapController();

  late LatLng currentLocation;

  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();

    // Comenzamos mostrando la ciudad seleccionada.
    currentLocation = widget.selectedCity.location;

    getLocation();
  }

  // ==========================================================
  // GPS
  // ==========================================================

  Future<void> getLocation() async {

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionSubscription =
        Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((Position position) {

      final LatLng newLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        currentLocation = newLocation;
      });

      _mapController.move(
        newLocation,
        15,
      );
    });
  }

  // ==========================================================
  // CAMBIAR CIUDAD
  // ==========================================================

  Future<void> changeCity() async {

    final newCity = await Navigator.push<City>(
      context,
      MaterialPageRoute(
        builder: (context) => const CitySelectionScreen(),
      ),
    );

    if (newCity == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'selected_city',
      newCity.name,
    );

    if (!mounted) return;

    setState(() {
      currentLocation = newCity.location;
    });

    _mapController.move(
      newCity.location,
      13,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  // ==========================================================
  // INTERFAZ
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(
          widget.selectedCity.name,
        ),

        actions: [

          IconButton(
            icon: const Icon(Icons.location_city),
            tooltip: 'Cambiar ciudad',
            onPressed: changeCity,
          ),

        ],
      ),

      body: FlutterMap(

        mapController: _mapController,

        options: MapOptions(
          initialCenter: widget.selectedCity.location,
          initialZoom: 13,
        ),

        children: [

          TileLayer(
            urlTemplate:
                "https://tile.openstreetmap.de/{z}/{x}/{y}.png",
            userAgentPackageName:
                "com.example.app_ciclistas",
          ),

          MarkerLayer(
            markers: [

              Marker(
                point: currentLocation,
                width: 80,
                height: 80,

                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),

            ],
          ),

        ],
      ),
    );
  }
}
 