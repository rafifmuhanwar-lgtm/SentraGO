import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distance_service.dart';

final distanceServiceProvider = Provider<DistanceService>((ref) {
  return DistanceService();
});
