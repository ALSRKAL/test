import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';
import 'package:hajzy/shared/widgets/inputs/custom_textfield.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';
import '../providers/package_provider.dart';
import '../../data/models/package_model.dart';

class PackageManagementPageNew extends ConsumerStatefulWidget {
  const PackageManagementPageNew({super.key});

  @override
  ConsumerState<PackageManagementPageNew> createState() =>
      _PackageManagementPageNewState();
}

class _PackageManagementPageNewState
    extends ConsumerState<PackageManagementPageNew> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(packageProvider.notifier).loadPackages());
  }

  @override
  Widget build(BuildContext context) {
    final packageState = ref.watch(packageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الباقات'),
        backgroundColor: AppColors.primaryGradientStart,
        foregroundColor: Colors.white,
      ),
      body: packageState.isLoading && packageState.packages.isEmpty
          ? const Center(child: LoadingIndicator())
          : packageState.error != null && packageState.packages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    packageState.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomButton(
                    text: 'إعادة المحاولة',
                    onPressed: () =>
                        ref.read(packageProvider.notifier).loadPackages(),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(packageProvider.notifier).loadPackages(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: packageState.packages.length + 1,
                itemBuilder: (context, index) {
                  if (index == packageState.packages.length) {
                    return _buildAddPackageButton();
                  }
                  return _buildPackageCard(packageState.packages[index]);
                },
              ),
            ),
    );
  }

  Widget _buildPackageCard(PackageModel package) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: package.isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.getTextSecondary(context).withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  package.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: package.isActive,
                onChanged: (value) {
                  ref
                      .read(packageProvider.notifier)
                      .togglePackageStatus(package.id!, value);
                },
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '${package.price.toStringAsFixed(0)} ر.س',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGradientStart,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGradientStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  package.duration,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryGradientStart,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'المميزات:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...package.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(feature, style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPackageDialog(package: package),
                  icon: const Icon(Icons.edit),
                  label: const Text('تعديل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGradientStart,
                    side: const BorderSide(
                      color: AppColors.primaryGradientStart,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deletePackage(package),
                  icon: const Icon(Icons.delete),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPackageButton() {
    return GestureDetector(
      onTap: () => _showPackageDialog(),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: AppColors.primaryGradientStart.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: AppColors.primaryGradientStart,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'إضافة باقة جديدة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGradientStart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPackageDialog({PackageModel? package}) {
    showDialog(
      context: context,
      builder: (context) => PackageDialog(package: package),
    );
  }

  void _deletePackage(PackageModel package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الباقة'),
        content: Text('هل أنت متأكد من حذف باقة "${package.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(packageProvider.notifier)
                    .deletePackage(package.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الباقة بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل حذف الباقة: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// Package Dialog
class PackageDialog extends ConsumerStatefulWidget {
  final PackageModel? package;

  const PackageDialog({super.key, this.package});

  @override
  ConsumerState<PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends ConsumerState<PackageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  final List<TextEditingController> _featureControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package?.name ?? '');
    _priceController = TextEditingController(
      text: widget.package?.price.toStringAsFixed(0) ?? '',
    );
    _durationController = TextEditingController(
      text: widget.package?.duration ?? '',
    );

    if (widget.package != null && widget.package!.features.isNotEmpty) {
      for (var feature in widget.package!.features) {
        _featureControllers.add(TextEditingController(text: feature));
      }
    } else {
      _featureControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    for (var controller in _featureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.package == null ? 'إضافة باقة جديدة' : 'تعديل الباقة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  label: 'اسم الباقة',
                  hint: 'مثال: باقة الزفاف الذهبية',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم الباقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'السعر (ريال)',
                  hint: '500',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال السعر';
                    }
                    if (double.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'المدة',
                  hint: 'مثال: 4 ساعات',
                  controller: _durationController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال المدة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المميزات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _featureControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add_circle),
                      color: AppColors.primaryGradientStart,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._featureControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            hint: 'مثال: 50 صورة معدلة',
                            controller: controller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال الميزة';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_featureControllers.length > 1)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                controller.dispose();
                                _featureControllers.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.remove_circle),
                            color: AppColors.error,
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: CustomButton(
                        text: _isLoading
                            ? 'جاري الحفظ...'
                            : (widget.package == null ? 'إضافة' : 'حفظ'),
                        onPressed: _isLoading ? null : _savePackage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final features = _featureControllers
          .map((c) => c.text.trim())
          .where((f) => f.isNotEmpty)
          .toList();

      final package = PackageModel(
        id: widget.package?.id,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        duration: _durationController.text.trim(),
        features: features,
        isActive: widget.package?.isActive ?? true,
      );

      if (widget.package == null) {
        await ref.read(packageProvider.notifier).addPackage(package);
      } else {
        await ref
            .read(packageProvider.notifier)
            .updatePackage(widget.package!.id!, package);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.package == null
                  ? 'تم إضافة الباقة بنجاح'
                  : 'تم تحديث الباقة بنجاح',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ الباقة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
