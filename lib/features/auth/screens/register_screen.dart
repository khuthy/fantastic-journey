import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _emailCtrl, _phoneCtrl, _unitCtrl, _idCtrl,
      _vehicleCtrl, _passwordCtrl, _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          unitNumber: _unitCtrl.text.trim(),
          idNumber: _idCtrl.text.trim().isEmpty ? null : _idCtrl.text.trim(),
          vehicleRegistration: _vehicleCtrl.text.trim().isEmpty
              ? null
              : _vehicleCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        AppHelpers.showSnackBar(context, next.message, isError: true);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 560 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceXXL,
                    vertical: AppDimensions.spaceLG,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resident Registration',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppDimensions.spaceSM),
                      Text(
                        'Fill in your details to create a resident account. Your account will be reviewed by the estate admin.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppDimensions.space3XL),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AppTextField(
                              controller: _nameCtrl,
                              label: 'Full name',
                              hint: 'John Doe',
                              prefixIcon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  Validators.required(v, 'Full name'),
                            ),
                            const SizedBox(height: AppDimensions.spaceLG),
                            AppTextField(
                              controller: _emailCtrl,
                              label: 'Email address',
                              hint: 'you@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: AppDimensions.spaceLG),
                            AppTextField(
                              controller: _phoneCtrl,
                              label: 'Phone number',
                              hint: '+27 71 234 5678',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: Validators.phone,
                            ),
                            const SizedBox(height: AppDimensions.spaceLG),
                            AppTextField(
                              controller: _unitCtrl,
                              label: 'Unit / Stand number',
                              hint: 'e.g. A12 or 45',
                              prefixIcon: Icons.home_outlined,
                              textInputAction: TextInputAction.next,
                              validator: Validators.unitNumber,
                            ),
                            const SizedBox(height: AppDimensions.spaceLG),
                            AppTextField(
                              controller: _idCtrl,
                              label: 'SA ID number (optional)',
                              hint: '8001015009087',
                              prefixIcon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  v == null || v.isEmpty ? null : Validators.idNumber(v),
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
                            const SizedBox(height: AppDimensions.spaceXL),
                            const Divider(),
                            const SizedBox(height: AppDimensions.spaceLG),
                            AppTextField(
                              controller: _passwordCtrl,
                              label: 'Password',
                              hint: 'Min. 8 characters',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePass,
                              textInputAction: TextInputAction.next,
                              validator: Validators.password,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceLG),
                            AppTextField(
                              controller: _confirmCtrl,
                              label: 'Confirm password',
                              hint: 'Re-enter password',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) =>
                                  Validators.confirmPassword(v, _passwordCtrl.text),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space3XL),
                            AppButton(
                              label: 'Create Account',
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _submit,
                            ),
                            const SizedBox(height: AppDimensions.spaceLG),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.textSecondary),
                                ),
                                TextButton(
                                  onPressed: () => context.go(AppRoutes.login),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Sign in'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.space3XL),
                          ],
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
    );
  }
}
