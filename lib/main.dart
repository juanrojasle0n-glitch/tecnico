
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

// ======================================================
// APP PRINCIPAL
// ======================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mapa Ciclistas',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3F1E8),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6B4F),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ======================================================
// PANTALLA PRINCIPAL
// ======================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    RoutesScreen(),
    AlertsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // ==================================================
      // BARRA INFERIOR
      // ==================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDCE9DF),

        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Mapa',
          ),

          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Rutas',
          ),

          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ======================================================
// MAPA PRINCIPAL
// ======================================================

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;

  // Ubicación inicial: Bogotá
  LatLng currentLocation = const LatLng(
    4.6097,
    -74.0817,
  );

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  // ====================================================
  // GPS
  // ====================================================

  Future<void> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionSubscription = Geolocator.getPositionStream(
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

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  // ====================================================
  // MAPA
  // ====================================================

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // ------------------------------------------------
        // MAPA
        // ------------------------------------------------

        FlutterMap(
          mapController: _mapController,

          options: MapOptions(
            initialCenter: currentLocation,
            initialZoom: 15,
          ),

          children: [

            TileLayer(
              urlTemplate:
                  "https://tile.openstreetmap.de/{z}/{x}/{y}.png",

              userAgentPackageName:
                  "com.example.app_ciclistas",
            ),

            // --------------------------------------------
            // RUTA DE EJEMPLO
            // --------------------------------------------

            PolylineLayer(
              polylines: [
                Polyline(
                  points: const [
                    LatLng(4.6100, -74.0830),
                    LatLng(4.6120, -74.0800),
                    LatLng(4.6140, -74.0770),
                    LatLng(4.6160, -74.0750),
                  ],
                  strokeWidth: 5,
                  color: const Color(0xFFD6AF31),
                ),
              ],
            ),

            // --------------------------------------------
            // UBICACIÓN DEL CICLISTA
            // --------------------------------------------

            MarkerLayer(
              markers: [
                Marker(
                  point: currentLocation,
                  width: 70,
                  height: 70,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 42,
                  ),
                ),
              ],
            ),
          ],
        ),

        // =================================================
        // BUSCADOR
        // =================================================

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              0,
            ),

            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),

              child: Container(
                height: 52,

                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Row(
                  children: [

                    Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),

                    SizedBox(width: 12),

                    Text(
                      '¿A dónde vas hoy?',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // =================================================
        // ALERTAS CERCANAS
        // =================================================

        Positioned(
          top: 100,
          right: 16,

          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFF202522),
              borderRadius: BorderRadius.circular(20),
            ),

            child: const Text(
              '3 alertas cerca',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),

        // =================================================
        // LEYENDA
        // =================================================

        Positioned(
          top: 165,
          left: 16,

          child: Container(
            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                ),
              ],
            ),

            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                LegendItem(
                  color: Color(0xFF34745A),
                  text: 'Tramo seguro',
                ),

                SizedBox(height: 6),

                LegendItem(
                  color: Color(0xFFE3B52F),
                  text: 'Riesgo moderado',
                ),

                SizedBox(height: 6),

                LegendItem(
                  color: Color(0xFFC84A2E),
                  text: 'Punto de siniestralidad',
                ),
              ],
            ),
          ),
        ),

        // =================================================
        // TARJETA DE RUTA
        // =================================================

        Positioned(
          left: 16,
          right: 16,
          bottom: 18,

          child: Container(
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),

              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),

            child: Row(
              children: [

                // ------------------------------------------
                // INFORMACIÓN
                // ------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        'Cra 7 — La Soledad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        '3.2 km   •   14 min   •   2 alertas',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // ------------------------------------------
                // NIVEL DE RIESGO
                // ------------------------------------------

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EEE8),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: const Column(
                    children: [

                      Text(
                        'Bajo',
                        style: TextStyle(
                          color: Color(0xFF34745A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'riesgo',
                        style: TextStyle(
                          color: Color(0xFF34745A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================
// ELEMENTO DE LA LEYENDA
// ======================================================

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({
    super.key,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Container(
          width: 16,
          height: 6,

          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ======================================================
// RUTAS
// ======================================================

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  List<Map<String, String>> myRoutes = [];

  // =========================================================
  // CIUDAD SELECCIONADA
  // =========================================================

  String? selectedCity;

  final Map<String, LatLng> cities = {
    'Bogotá': const LatLng(4.7110, -74.0721),
    'Medellín': const LatLng(6.2442, -75.5812),
    'Cali': const LatLng(3.4516, -76.5320),
    'Barranquilla': const LatLng(10.9685, -74.7813),
    'Cartagena': const LatLng(10.3910, -75.4794),
    'Bucaramanga': const LatLng(7.1193, -73.1227),
    'Pereira': const LatLng(4.8087, -75.6906),
    'Manizales': const LatLng(5.0703, -75.5138),
    'Santa Marta': const LatLng(11.2408, -74.1990),
    'Cúcuta': const LatLng(7.8891, -72.4967),
    'Ibagué': const LatLng(4.4389, -75.2322),
    'Villavicencio': const LatLng(4.1420, -73.6266),
  };

  Future<void> saveSelectedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('selected_city', city);

    setState(() {
      selectedCity = city;
    });
  }

  Future<void> loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCity = prefs.getString('selected_city');

    if (savedCity != null && cities.containsKey(savedCity)) {
      setState(() {
        selectedCity = savedCity;
      });
    }
  }

  bool isLoading = true;

  // ====================================================
  // CARGAR RUTAS
  // ====================================================

  @override
  void initState() {
    super.initState();
    loadRoutes();
  }

  Future<void> loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();

    final savedRoutes = prefs.getStringList('my_routes');

    if (savedRoutes != null) {
      setState(() {
        myRoutes = savedRoutes.map((route) {
          final data = route.split('|');

          return {
            'name': data.isNotEmpty ? data[0] : '',
            'distance': data.length > 1 ? data[1] : '',
            'time': data.length > 2 ? data[2] : '',
          };
        }).toList();

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ====================================================
  // GUARDAR RUTAS
  // ====================================================

  Future<void> saveRoutes() async {
    final prefs = await SharedPreferences.getInstance();

    final routes = myRoutes.map((route) {
      return '${route['name']}|'
          '${route['distance']}|'
          '${route['time']}';
    }).toList();

    await prefs.setStringList(
      'my_routes',
      routes,
    );
  }

  // ====================================================
  // CREAR / EDITAR
  // ====================================================

  void showRouteDialog({int? index}) {
    final nameController = TextEditingController(
      text: index != null
          ? myRoutes[index]['name']
          : '',
    );

    final distanceController = TextEditingController(
      text: index != null
          ? myRoutes[index]['distance']
          : '',
    );

    final timeController = TextEditingController(
      text: index != null
          ? myRoutes[index]['time']
          : '',
    );

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Text(
            index == null
                ? 'Crear mi ruta'
                : 'Editar ruta',
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [

              TextField(
                controller: nameController,

                decoration: const InputDecoration(
                  labelText: 'Nombre de la ruta',
                  hintText: 'Ej. Casa → Universidad',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: distanceController,

                decoration: const InputDecoration(
                  labelText: 'Distancia',
                  hintText: 'Ej. 5.2 km',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: timeController,

                decoration: const InputDecoration(
                  labelText: 'Tiempo estimado',
                  hintText: 'Ej. 24 min',
                ),
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancelar',
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  return;
                }

                final route = {
                  'name': nameController.text.trim(),
                  'distance':
                      distanceController.text.trim(),
                  'time':
                      timeController.text.trim(),
                };

                setState(() {
                  if (index == null) {
                    myRoutes.add(route);
                  } else {
                    myRoutes[index] = route;
                  }
                });

                await saveRoutes();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },

              child: Text(
                index == null
                    ? 'Crear'
                    : 'Guardar',
              ),
            ),
          ],
        );
      },
    );
  }

  // ====================================================
  // ELIMINAR
  // ====================================================

  void deleteRoute(int index) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            '¿Eliminar esta ruta?',
          ),

          content: const Text(
            'Esta acción no se puede deshacer.',
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancelar',
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                setState(() {
                  myRoutes.removeAt(index);
                });

                await saveRoutes();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFC84A2E),

                foregroundColor:
                    Colors.white,
              ),

              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );
  }

  // ====================================================
  // PANTALLA
  // ====================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          15,
          20,
          10,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              'Rutas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Organiza tus rutas y descubre nuevas opciones.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [

                  // ======================================
                  // MIS RUTAS
                  // ======================================

                  const Text(
                    'Mis rutas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (myRoutes.isEmpty)
                    Container(
                      padding:
                          const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      child: const Column(
                        children: [

                          Icon(
                            Icons.route_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 8),

                          Text(
                            'Todavía no tienes rutas guardadas.',
                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ======================================
                  // MIS RUTAS
                  // ======================================

                  ...myRoutes.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final route = entry.value;

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),

                        child: MyRouteCard(
                          name:
                              route['name'] ?? '',

                          distance:
                              route['distance'] ?? '',

                          time:
                              route['time'] ?? '',

                          onEdit: () {
                            showRouteDialog(
                              index: index,
                            );
                          },

                          onDelete: () {
                            deleteRoute(index);
                          },
                        ),
                      );
                    },
                  ),

                  // ======================================
                  // CREAR RUTA
                  // ======================================

                  SizedBox(
                    width: double.infinity,
                    height: 48,

                    child: OutlinedButton.icon(
                      onPressed: () {
                        showRouteDialog();
                      },

                      icon: const Icon(
                        Icons.add,
                      ),

                      label: const Text(
                        'Crear mi ruta',
                      ),

                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(0xFF202522),

                        side: const BorderSide(
                          color:
                              Color(0xFF202522),
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ======================================
                  // RECOMENDADAS
                  // ======================================

                  const Text(
                    'Rutas recomendadas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  RecommendedRouteCard(
                    name:
                        'Cra 7 — La Soledad',

                    distance:
                        '3.2 km',

                    time:
                        '14 min',

                    risk:
                        'Bajo riesgo',

                    riskColor:
                        const Color(0xFF34745A),

                    riskBackground:
                        const Color(0xFFE3EEE8),
                  ),

                  const SizedBox(height: 12),

                  RecommendedRouteCard(
                    name:
                        'Carrera 13 — Chapinero',

                    distance:
                        '4.8 km',

                    time:
                        '21 min',

                    risk:
                        'Riesgo moderado',

                    riskColor:
                        const Color(0xFFB88A16),

                    riskBackground:
                        const Color(0xFFFFF1C7),
                  ),

                  const SizedBox(height: 12),

                  RecommendedRouteCard(
                    name:
                        'Calle 72 — Parque El Virrey',

                    distance:
                        '5.6 km',

                    time:
                        '25 min',

                    risk:
                        'Bajo riesgo',

                    riskColor:
                        const Color(0xFF34745A),

                    riskBackground:
                        const Color(0xFFE3EEE8),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// TARJETA MIS RUTAS
// ======================================================

class MyRouteCard extends StatelessWidget {
  final String name;
  final String distance;
  final String time;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MyRouteCard({
    super.key,
    required this.name,
    required this.distance,
    required this.time,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              const Icon(
                Icons.star,
                color: Color(0xFFD6AF31),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {

                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },

                itemBuilder:
                    (context) => const [

                  PopupMenuItem(
                    value: 'edit',

                    child: Row(
                      children: [

                        Icon(
                          Icons.edit_outlined,
                        ),

                        SizedBox(width: 10),

                        Text('Editar'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'delete',

                    child: Row(
                      children: [

                        Icon(
                          Icons.delete_outline,
                        ),

                        SizedBox(width: 10),

                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [

              const Icon(
                Icons.straighten,
                size: 18,
                color: Colors.grey,
              ),

              const SizedBox(width: 5),

              Text(
                distance,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(width: 20),

              const Icon(
                Icons.access_time,
                size: 18,
                color: Colors.grey,
              ),

              const SizedBox(width: 5),

              Text(
                time,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================
// TARJETA RUTA RECOMENDADA
// ======================================================

class RecommendedRouteCard
    extends StatelessWidget {

  final String name;
  final String distance;
  final String time;
  final String risk;

  final Color riskColor;
  final Color riskBackground;

  const RecommendedRouteCard({
    super.key,
    required this.name,
    required this.distance,
    required this.time,
    required this.risk,
    required this.riskColor,
    required this.riskBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: riskBackground,
                  borderRadius:
                      BorderRadius.circular(9),
                ),

                child: Text(
                  risk,
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [

              const Icon(
                Icons.straighten,
                size: 18,
                color: Colors.grey,
              ),

              const SizedBox(width: 5),

              Text(
                distance,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(width: 20),

              const Icon(
                Icons.access_time,
                size: 18,
                color: Colors.grey,
              ),

              const SizedBox(width: 5),

              Text(
                time,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 42,

            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteDetailScreen(
                      name: name,
                      distance: distance,
                      time: time,
                      risk: risk,
                    ),
                  ),
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF202522),

                foregroundColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),

              child: const Text(
                'Ver ruta',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// DETALLE DE LA RUTA
// ======================================================

class RouteDetailScreen extends StatelessWidget {
  final String name;
  final String distance;
  final String time;
  final String risk;

  const RouteDetailScreen({
    super.key,
    required this.name,
    required this.distance,
    required this.time,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    // Puntos de ejemplo para mostrar el recorrido.
    // Más adelante los reemplazaremos por la ruta real.
    final routePoints = <LatLng>[
      const LatLng(4.6350, -74.0700),
      const LatLng(4.6365, -74.0675),
      const LatLng(4.6380, -74.0645),
      const LatLng(4.6400, -74.0620),
      const LatLng(4.6420, -74.0595),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3EB),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF202522),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Detalle de la ruta',
          style: TextStyle(
            color: Color(0xFF202522),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // ==================================================
          // INFORMACIÓN DE LA RUTA
          // ==================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              5,
              20,
              15,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF202522),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),

                      decoration: BoxDecoration(
                        color: risk == 'Bajo riesgo'
                            ? const Color(0xFFE3EEE8)
                            : const Color(0xFFFFF1C7),

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        risk,
                        style: TextStyle(
                          color: risk == 'Bajo riesgo'
                              ? const Color(0xFF34745A)
                              : const Color(0xFFB88A16),

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Icon(
                      Icons.straighten,
                      size: 18,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      distance,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ==================================================
          // MAPA
          // ==================================================

          SizedBox(
            height: 280,

            child: FlutterMap(
              options: MapOptions(
                initialCenter: routePoints[2],
                initialZoom: 15,
              ),

              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.de/{z}/{x}/{y}.png',

                  userAgentPackageName:
                      'com.example.app_ciclistas',
                ),

                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5,
                      color: const Color(0xFFD4AD32),
                    ),
                  ],
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: routePoints.first,
                      width: 45,
                      height: 45,

                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF34745A),
                        size: 35,
                      ),
                    ),

                    Marker(
                      point: routePoints.last,
                      width: 45,
                      height: 45,

                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFC84A2E),
                        size: 35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ==================================================
          // TRAMOS DE LA RUTA
          // ==================================================

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tramos de la ruta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202522),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _RouteSection(
                    icon: Icons.check_circle,
                    iconColor: const Color(0xFF34745A),
                    title: 'Ciclorruta principal',
                    description:
                        'Tramo separado del tráfico y sin reportes recientes.',
                  ),

                  _RouteSection(
                    icon: Icons.warning,
                    iconColor: const Color(0xFFE5B52E),
                    title: 'Cruce de vía',
                    description:
                        'Intersección que requiere mayor atención.',
                  ),

                  _RouteSection(
                    icon: Icons.cancel,
                    iconColor: const Color(0xFFC84A2E),
                    title: 'Punto de siniestralidad',
                    description:
                        'Zona con reportes de incidentes registrados.',
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // BOTÓN INICIAR RUTA
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteTrackingScreen(
                              routeName: name,
                              plannedDistance: distance,
                            ),
                          ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF202522),
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: const Text(
                        'Iniciar ruta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// TRAMO DE LA RUTA
// ======================================================

class _RouteSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _RouteSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),

      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black12,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            color: iconColor,
            size: 27,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// SEGUIMIENTO DE LA RUTA
// =========================================================

class RouteTrackingScreen extends StatefulWidget {
  final String routeName;
  final String plannedDistance;

  const RouteTrackingScreen({
    super.key,
    required this.routeName,
    required this.plannedDistance,
  });

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {

  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;

  LatLng currentLocation = const LatLng(4.7110, -74.0721);

  bool isTracking = false;

  double distanceTraveled = 0;
  DateTime? startTime;
  DateTime? endTime;
  Duration? routeDuration;

  Position? lastPosition;
  Position? startPosition;

    @override
  void initState() {
    super.initState();
  }

  void startLocationUpdates() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

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
        final newLocation =
            LatLng(position.latitude, position.longitude);

        startPosition ??= position;

        if (startPosition == null) {
        }    

        if (lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            lastPosition!.latitude,
            lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          if (distance > 1) {
            distanceTraveled += distance;
          }
        }

        lastPosition = position;

        setState(() {
          currentLocation = newLocation;
        });

        _mapController.move(newLocation, 16);
      });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> saveRoute() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> savedRoutes =
        prefs.getStringList('saved_routes') ?? [];

    final route = {
      'name': widget.routeName,
      'distance':
          (distanceTraveled / 1000).toStringAsFixed(2),
      'time': routeDuration != null
          ? '${routeDuration!.inMinutes} min'
          : '0 min',
      'startLat': startPosition?.latitude ?? 0,
      'startLng': startPosition?.longitude ?? 0,
      'endLat': lastPosition?.latitude ?? 0,
      'endLng': lastPosition?.longitude ?? 0,
    };

    savedRoutes.add(jsonEncode(route));

    await prefs.setStringList('saved_routes', savedRoutes);
  }

    @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_bike,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              'Ruta: ${widget.routeName}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Distancia planificada: ${widget.plannedDistance}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Recorrido: ${(distanceTraveled / 1000).toStringAsFixed(2)} km',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
            onPressed: () async {
              if (!isTracking) {
                setState(() {
                  isTracking = true;
                  startTime = DateTime.now();
                });

                startLocationUpdates();
              } else {
                setState(() {
                  isTracking = false;
                  endTime = DateTime.now();

                  if (startTime != null) {
                    routeDuration = endTime!.difference(startTime!);
                  }
                });

                _positionSubscription?.cancel();

                await saveRoute();
              }
            },
            child: Text(
              isTracking ? 'Detener ruta' : 'Iniciar seguimiento',
            ),
          ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// ALERTAS
// ======================================================

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const SizedBox(height: 20),

            const Text(
              'Alertas cercanas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Reportes de otros ciclistas y datos de siniestralidad.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            AlertCard(
              title: 'Vía sin iluminación',
              description:
                  'Tramo oscuro con poca visibilidad para ciclistas.',
              distance: '400 m',
              icon: Icons.lightbulb_outline,
            ),

            const SizedBox(height: 12),

            AlertCard(
              title: 'Ciclorruta obstruida',
              description:
                  'Obstáculo reportado sobre la ciclorruta.',
              distance: '850 m',
              icon: Icons.warning_amber,
            ),

            const SizedBox(height: 12),

            AlertCard(
              title: 'Punto de siniestralidad',
              description:
                  'Zona con reportes de accidentes.',
              distance: '1.1 km',
              icon: Icons.dangerous_outlined,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: OutlinedButton(
                onPressed: () {},

                child: const Text(
                  'Reportar un punto de riesgo',
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// TARJETA DE ALERTA
// ======================================================

class AlertCard extends StatelessWidget {
  final String title;
  final String description;
  final String distance;
  final IconData icon;

  const AlertCard({
    super.key,
    required this.title,
    required this.description,
    required this.distance,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),

      child: Row(
        children: [

          Icon(
            icon,
            color: const Color(0xFFC84A2E),
            size: 28,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '📍 $distance',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// PERFIL
// ======================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> routeHistory = [];

  @override
  void initState() {
    super.initState();
    loadRouteHistory(); 
  }

  Future<void> loadRouteHistory() async {
  final prefs = await SharedPreferences.getInstance();

  final List<String> savedRoutes =
      prefs.getStringList('saved_routes') ?? [];

  setState(() {
    routeHistory = savedRoutes
        .map((route) => jsonDecode(route) as Map<String, dynamic>)
        .toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

            const SizedBox(height: 20),

            const Text(
              'Mi perfil',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Row(
                children: [

                  CircleAvatar(
                    radius: 30,
                    child: Icon(
                      Icons.person,
                      size: 35,
                    ),
                  ),

                  SizedBox(width: 15),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        'Ciclista',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Bogotá',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historial de rutas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            if (routeHistory.isEmpty)
              const Text(
                'Todavía no tienes rutas en tu historial.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

            ...routeHistory.map((route) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.directions_bike,
                    color: Colors.green,
                  ),
                  title: Text(
                    route['name'] ?? 'Ruta',
                  ),
                  subtitle: Text(
                    '${route['distance']} km  •  ${route['time']}',
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            const Text(
              'Mis estadísticas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [

                StatisticCard(
                  value: '0',
                  label: 'Recorridos',
                ),

                const SizedBox(width: 10),

                StatisticCard(
                  value: '0 km',
                  label: 'Distancia',
                ),

                const SizedBox(width: 10),

                StatisticCard(
                  value: '0 kcal',
                  label: 'Calorías',
                ),
              ],
            ),

            const SizedBox(height: 25),

            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('Cambiar ciudad'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    ),
    );    
  }
}

// ======================================================
// ESTADÍSTICA
// ======================================================

class StatisticCard extends StatelessWidget {
  final String value;
  final String label;

  const StatisticCard({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 5,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),

        child: Column(
          children: [

            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 