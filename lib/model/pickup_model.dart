import 'package:google_maps_flutter/google_maps_flutter.dart';
class Pickup {
  final int id;
  final LatLng location;
  final String timeSlot;
  final int inventory;

  Pickup({
    required this.id,
    required this.location,
    required this.timeSlot,
    required this.inventory,
  });
}
