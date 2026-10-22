import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';
import '../utils/wifi_qr_parser.dart';

class WifiScannerModal extends StatefulWidget {
  const WifiScannerModal({super.key});

  static Future<WifiQrResult?> scan(BuildContext context) {
    return showModalBottomSheet<WifiQrResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WifiScannerModal(),
    );
  }

  @override
  State<WifiScannerModal> createState() => _WifiScannerModalState();
}

class _WifiScannerModalState extends State<WifiScannerModal> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().toUpperCase().startsWith('WIFI:')) {
        final result = WifiQrParser.parse(raw);
        if (result != null) {
          _isProcessing = true;
          HapticFeedback.heavyImpact();
          Navigator.of(context).pop(result);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double modalHeight = mediaQuery.size.height * 0.75;

    return Container(
      height: modalHeight,
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          // Drag handle pill
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderMuted,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Wi-Fi QR Code',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Point camera at phone or router Wi-Fi QR',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.oatMilkBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderMuted),
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Viewfinder Camera
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),

                    // Matcha Viewfinder Frame Overlay
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryMatcha, width: 2.5),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.transparent,
                      ),
                    ),

                    // Torch toggle
                    Positioned(
                      bottom: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: ValueListenableBuilder<MobileScannerState>(
                            valueListenable: _controller,
                            builder: (context, state, _) {
                              return Icon(
                                state.torchState == TorchState.on
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: Colors.white,
                                size: 20,
                              );
                            },
                          ),
                          onPressed: () => _controller.toggleTorch(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
