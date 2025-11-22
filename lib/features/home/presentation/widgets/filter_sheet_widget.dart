import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  String _sortBy = 'rating';
  RangeValues _priceRange = const RangeValues(0, 5000);
  String? _selectedCity;

  @override
  @override
  Widget build(BuildContext context) {
    final availableCities = ref
        .read(photographersProvider.notifier)
        .availableCities;
    // Ensure selected city is in the list or null
    if (_selectedCity != null && !availableCities.contains(_selectedCity)) {
      _selectedCity = null;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الفلاتر',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortBy = 'rating';
                    _priceRange = const RangeValues(0, 5000);
                    _selectedCity = null;
                  });
                  ref
                      .read(photographersProvider.notifier)
                      .getPhotographers(refresh: true);
                  Navigator.pop(context);
                },
                child: const Text('إعادة تعيين'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'الترتيب حسب',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('التقييم'),
                selected: _sortBy == 'rating',
                onSelected: (selected) => setState(() => _sortBy = 'rating'),
              ),
              ChoiceChip(
                label: const Text('السعر (الأقل)'),
                selected: _sortBy == 'price_low',
                onSelected: (selected) => setState(() => _sortBy = 'price_low'),
              ),
              ChoiceChip(
                label: const Text('السعر (الأعلى)'),
                selected: _sortBy == 'price_high',
                onSelected: (selected) =>
                    setState(() => _sortBy = 'price_high'),
              ),
              ChoiceChip(
                label: const Text('عدد المراجعات'),
                selected: _sortBy == 'reviews',
                onSelected: (selected) => setState(() => _sortBy = 'reviews'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'نطاق السعر',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 5000,
            divisions: 50,
            labels: RangeLabels(
              '${_priceRange.start.round()} ريال',
              '${_priceRange.end.round()} ريال',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('المدينة', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'اختر المدينة',
            ),
            items: availableCities.map((city) {
              return DropdownMenuItem(value: city, child: Text(city));
            }).toList(),
            onChanged: (value) => setState(() => _selectedCity = value),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref
                    .read(photographersProvider.notifier)
                    .getPhotographers(
                      refresh: true,
                      location: _selectedCity,
                      minPrice: _priceRange.start,
                      maxPrice: _priceRange.end,
                    );
                Navigator.pop(context);
              },
              child: const Text('تطبيق الفلاتر'),
            ),
          ),
        ],
      ),
    );
  }
}
