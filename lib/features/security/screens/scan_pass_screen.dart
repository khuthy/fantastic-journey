import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/services/neon_db_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';

enum _ScanMode { qr, otp }

class ScanPassScreen extends ConsumerStatefulWidget {
  const ScanPassScreen({super.key});

  @override
  ConsumerState<ScanPassScreen> createState() => _ScanPassScreenState();
}

class _ScanPassScreenState extends ConsumerState<ScanPassScreen> {
  _ScanMode _mode = _ScanMode.qr;
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;
  Map<String, dynamic>? _result;
  bool? _success;
  bool _cameraActive = true;
  final _scanController = MobileScannerController();

  @override
  void dispose() {
    _otpCtrl.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _validate(String token) async {
    if (_isValidating) return;
    setState(() {
      _isValidating = true;
      _result = null;
      _success = null;
    });

    try {
      final db = ref.read(neonDbServiceProvider);
      final data = await db.validatePass(token);
      setState(() {
        _result = data;
        _success = data['valid'] as bool? ?? false;
        _cameraActive = false;
      });
    } catch (e) {
      setState(() {
        _success = false;
        _result = {'error': e.toString()};
        _cameraActive = false;
      });
    } finally {
      setState(() => _isValidating = false);
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _success = null;
      _cameraActive = true;
      _otpCtrl.clear();
    });
    _scanController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Visitor Pass'),
        actions: [
          SegmentedButton<_ScanMode>(
            segments: const [
              ButtonSegment(
                value: _ScanMode.qr,
                icon: Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: Text('QR'),
              ),
              ButtonSegment(
                value: _ScanMode.otp,
                icon: Icon(Icons.pin_rounded, size: 18),
                label: Text('OTP'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) {
              setState(() {
                _mode = s.first;
                _reset();
              });
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _result != null ? _buildResult() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    if (_mode == _ScanMode.otp) return _buildOtpEntry();
    return _buildQrScanner();
  }

  Widget _buildQrScanner() {
    return Stack(
      children: [
        if (_cameraActive)
          MobileScanner(
            controller: _scanController,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _scanController.stop();
                _validate(barcode!.rawValue!);
              }
            },
          )
        else
          Container(color: Colors.black),
        // Overlay
        CustomPaint(
          painter: _ScannerOverlayPainter(),
          size: Size.infinite,
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceXXL,
                vertical: AppDimensions.spaceSM,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: const Text(
                'Point camera at visitor QR code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        if (_isValidating)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
      ],
    );
  }

  Widget _buildOtpEntry() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceXXL),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pin_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              Text(
                'Enter Visitor OTP',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Ask the visitor for their 6-digit one-time code.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.space3XL),
              Form(
                key: _formKey,
                child: AppTextField(
                  controller: _otpCtrl,
                  label: 'OTP Code',
                  hint: '123456',
                  prefixIcon: Icons.lock_outline_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitOtp(),
                  validator: Validators.otpCode,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              AppButton(
                label: 'Verify Code',
                isLoading: _isValidating,
                onPressed: _isValidating ? null : _submitOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      _validate(_otpCtrl.text.trim());
    }
  }

  Widget _buildResult() {
    final pass = _result ?? {};
    final isSuccess = _success ?? false;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: isSuccess ? AppColors.success : AppColors.error,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              Text(
                isSuccess ? 'Access Granted' : 'Access Denied',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isSuccess ? AppColors.success : AppColors.error,
                    ),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                isSuccess
                    ? 'Visitor pass is valid. Allow entry.'
                    : pass['error'] as String? ??
                        'Pass is invalid, expired, or already used.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              if (isSuccess && pass.containsKey('visitor_name')) ...[
                const SizedBox(height: AppDimensions.spaceXXL),
                AppCard(
                  padding: const EdgeInsets.all(AppDimensions.spaceXXL),
                  borderColor:
                      AppColors.success.withOpacity(0.3),
                  child: Column(
                    children: [
                      _ResultRow(
                          label: 'Visitor',
                          value: pass['visitor_name'] as String? ?? ''),
                      const Divider(height: AppDimensions.spaceXXL),
                      _ResultRow(
                          label: 'Resident Unit',
                          value: pass['resident_unit'] as String? ?? ''),
                      const Divider(height: AppDimensions.spaceXXL),
                      _ResultRow(
                          label: 'Vehicle',
                          value: pass['vehicle_registration'] as String? ??
                              'Not specified'),
                      const Divider(height: AppDimensions.spaceXXL),
                      _ResultRow(
                          label: 'Expires',
                          value: pass['expires_at'] != null
                              ? AppHelpers.formatDateTime(
                                  DateTime.parse(pass['expires_at'] as String))
                              : ''),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppDimensions.space3XL),
              AppButton(
                label: 'Scan Next',
                leadingIcon: Icons.refresh_rounded,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Scanner frame overlay
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    const cutSize = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: cutSize, height: cutSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Corner brackets
    final corner = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const c = 28.0;
    const r = 14.0;

    void drawCorner(Offset o, double sx, double sy) {
      canvas
        ..drawLine(o.translate(sx * r, 0), o.translate(sx * c, 0), corner)
        ..drawLine(o.translate(0, sy * r), o.translate(0, sy * c), corner)
        ..drawArc(
          Rect.fromCenter(
              center: o.translate(sx * r, sy * r), width: r * 2, height: r * 2),
          sx > 0 ? (sy > 0 ? 3.14159 : -3.14159 / 2) : (sy > 0 ? 3.14159 / 2 : 0),
          3.14159 / 2,
          false,
          corner,
        );
    }

    drawCorner(rect.topLeft, 1, 1);
    drawCorner(rect.topRight, -1, 1);
    drawCorner(rect.bottomLeft, 1, -1);
    drawCorner(rect.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
