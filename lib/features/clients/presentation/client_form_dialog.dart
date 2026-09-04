import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/features/clients/data/firestore_clients_repository.dart';
import 'package:jm_imports/features/clients/domain/client.dart';

class ClientFormDialog extends ConsumerStatefulWidget {
  final Client? client;

  const ClientFormDialog({super.key, this.client});

  static Future<bool?> show(BuildContext context, {Client? client}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ClientFormDialog(client: client),
    );
  }

  @override
  ConsumerState<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends ConsumerState<ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _dniRucController;

  bool _isLoading = false;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _dniRucController = TextEditingController(text: widget.client?.dniRuc ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dniRucController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(clientsRepositoryProvider);

      if (_isEditing) {
        final updatedClient = widget.client!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          dniRuc: _dniRucController.text.trim(),
        );
        await repository.update(updatedClient);
      } else {
        final newClient = Client(
          id: '',
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          dniRuc: _dniRucController.text.trim(),
          createdAt: DateTime.now(),
        );
        await repository.add(newClient);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cliente: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_add_rounded, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textLightGray, size: 20),
                      onPressed: () => Navigator.of(context).pop(false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 16),

                // Nombre
                TextFormField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo / Razón Social',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Teléfono (Opcional)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono / WhatsApp (Opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_android_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                // DNI / RUC (Opcional)
                TextFormField(
                  controller: _dniRucController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'DNI / RUC (Opcional)',
                    hintText: 'Ej. 72xxxxxx o 20xxxxxxxx',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancelar',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLightGray),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _saveClient,
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(_isEditing ? 'Actualizar' : 'Guardar Cliente'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
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
}
