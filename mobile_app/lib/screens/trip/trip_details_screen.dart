import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:letsgo/models/trip.dart';
import 'package:letsgo/providers/trip_provider.dart';
import 'package:letsgo/providers/auth_provider.dart';
import 'package:letsgo/providers/payment_provider.dart';
import 'package:letsgo/providers/review_provider.dart';
import 'package:letsgo/services/payment_service.dart';
import 'package:letsgo/screens/chat/chat_screen.dart';
import 'package:letsgo/screens/review/reviews_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TripDetailsScreen extends StatelessWidget {
  final Trip trip;
  final bool isDriver;

  const TripDetailsScreen({
    super.key,
    required this.trip,
    this.isDriver = false,
  });

  Future<void> _handlePayment(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    try {
      final paymentUrl = await paymentProvider.createPayment(
        trip: trip,
        token: authProvider.token!,
      );

      if (await canLaunchUrl(Uri.parse(paymentUrl))) {
        await launchUrl(Uri.parse(paymentUrl));
        
        // Проверяем статус платежа каждые 5 секунд
        bool isPaid = false;
        while (!isPaid) {
          await Future.delayed(const Duration(seconds: 5));
          isPaid = await paymentProvider.checkPaymentStatus(
            paymentId: paymentUrl.split('/').last,
            token: authProvider.token!,
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Оплата прошла успешно'),
            ),
          );
          
          // Бронируем поездку после успешной оплаты
          await tripProvider.bookTrip(
            trip.id,
            authProvider.token!,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали поездки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(tripId: trip.id),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReviewsScreen(
                    tripId: trip.id,
                    userId: isDriver ? trip.driverId : trip.id,
                    isDriver: isDriver,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(trip.fromLat, trip.fromLng),
                  zoom: 10,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('from'),
                    position: LatLng(trip.fromLat, trip.fromLng),
                    infoWindow: InfoWindow(title: trip.from),
                  ),
                  Marker(
                    markerId: const MarkerId('to'),
                    position: LatLng(trip.toLat, trip.toLng),
                    infoWindow: InfoWindow(title: trip.to),
                  ),
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: [
                      LatLng(trip.fromLat, trip.fromLng),
                      LatLng(trip.toLat, trip.toLng),
                    ],
                  ),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: Icons.location_on,
                    title: 'Откуда',
                    value: trip.from,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    title: 'Куда',
                    value: trip.to,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    title: 'Время отправления',
                    value: DateFormat('dd.MM.yyyy HH:mm').format(trip.departureTime),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.event_seat,
                    title: 'Свободные места',
                    value: '${trip.availableSeats}/${trip.totalSeats}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.attach_money,
                    title: 'Цена за место',
                    value: '${trip.price} ₽',
                  ),
                  if (!isDriver) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.person,
                      title: 'Водитель',
                      value: trip.driverName,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.phone,
                      title: 'Телефон',
                      value: trip.driverPhone,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!isDriver && trip.availableSeats > 0)
                    ElevatedButton(
                      onPressed: () => _handlePayment(context),
                      child: const Text('Оплатить и забронировать'),
                    ),
                  if (isDriver)
                    ElevatedButton(
                      onPressed: () async {
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final tripProvider = Provider.of<TripProvider>(
                          context,
                          listen: false,
                        );

                        try {
                          await tripProvider.cancelTrip(
                            trip.id,
                            authProvider.token!,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Поездка отменена'),
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Отменить поездку'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
} 