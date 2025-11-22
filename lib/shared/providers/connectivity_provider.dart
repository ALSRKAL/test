import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/network/network_info.dart';

/// Provider for network connectivity status
final connectivityProvider = StreamProvider<bool>((ref) {
  final networkInfo = NetworkInfoImpl(Connectivity());
  return networkInfo.onConnectivityChanged;
});

/// Provider for checking if device is connected
final isConnectedProvider = FutureProvider<bool>((ref) async {
  final networkInfo = NetworkInfoImpl(Connectivity());
  return await networkInfo.isConnected;
});
