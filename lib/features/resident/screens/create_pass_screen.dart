import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/services/neon_db_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'pass_display_screen.dart';

enum _PassDuration { oneHour, fourHours, day, week, custom }

extension _PassDurationExt on _PassDuration {
  String get label {
    switch (this) {
      case _PassDuration.oneHour:
        return '1 hour';
      case _PassDuration.fourHours:
        return '4 hours';
      case _PassDuration.day:
        return '1 day';
      case _PassDuration.week:
        return '1 week';
      case _PassDuration.custom:
        return 'Custom';
    }
  }

  DateTime expiresAt(DateTime? custom) {
    final now = DateTime.now();
    switch (this) {
      case _PassDuration.oneHour:
        return now.add(const Duration(hours: 1));
      case _PassDuration.fourHours:
        return now.add(const Duration(hours: 4));
      case _PassDuration.day:
        return now.add(const Duration(days: 1));
      case _PassDuration.week:
        return now.add(const Duration(days: 7));
      case _PassDuration.custom:
        return custom ?? now.add(const Duration(hours: 4));
    }
  }
}

class CreatePassScreen extends ConsumerStatefulWidget {
  const CreatePassScreen({super.key});

  @override
  ConsumerState<CreatePassScreen> createState() => _CreatePassScreenState();
}

class _CreatePassScreenState extends ConsumerState<CreatePassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();

  bool _useQr = true;
  _PassDuration _duration = _PassDuration.day;
  DateTime? _customExpiry;
  bool _isLoading = false;
  int _maxUses = 1;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final db = ref.read(neonDbServiceProvider);
      final expiry = _duration.expiresAt(_customExpiry);
      final data = await db.createVisitorPass(
        residentId: user.id,
        visitorName: _nameCtrl.text.trim(),
        visitorPhone: _phoneCtrl.text.trim(),
        passType: _useQr ? 'qr' : 'otp',
        expiresAt: expiry,
        vehicleRegistration: _vehicleCtrl.text.trim().isEmpty
            ? null
            : _vehicleCtrl.text.trim(),
        purpose: _purposeCtrl.text.trim().isEmpty
            ? null
            : _purposeCtrl.text.trim(),
        maxUses: _maxUses,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PassDisplayScreen(passData: data),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDateTimePicker(context);
    if (picked != null) {
      setState(() => _customExpiry = picked);
    }
  }

  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          DateTime.now().add(const Duration(hours: 4))),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Visitor Pass'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.residentDashboard)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visitor Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),
                  AppTextField(
                    controller: _nameCtrl,
                    label: "Visitor's full name",
                    hint: 'Jane Smith',
                    prefixIcon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'Visitor name'),
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),
                  AppTextField(
                    controller: _phoneCtrl,
                    label: "Visitor's phone number",
                    hint: '+27 71 234 5678',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),
                  AppTextField(
                    controller: _vehicleCtrl,
                    label: 'Vehicle registration (optional)',
                    hint: 'GP 123 456',
                    prefixIcon: Icons.directions_car_outlined,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    validator: Validators.vehicleReg,
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),
                  AppTextField(
                    controller: _purposeCtrl,
                    label: 'Purpose of visit (optional)',
                    hint: 'e.g. Family visit, delivery...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppDimensions.spaceXXL),

                  // Pass type selection
                  Text(
                    'Pass Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  Row(
                    children: [
                      Expanded(
                        child: _PassTypeCard(
                          icon: Icons.qr_code_2_rounded,
                          title: 'QR Code',
                          subtitle: 'Scan at gate',
                          selected: _useQr,
                          onTap: () => setState(() => _useQr = true),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: _PassTypeCard(
                          icon: Icons.pin_rounded,
                          title: 'OTP Code',
                          subtitle: '6-digit pin',
                          selected: !_useQr,
                          onTap: () => setState(() => _useQr = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceXXL),

                  // Duration
                  Text(
                    'Valid For',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  Wrap(
                    spacing: AppDimensions.spaceSM,
                    runSpacing: AppDimensions.spaceSM,
                    children: _PassDuration.values.map((d) {
                      final selected = _duration == d;
                      return ChoiceChip(
                        label: Text(d.label),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _duration = d);
                          if (d == _PassDuration.custom) _pickCustomDate();
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : null,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  if (_duration == _PassDuration.custom && _customExpiry != null) ...[
                    const SizedBox(height: AppDimensions.spaceSM),
                    Text(
                      'Expires: ${AppHelpers.formatDateTime(_customExpiry!)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spaceXXL),

                  // Max uses
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Max entries allowed',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _maxUses > 1
                                ? () => setState(() => _maxUses--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_maxUses',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: _maxUses < 10
                                ? () => setState(() => _maxUses++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space3XL),
                  AppButton(
                    label: 'Generate Pass',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                    leadingIcon: _useQr
                        ? Icons.qr_code_2_rounded
                        : Icons.pin_rounded,
                  ),
                  const SizedBox(height: AppDimensions.space3XL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassTypeCard extends StatelessWidget {
  const _PassTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.primary : null,
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Row(
        children: [
          Icon(
            icon,
            color: selected ? AppColors.primary : AppColors.textHint,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const Spacer(),
          if (selected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 18,
            ),
        ],
      ),
    );
  }
}
