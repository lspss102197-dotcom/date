import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Map Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MapHomePage(),
    );
  }
}

class MapHomePage extends StatelessWidget {
  const MapHomePage({super.key});

  static const LatLng _taipeiMainStation = LatLng(25.0478, 121.5170);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _MapAppBar(),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _taipeiMainStation,
          zoom: 14,
        ),
      ),
    );
  }
}

class _MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MapAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Google Map'));
  }
}
