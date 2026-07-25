import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/distance_service.dart';

/// Widget untuk mencari alamat dengan autocomplete dari Mapbox/OSM.
/// Bisa dipakai di form Jastip, Suruh, atau halaman alamat.
class AddressSearchField extends ConsumerStatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final ValueChanged<GeocodeRecommendation> onSelected;
  final double? proximityLat;
  final double? proximityLng;

  const AddressSearchField({
    super.key,
    required this.label,
    required this.hint,
    required this.onSelected,
    this.prefixIcon = Icons.search,
    this.proximityLat,
    this.proximityLng,
  });

  @override
  ConsumerState<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends ConsumerState<AddressSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _distanceService = DistanceService();

  List<GeocodeRecommendation> _results = [];
  bool _isSearching = false;
  bool _showDropdown = false;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showDropdown = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _showDropdown = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _distanceService.searchRecommendations(
        query: query,
        proximityLat: widget.proximityLat,
        proximityLng: widget.proximityLng,
      );

      if (!mounted) return;

      setState(() {
        _results = results;
        _showDropdown = results.isNotEmpty;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  void _selectResult(GeocodeRecommendation result) {
    setState(() {
      _selectedAddress = result.fullAddress;
      _controller.text = result.placeName;
      _showDropdown = false;
    });
    widget.onSelected(result);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: _selectedAddress ?? widget.hint,
            prefixIcon: Icon(widget.prefixIcon, color: AppColors.primary, size: 20),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _selectedAddress = null;
                          setState(() {
                            _results = [];
                            _showDropdown = false;
                          });
                        },
                      )
                    : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onChanged: (value) {
            _selectedAddress = null;
            _search(value);
          },
        ),

        // Dropdown hasil pencarian
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final result = _results[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: index == 0
                        ? const BorderRadius.vertical(top: Radius.circular(12))
                        : index == _results.length - 1
                            ? const BorderRadius.vertical(bottom: Radius.circular(12))
                            : null,
                    onTap: () => _selectResult(result),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.placeName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  result.fullAddress,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (result.distanceKm != null)
                            Text(
                              '${result.distanceKm!.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}