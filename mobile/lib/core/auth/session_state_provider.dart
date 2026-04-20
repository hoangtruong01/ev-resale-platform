import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented when an unauthorized API response is detected.
final sessionExpiredTickProvider = StateProvider<int>((ref) => 0);
