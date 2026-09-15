import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/system_memory_service.dart';

/// Provider exposing the [SystemMemoryService] instance.
final systemMemoryServiceProvider = Provider<SystemMemoryService>((ref) {
  return const SystemMemoryService();
});

/// Asynchronously fetches the current [SystemMemoryInfo] snapshot.
final systemMemoryInfoProvider = FutureProvider<SystemMemoryInfo>((ref) async {
  final service = ref.watch(systemMemoryServiceProvider);
  return service.getMemoryInfo();
});

/// Resolves the current [DeviceRamTier] (low, standard, or high)
/// based on measured system RAM.
final deviceRamTierProvider = FutureProvider<DeviceRamTier>((ref) async {
  final memInfo = await ref.watch(systemMemoryInfoProvider.future);
  return memInfo.tier;
});
