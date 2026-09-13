import 'dart:math';

class AppConstants {
  static const String appName = 'DCW-SETIF-TRACKER';
  static const String appNameAr = 'منصة الرقابة والتفتيش الميداني';

  // Directorate HQ (مقر مديرية التجارة لولاية سطيف — حي المعبودة، شارع جودي حمو)
  static const double hqLatitude = 36.1930704;
  static const double hqLongitude = 5.3959613;
  static const double hqRadiusMeters = 500.0;

  // Work hours
  static const int workStartHour = 8;
  static const int workEndHour = 16;

  // GPS tracking interval
  static const int gpsTrackingIntervalMinutes = 15;

  // Distance between two GPS points in meters
  static double distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000;
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Check if point is within HQ radius
  static bool isWithinHQ(double lat, double lng) {
    final distance = distanceBetween(lat, lng, hqLatitude, hqLongitude);
    return distance <= hqRadiusMeters;
  }

  static double _toRad(double deg) => deg * pi / 180;
}
