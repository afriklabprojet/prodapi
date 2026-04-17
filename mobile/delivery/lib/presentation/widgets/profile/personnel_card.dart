import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../providers/profile_provider.dart';
import '../../../core/utils/snackbar_extension.dart';
import '../common/common_widgets.dart';

class PersonnelCard extends ConsumerWidget {
  final User user;

  const PersonnelCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courier = user.courier;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Informations personnelles',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.editProfile, extra: user),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _divider(),
          _infoTile(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFF059669),
            label: 'Email',
            value: user.email,
          ),
          _divider(),
          _infoTile(
            icon: Icons.phone_android_rounded,
            iconColor: const Color(0xFF3B82F6),
            label: 'Téléphone',
            value: user.phone ?? 'Non renseigné',
            trailing: _editButton(
              onTap: () => _showEditPhoneDialog(context, ref, user.phone),
            ),
          ),
          _divider(),
          _infoTile(
            icon: Icons.two_wheeler_rounded,
            iconColor: const Color(0xFFF59E0B),
            label: 'Véhicule',
            value: courier != null
                ? _vehicleLabel(courier.vehicleType)
                : 'Non configuré',
          ),
          if (courier?.vehicleNumber != null) ...[
            _divider(),
            _infoTile(
              icon: Icons.badge_outlined,
              iconColor: const Color(0xFF8B5CF6),
              label: 'Plaque',
              value: courier!.vehicleNumber ?? '---',
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D26),
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _editButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.edit_rounded,
          size: 14,
          color: Color(0xFF3B82F6),
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
    );
  }

  String _vehicleLabel(String? vehicleType) {
    switch (vehicleType?.toLowerCase()) {
      case 'motorcycle':
        return 'Moto';
      case 'car':
        return 'Voiture';
      case 'bicycle':
        return 'Vélo';
      case 'scooter':
        return 'Scooter';
      default:
        return vehicleType ?? 'Non défini';
    }
  }

  void _showEditPhoneDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentPhone,
  ) {
    final controller = TextEditingController(text: currentPhone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Color(0xFF3B82F6), size: 22),
            SizedBox(width: 12),
            Text(
              'Modifier le téléphone',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Entrez votre nouveau numéro de téléphone',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '+225 07 XX XX XX XX',
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF3B82F6)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un numéro';
                  }
                  final phone = value.replaceAll(RegExp(r'[\s\-\.]'), '');
                  if (phone.length < 8) {
                    return 'Numéro trop court';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                await _updatePhone(context, ref, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePhone(
    BuildContext context,
    WidgetRef ref,
    String newPhone,
  ) async {
    LoadingDialog.show(context, message: 'Mise à jour du numéro...');

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateProfile(phone: newPhone);

      if (context.mounted) LoadingDialog.hide(context);
      ref.invalidate(profileProvider);

      if (context.mounted) {
        context.showSuccess('Numéro de téléphone mis à jour');
      }
    } catch (e) {
      if (context.mounted) LoadingDialog.hide(context);

      if (context.mounted) {
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
        context.showErrorMessage(errorMsg);
      }
    }
  }
}
