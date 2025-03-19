import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:letsgo/providers/trip_provider.dart';
import 'package:letsgo/widgets/trip_card.dart';
import 'package:letsgo/screens/trip/trip_details_screen.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _updateCamera();
      });
    } catch (e) {
      debugPrint('Ошибка получения местоположения: $e');
    }
  }

  void _updateCamera() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _searchTrips() {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    tripProvider.searchTrips(
      from: _fromController.text,
      to: _toController.text,
      date: _selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск поездок'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _fromController,
                  decoration: const InputDecoration(
                    labelText: 'Откуда',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _toController,
                  decoration: const InputDecoration(
                    labelText: 'Куда',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    'Дата: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _searchTrips,
                  child: const Text('Найти поездки'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TripProvider>(
              builder: (context, tripProvider, child) {
                if (tripProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tripProvider.error != null) {
                  return Center(
                    child: Text(
                      tripProvider.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (tripProvider.trips.isEmpty) {
                  return const Center(
                    child: Text('Поездки не найдены'),
                  );
                }

                if (_showMap) {
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentPosition?.latitude ?? 55.7558,
                        _currentPosition?.longitude ?? 37.6173,
                      ),
                      zoom: 10,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  );
                }

                return ListView.builder(
                  itemCount: tripProvider.trips.length,
                  itemBuilder: (context, index) {
                    final trip = tripProvider.trips[index];
                    return TripCard(
                      trip: trip,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TripDetailsScreen(
                              trip: trip,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
} 