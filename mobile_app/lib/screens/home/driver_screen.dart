import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:letsgo/providers/trip_provider.dart';
import 'package:letsgo/providers/auth_provider.dart';
import 'package:letsgo/widgets/trip_card.dart';
import 'package:letsgo/screens/trip/trip_details_screen.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  DateTime? _departureTime;
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMyTrips();
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

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _departureTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _loadMyTrips() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    tripProvider.getMyTrips(authProvider.token!);
  }

  void _createTrip() {
    if (_fromController.text.isEmpty ||
        _toController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _seatsController.text.isEmpty ||
        _departureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    tripProvider.createTrip(
      from: _fromController.text,
      to: _toController.text,
      departureTime: _departureTime!,
      price: double.parse(_priceController.text),
      totalSeats: int.parse(_seatsController.text),
      fromLat: _currentPosition?.latitude ?? 55.7558,
      fromLng: _currentPosition?.longitude ?? 37.6173,
      toLat: 55.7558, // TODO: Получить координаты пункта назначения
      toLng: 37.6173, // TODO: Получить координаты пункта назначения
      token: authProvider.token!,
    );

    // Очищаем поля после создания поездки
    _fromController.clear();
    _toController.clear();
    _priceController.clear();
    _seatsController.clear();
    setState(() {
      _departureTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои поездки'),
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
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Цена за место',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _seatsController,
                  decoration: const InputDecoration(
                    labelText: 'Количество мест',
                    prefixIcon: Icon(Icons.event_seat),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    _departureTime == null
                        ? 'Выберите дату и время'
                        : 'Отправление: ${_departureTime!.toString().split('.')[0]}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDateTime,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _createTrip,
                  child: const Text('Создать поездку'),
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
                    child: Text('У вас пока нет поездок'),
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
                      isDriver: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TripDetailsScreen(
                              trip: trip,
                              isDriver: true,
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
    _priceController.dispose();
    _seatsController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
} 