import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';
import 'package:hajzy/shared/widgets/inputs/custom_textfield.dart';
import 'package:hajzy/features/photographer/domain/usecases/create_photographer_profile_usecase.dart';
import 'package:hajzy/features/photographer/data/repositories/photographer_repository_impl.dart';
import 'package:hajzy/features/photographer/data/datasources/photographer_remote_datasource.dart';
import 'package:hajzy/features/photographer/data/datasources/photographer_local_datasource.dart';
import 'package:hajzy/core/network/api_client.dart';
import 'package:hajzy/core/services/offline_service.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _selectedSpecialties = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;
  String? _selectedImagePath; // مسار الصورة المختارة (لم ترفع بعد)
  String _selectedCurrency = 'YER'; // العملة الافتراضية

  // Map English to Arabic for display
  final Map<String, String> _englishToArabic = {
    'weddings': 'تصوير الأعراس',
    'events': 'تصوير المناسبات',
    'children': 'تصوير الأطفال',
    'portraits': 'تصوير العائلات',
    'products': 'تصوير المنتجات',
    'fashion': 'تصوير الأزياء',
  };

  // Map Arabic to English for backend
  final Map<String, String> _arabicToEnglish = {
    'تصوير الأعراس': 'weddings',
    'تصوير المناسبات': 'events',
    'تصوير الأطفال': 'children',
    'تصوير العائلات': 'portraits',
    'تصوير المنتجات': 'products',
    'تصوير الأزياء': 'fashion',
  };

  final List<String> _availableSpecialties = [
    'تصوير الأعراس',
    'تصوير المناسبات',
    'تصوير الأطفال',
    'تصوير العائلات',
    'تصوير المنتجات',
    'تصوير الأزياء',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch latest profile data to ensure state is in sync
      ref.read(photographersProvider.notifier).getMyPhotographerProfile();
      _loadCurrentData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this page
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final photographer = ref.read(photographersProvider).selectedPhotographer;
    final user = ref.read(authProvider).user;

    if (mounted) {
      setState(() {
        if (photographer != null) {
          // Edit mode - load from photographer profile
          _isEditMode = true;
          _nameController.text = photographer.name;
          _phoneController.text = user?.phone ?? '';
          _bioController.text = photographer.bio ?? '';
          _cityController.text = photographer.location.city;
          _areaController.text = photographer.location.area;
          _priceController.text = photographer.startingPrice?.toString() ?? '';
          _selectedCurrency = photographer.currency ?? 'YER';
          _avatarUrl = user?.avatar;
          _selectedImagePath = null; // Reset selected image

          // Convert English specialties to Arabic
          _selectedSpecialties.clear();
          for (final specialty in photographer.specialties) {
            final arabic = _englishToArabic[specialty];
            if (arabic != null && !_selectedSpecialties.contains(arabic)) {
              _selectedSpecialties.add(arabic);
            }
          }
        } else if (user != null) {
          // New photographer - pre-fill from user data
          _isEditMode = false;
          _nameController.text = user.name;
          _phoneController.text = user.phone ?? '';
          _avatarUrl = user.avatar;
          _selectedImagePath = null;
          // Leave other fields empty for user to fill
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل الملف الشخصي' : 'إكمال الملف الشخصي'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message (only for new photographers)
              if (!_isEditMode) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGradientStart,
                        AppColors.primaryGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: Colors.white),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'مرحباً بك!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'أكمل ملفك الشخصي لتتمكن من إدارة معرضك وحجوزاتك',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGradientStart,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.getSurface(context),
                        backgroundImage: _selectedImagePath != null
                            ? FileImage(File(_selectedImagePath!))
                            : (_avatarUrl != null
                                  ? NetworkImage(_avatarUrl!)
                                  : null),
                        child: _selectedImagePath == null && _avatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.getTextSecondary(context),
                              )
                            : null,
                      ),
                    ),

                    // Upload indicator
                    if (_isUploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Edit button
                    if (!_isUploadingAvatar)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGradientStart,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: _showAvatarOptions,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Name
              const Text(
                'الاسم',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              CustomTextField(
                controller: _nameController,
                hint: 'اسمك الكامل',
                prefixIcon: const Icon(Icons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الاسم';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Phone
              const Text(
                'رقم الهاتف',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              CustomTextField(
                controller: _phoneController,
                hint: '+967xxxxxxxxx أو 7xxxxxxxx',
                prefixIcon: const Icon(Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال رقم الهاتف';
                  }

                  // Remove spaces and special characters except +
                  final cleanPhone = value.replaceAll(
                    RegExp(r'[\s\-\(\)]'),
                    '',
                  );

                  // Check if it's a valid international format
                  final isValidInternational = RegExp(
                    r'^\+?(20|212|213|216|218|221|222|223|224|225|226|227|228|229|230|231|232|233|234|235|236|237|238|239|240|241|242|243|244|245|246|247|248|249|250|251|252|253|254|255|256|257|258|260|261|262|263|264|265|266|267|268|269|27|290|291|297|298|299|350|351|352|353|354|355|356|357|358|359|370|371|372|373|374|375|376|377|378|380|381|382|383|385|386|387|389|39|40|41|420|421|423|43|44|45|46|47|48|49|500|501|502|503|504|505|506|507|508|509|51|52|53|54|55|56|57|58|590|591|592|593|594|595|596|597|598|599|60|61|62|63|64|65|66|670|672|673|674|675|676|677|678|679|680|681|682|683|684|685|686|687|688|689|690|691|692|850|852|853|855|856|86|870|880|886|90|91|92|93|94|95|960|961|962|963|964|965|966|967|968|970|971|972|973|974|975|976|977|98|992|993|994|995|996|998)\d{7,14}$',
                  ).hasMatch(cleanPhone);

                  // Check common Arab countries local formats
                  final isValidLocal = RegExp(
                    r'^(0?5|0?6|0?7|0?8|0?9|010|011|012|015|050|051|052|053|054|055|056|058|059|060|061|062|063|064|065|066|067|068|069|070|071|072|073|074|075|076|077|078|079|090|091|092|093|094|095|096|097|098|099)\d{7,9}$',
                  ).hasMatch(cleanPhone);

                  if (!isValidInternational && !isValidLocal) {
                    return 'رقم الهاتف غير صحيح';
                  }

                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Bio
              const Text(
                'نبذة عنك',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              CustomTextField(
                controller: _bioController,
                hint: 'اكتب نبذة مختصرة عن خبرتك وأسلوبك في التصوير',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء كتابة نبذة عنك';
                  }
                  if (value.length < 50) {
                    return 'النبذة يجب أن تكون 50 حرف على الأقل';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Starting Price
              const Text(
                'السعر المبدئي (اختياري)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _priceController,
                      hint: 'أقل سعر لخدماتك',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'الرجاء إدخال رقم صحيح';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'YER', child: Text('ر.ي')),
                            DropdownMenuItem(value: 'SAR', child: Text('ر.س')),
                            DropdownMenuItem(
                              value: 'USD',
                              child: Text('دولار'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCurrency = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الموقع',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      hint: 'المدينة',
                      prefixIcon: const Icon(Icons.location_city),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'مطلوب';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomTextField(
                      controller: _areaController,
                      hint: 'الحي',
                      prefixIcon: const Icon(Icons.location_on),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'مطلوب';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Specialties
              const Text(
                'التخصصات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'اختر تخصصاً واحداً على الأقل',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSpecialties.map((specialty) {
                  final isSelected = _selectedSpecialties.contains(specialty);
                  return FilterChip(
                    label: Text(specialty),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSpecialties.add(specialty);
                        } else {
                          _selectedSpecialties.remove(specialty);
                        }
                      });
                    },
                    selectedColor: AppColors.primaryGradientStart.withOpacity(
                      0.2,
                    ),
                    checkmarkColor: AppColors.primaryGradientStart,
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              CustomButton(
                text: _isEditMode ? 'حفظ التغييرات' : 'إنشاء الملف الشخصي',
                onPressed: _isLoading ? null : _submitProfile,
                isLoading: _isLoading,
              ),

              // Info Message (only for new photographers)
              if (!_isEditMode) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGradientStart.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(
                      color: AppColors.primaryGradientStart.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryGradientStart,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'بعد إنشاء الملف، يمكنك إضافة معرض الصور والفيديو الخاص بك',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'صورة الملف الشخصي',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryGradientStart,
              ),
              title: const Text('التقاط صورة'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryGradientStart,
              ),
              title: const Text('اختيار من المعرض'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            if (_avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('حذف الصورة'),
                onTap: _deleteAvatar,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('تم اختيار الصورة! اضغط حفظ لرفعها ✓')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAvatar() async {
    Navigator.pop(context);

    setState(() => _isUploadingAvatar = true);

    try {
      await ref.read(authProvider.notifier).deleteAvatar();

      setState(() {
        _avatarUrl = null;
        _isUploadingAvatar = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('تم حذف الصورة بنجاح! ✓')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingAvatar = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('فشل حذف الصورة: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار تخصص واحد على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert Arabic specialties to English for backend
      final englishSpecialties = _selectedSpecialties
          .map((arabic) => _arabicToEnglish[arabic] ?? 'other')
          .toSet()
          .toList();

      if (_isEditMode) {
        // Upload avatar if selected
        if (_selectedImagePath != null) {
          await ref
              .read(authProvider.notifier)
              .uploadAvatar(_selectedImagePath!);
        }

        // Update user info (name, phone)
        await ref
            .read(authProvider.notifier)
            .updateUserProfile(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
            );

        // Update photographer profile (Backend handles upsert)
        try {
          await ref
              .read(photographersProvider.notifier)
              .updateProfile(
                bio: _bioController.text.trim(),
                specialties: englishSpecialties,
                city: _cityController.text.trim(),
                area: _areaController.text.trim(),
                startingPrice: _priceController.text.isNotEmpty
                    ? double.tryParse(_priceController.text.trim())
                    : null,
                currency: _selectedCurrency,
              );
        } catch (e) {
          rethrow;
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('تم حفظ التغييرات بنجاح! ✓')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop();
      } else {
        // Create new profile
        final apiClient = ApiClient();
        final remoteDataSource = PhotographerRemoteDataSourceImpl(apiClient);
        final offlineService = OfflineService();
        final localDataSource = PhotographerLocalDataSource(offlineService);

        final repository = PhotographerRepositoryImpl(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );

        final useCase = CreatePhotographerProfileUseCase(repository);

        await useCase.call(
          bio: _bioController.text.trim(),
          city: _cityController.text.trim(),
          area: _areaController.text.trim(),
          specialties: englishSpecialties,
          startingPrice: _priceController.text.isNotEmpty
              ? double.tryParse(_priceController.text.trim())
              : null,
          currency: _selectedCurrency,
        );

        if (!mounted) return;

        // Update user role in auth provider
        ref.read(authProvider.notifier).updateUserRole('photographer');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('تم إنشاء الملف الشخصي بنجاح! ✓')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pushReplacementNamed('/photographer-dashboard');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('خطأ: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
