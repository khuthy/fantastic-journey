import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

class PassDisplayScreen extends StatelessWidget {
  const PassDisplayScreen({super.key, required this.passData});
  final Map<String, dynamic> passData;

  bool get _isQr => passData['pass_type'] == 'qr';
  String get _token => passData['token'] as String;
  String get _visitorName => passData['visitor_name'] as String? ?? 'Visitor';
  DateTime get _expiresAt =>
      DateTime.parse(passData['expires_at'] as String);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Pass'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _sharePass(context),
            tooltip: 'Share',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Column(
              children: [
                _PassCard(
                  isQr: _isQr,
                  token: _token,
                  visitorName: _visitorName,
                  expiresAt: _expiresAt,
                  passData: passData,
                ),
                const SizedBox(height: AppDimensions.spaceXXL),
                if (!_isQr) ...[
                  _OtpCopyRow(token: _token),
                  const SizedBox(height: AppDimensions.spaceLG),
                ],
                AppButton(
                  label: 'Done',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: AppDimensions.space3XL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sharePass(BuildContext context) {
    final message = _isQr
        ? 'Your visitor pass for Protea Glen Estate.\n'
            'Visitor: $_visitorName\n'
            'Valid until: ${AppHelpers.formatDateTime(_expiresAt)}\n'
            'Show this QR code at the gate.'
        : 'Your visitor OTP for Protea Glen Estate.\n'
            'Visitor: $_visitorName\n'
            'OTP Code: $_token\n'
            'Valid until: ${AppHelpers.formatDateTime(_expiresAt)}';
    Clipboard.setData(ClipboardData(text: message));
    AppHelpers.showSnackBar(
        context, 'Pass details copied to clipboard — share with your visitor');
  }
}

class _PassCard extends StatelessWidget {
  const _PassCard({
    required this.isQr,
    required this.token,
    required this.visitorName,
    required this.expiresAt,
    required this.passData,
  });

  final bool isQr;
  final String token;
  final String visitorName;
  final DateTime expiresAt;
  final Map<String, dynamic> passData;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceXXL),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Protea Glen Estate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isQr ? 'QR Visitor Pass' : 'OTP Visitor Pass',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gateOpen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.gateOpen.withOpacity(0.4),
                  ),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: AppColors.gateOpen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXXL),

          // QR or OTP display
          if (isQr)
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              ),
              child: QrImageView(
                data: token,
                size: AppDimensions.qrCodeSize,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space3XL,
                vertical: AppDimensions.space3XL,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                token,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                ),
              ),
            ),

          const SizedBox(height: AppDimensions.spaceXXL),

          // Visitor info
          _InfoRow(
            label: 'Visitor',
            value: visitorName,
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          _InfoRow(
            label: 'Vehicle',
            value: passData['vehicle_registration'] as String? ?? 'Not specified',
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          _InfoRow(
            label: 'Max Entries',
            value: '${passData['max_uses'] ?? 1}',
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: AppDimensions.spaceMD),
          _InfoRow(
            label: 'Expires',
            value: AppHelpers.formatDateTime(expiresAt),
            valueColor: AppHelpers.expiryLabel(expiresAt) == 'Expired'
                ? AppColors.error
                : AppColors.accentLight,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OtpCopyRow extends StatelessWidget {
  const _OtpCopyRow({required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Share this 6-digit code with your visitor so they can present it at the gate.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              AppHelpers.showSnackBar(context, 'OTP copied to clipboard');
            },
            tooltip: 'Copy OTP',
          ),
        ],
      ),
    );
  }
}
