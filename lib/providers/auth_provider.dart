import 'package:flutter_riverpod/flutter_riverpod.dart';

// Login state
final authProvider = StateProvider<bool>((ref) => false);
final adminIdProvider = StateProvider<int?>((ref) => null);
