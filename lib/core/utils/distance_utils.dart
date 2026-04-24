import 'package:geolocator/geolocator.dart';

String formatDistanceKm({
  required double? fromLat,
  required double? fromLng,
  required double? toLat,
  required double? toLng,
}) {
  if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
    return 'N/A';
  }
  final meters = Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  final km = meters / 1000.0;
  return '${km.toStringAsFixed(1)} km';
}
