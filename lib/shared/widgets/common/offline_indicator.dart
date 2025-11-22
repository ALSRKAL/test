import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/offline_provider.dart';

/// مؤشر حالة الاتصال
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final pendingSyncAsync = ref.watch(pendingSyncCountProvider);

    return connectivityAsync.when(
      data: (isOnline) {
        if (isOnline) {
          return pendingSyncAsync.when(
            data: (count) {
              if (count > 0) {
                return _buildSyncingBanner(context, count);
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        }
        return _buildOfflineBanner(context);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _buildOfflineBanner(context),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade700,
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'وضع أوف لاين - سيتم المزامنة عند الاتصال',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingBanner(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.shade700,
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'جاري المزامنة... ($count عملية معلقة)',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// زر المزامنة اليدوية
class ManualSyncButton extends ConsumerWidget {
  const ManualSyncButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final syncService = ref.watch(syncServiceProvider);

    return IconButton(
      icon: syncStatus == SyncStatus.syncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      onPressed: syncStatus == SyncStatus.syncing
          ? null
          : () async {
              ref.read(syncStatusProvider.notifier).setSyncing();
              try {
                final result = await syncService.manualSync();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                }
                ref.read(syncStatusProvider.notifier).setSuccess();
                // تحديث عدد العمليات المعلقة
                ref.invalidate(pendingSyncCountProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشلت المزامنة: $e')),
                  );
                }
                ref.read(syncStatusProvider.notifier).setError();
              } finally {
                Future.delayed(const Duration(seconds: 2), () {
                  ref.read(syncStatusProvider.notifier).setIdle();
                });
              }
            },
      tooltip: 'مزامنة يدوية',
    );
  }
}
