class Trip {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String from;
  final String to;
  final DateTime departureTime;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final String status;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.status,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      driverId: json['driver_id'],
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      from: json['from'],
      to: json['to'],
      departureTime: DateTime.parse(json['departure_time']),
      price: json['price'].toDouble(),
      totalSeats: json['total_seats'],
      availableSeats: json['available_seats'],
      fromLat: json['from_lat'].toDouble(),
      fromLng: json['from_lng'].toDouble(),
      toLat: json['to_lat'].toDouble(),
      toLng: json['to_lng'].toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'from': from,
      'to': to,
      'departure_time': departureTime.toIso8601String(),
      'price': price,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'from_lat': fromLat,
      'from_lng': fromLng,
      'to_lat': toLat,
      'to_lng': toLng,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 