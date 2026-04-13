import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/address_entity.dart';
import '../providers/addresses_provider.dart';

class EditAddressPage extends ConsumerStatefulWidget {
  final AddressEntity address;

  const EditAddressPage({super.key, required this.address});

  @override
  ConsumerState<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends ConsumerState<EditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _instructionsController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address.label);
    _addressController = TextEditingController(text: widget.address.address);
    _cityController = TextEditingController(text: widget.address.city ?? '');
    _phoneController = TextEditingController(text: widget.address.phone ?? '');
    _instructionsController = TextEditingController(
      text: widget.address.instructions ?? '',
    );
    _isDefault = widget.address.isDefault;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier l\'adresse')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'adresse',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adresse'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions de livraison',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Adresse par défaut'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(addressesProvider.notifier)
          .updateAddress(
            id: widget.address.id,
            label: _labelController.text.trim(),
            address: _addressController.text.trim(),
            city: _cityController.text.trim().isNotEmpty
                ? _cityController.text.trim()
                : null,
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            instructions: _instructionsController.text.trim().isNotEmpty
                ? _instructionsController.text.trim()
                : null,
            isDefault: _isDefault,
          );
      if (mounted) {
        AppSnackbar.success(context, 'Adresse mise à jour');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Impossible de mettre à jour l\'adresse');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
