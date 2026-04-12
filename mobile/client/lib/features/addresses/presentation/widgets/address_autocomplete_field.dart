import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/places_autocomplete_service.dart';

/// Widget de recherche d'adresses avec autocomplétion Google Places
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final PlacesAutocompleteService placesService;
  final Function(PlaceDetails details)? onPlaceSelected;
  final String? Function(String?)? validator;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.placesService,
    this.label = 'Adresse',
    this.hint = 'Rechercher une adresse...',
    this.icon = Icons.location_on_outlined,
    this.onPlaceSelected,
    this.validator,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  List<PlacePrediction> _predictions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _debounce;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _removeOverlay();
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 2) {
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    final results = await widget.placesService.searchPlaces(query);

    if (mounted) {
      setState(() {
        _predictions = results;
        _isSearching = false;
        _showSuggestions = results.isNotEmpty;
      });

      if (_showSuggestions) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    _removeOverlay();

    widget.controller.text = prediction.description;

    // Obtenir les détails (coordonnées GPS)
    final details = await widget.placesService.getPlaceDetails(
      prediction.placeId,
    );

    if (details != null && widget.onPlaceSelected != null) {
      widget.onPlaceSelected!(details);
    }
  }

  void _showOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _predictions.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    title: Text(
                      prediction.mainText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      prediction.secondaryText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectPrediction(prediction),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showSuggestions = false;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        validator: widget.validator,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    widget.controller.clear();
                    _removeOverlay();
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
