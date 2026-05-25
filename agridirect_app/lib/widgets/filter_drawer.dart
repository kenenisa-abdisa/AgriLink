import 'package:flutter/material.dart';
import '../constants.dart';

class FilterDrawer extends StatefulWidget {
  final String? selectedCategory;
  final bool? isOrganicFilter;
  final String locationFilter;
  final double? minPrice;
  final double? maxPrice;
  final Function({
    String? category,
    bool? isOrganic,
    String? location,
    double? minPrice,
    double? maxPrice,
  }) onApplyFilters;
  final VoidCallback onClearFilters;

  const FilterDrawer({
    super.key,
    this.selectedCategory,
    this.isOrganicFilter,
    this.locationFilter = '',
    this.minPrice,
    this.maxPrice,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  String? _selectedCategory;
  bool? _isOrganic;
  String _location = '';
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _isOrganic = widget.isOrganicFilter;
    _location = widget.locationFilter;
    if (widget.minPrice != null) {
      _minPriceController.text = widget.minPrice!.toStringAsFixed(0);
    }
    if (widget.maxPrice != null) {
      _maxPriceController.text = widget.maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Products',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onClearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category
              const Text('Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: productCategories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(
                        '${categoryEmojis[cat] ?? ''} $cat'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1B6B3A).withValues(alpha: 0.2),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? cat : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Organic filter
              const Text('Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _isOrganic == null,
                    onSelected: (_) => setState(() => _isOrganic = null),
                  ),
                  ChoiceChip(
                    label: const Text('🌿 Organic'),
                    selected: _isOrganic == true,
                    selectedColor:
                        const Color(0xFF1B6B3A).withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _isOrganic = true),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location
              const Text('Location',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _location.isEmpty ? null : _location,
                decoration: InputDecoration(
                  hintText: 'Select region',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All regions')),
                  ...ethiopianRegions.map((r) =>
                      DropdownMenuItem(value: r, child: Text(r))),
                ],
                onChanged: (val) => setState(() => _location = val ?? ''),
              ),
              const SizedBox(height: 20),

              // Price range
              const Text('Price Range (ETB)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Min',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Max',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApplyFilters(
                      category: _selectedCategory,
                      isOrganic: _isOrganic,
                      location: _location.isEmpty ? null : _location,
                      minPrice: double.tryParse(_minPriceController.text),
                      maxPrice: double.tryParse(_maxPriceController.text),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B6B3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}