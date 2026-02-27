import 'dart:math';

import '../../../data/models/user_model.dart';

// Haversine distance in km between provider and request location.
double? calculateDistanceKm(UserModel? from, double? toLat, double? toLng) {
  if (from?.latitude == null ||
      from?.longitude == null ||
      toLat == null ||
      toLng == null) {
    return null;
  }

  const earthRadiusKm = 6371.0;
  final lat1 = _toRadians(from!.latitude!);
  final lon1 = _toRadians(from.longitude!);
  final lat2 = _toRadians(toLat);
  final lon2 = _toRadians(toLng);
  final dLat = lat2 - lat1;
  final dLon = lon2 - lon1;

  final a = pow(sin(dLat / 2), 2) +
      cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degree) => degree * (pi / 180.0);
