import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/wallet_provider.dart';

void showWalletMobileMoneySheet(
  BuildContext parentContext,
  WidgetRef ref,
) async {
  String selectedOperator = 'Wave';
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  bool isLoading = false;
  bool isPrimary = true;
  String? errorMessage;
  String? successMessage;
  String? savedPhoneMasked;

  try {
    final data = await ref.read(paymentInfoProvider.future);
    final mobileMoneyList = data['mobile_money'] as List<dynamic>? ?? [];
    if (mobileMoneyList.isNotEmpty) {
      final primary = mobileMoneyList.firstWhere(
        (m) => m['is_primary'] == true,
        orElse: () => mobileMoneyList.first,
      );
      selectedOperator = primary['operator'] ?? 'Wave';
      phoneController.text = primary['phone_number'] ?? '';
      nameController.text = primary['holder_name'] ?? '';
      isPrimary = primary['is_primary'] ?? true;
      savedPhoneMasked = primary['phone_number_masked'] as String?;
    }
  } catch (e, stack) {
    debugPrint(
      '[WalletSettings] Failed to load mobile money settings: $e\n$stack',
    );
  }

  if (!parentContext.mounted) return;

  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setModalState(() => errorMessage = null);
                          },
                          customBorder: const CircleBorder(),
                          child: Icon(
                            Icons.close,
                            color: Colors.red.shade400,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (successMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          successMessage!,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mobile Money',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Recevoir sur votre compte mobile',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Choisir l\'operateur',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildOperatorChip(
                    'Wave',
                    'wave',
                    selectedOperator == 'Wave',
                    () {
                      setModalState(() => selectedOperator = 'Wave');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildOperatorChip(
                    'Orange Money',
                    'orange',
                    selectedOperator == 'Orange Money',
                    () {
                      setModalState(() => selectedOperator = 'Orange Money');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildOperatorChip(
                    'MTN MoMo',
                    'mtn',
                    selectedOperator == 'MTN MoMo',
                    () {
                      setModalState(() => selectedOperator = 'MTN MoMo');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildOperatorChip(
                    'Moov Money',
                    'moov',
                    selectedOperator == 'Moov Money',
                    () {
                      setModalState(() => selectedOperator = 'Moov Money');
                    },
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                obscureText: false,
                decoration: InputDecoration(
                  labelText: 'Numero de telephone',
                  hintText: savedPhoneMasked ?? '+225 XX XX XX XX XX',
                  helperText: savedPhoneMasked != null
                      ? 'Numéro enregistré: $savedPhoneMasked'
                      : null,
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom sur le compte',
                  hintText: 'Nom du titulaire',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Compte principal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Recevoir les paiements sur ce compte',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isPrimary,
                      onChanged: (val) => setModalState(() => isPrimary = val),
                      activeTrackColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setModalState(() {
                            errorMessage = null;
                            successMessage = null;
                          });

                          if (phoneController.text.isEmpty ||
                              nameController.text.isEmpty) {
                            setModalState(
                              () => errorMessage =
                                  'Veuillez remplir tous les champs',
                            );
                            return;
                          }

                          final phone = phoneController.text.trim();
                          if (phone.length < 8) {
                            setModalState(
                              () =>
                                  errorMessage = 'Numéro de téléphone invalide',
                            );
                            return;
                          }

                          setModalState(() => isLoading = true);

                          try {
                            await ref
                                .read(walletActionsProvider.notifier)
                                .saveMobileMoneyInfo(
                                  operator: selectedOperator,
                                  phoneNumber: phone,
                                  accountName: nameController.text.trim(),
                                  isPrimary: isPrimary,
                                );

                            setModalState(() {
                              isLoading = false;
                              successMessage =
                                  'Compte $selectedOperator enregistré avec succès!';
                            });

                            ref.invalidate(paymentInfoProvider);

                            Future.delayed(const Duration(seconds: 2), () {
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            });
                          } catch (e) {
                            setModalState(() {
                              isLoading = false;
                              errorMessage =
                                  'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(ctx).save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildOperatorChip(
  String name,
  String code,
  bool isSelected,
  VoidCallback onTap,
) {
  final Map<String, Color> operatorColors = {
    'wave': Colors.blue,
    'orange': Colors.deepOrange,
    'mtn': Colors.amber.shade700,
    'moov': Colors.green,
  };

  final color = operatorColors[code] ?? Colors.grey;

  return Expanded(
    child: AnimatedScale(
      scale: isSelected ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Material(
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.phone_android,
                  color: isSelected ? color : Colors.grey,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  name.split(' ').first,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
