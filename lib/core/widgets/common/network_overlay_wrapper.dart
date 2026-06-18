import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../theme/typography.dart';

class NetworkOverlayWrapper extends StatefulWidget {
  final Widget child;

  const NetworkOverlayWrapper({super.key, required this.child});

  @override
  State<NetworkOverlayWrapper> createState() => _NetworkOverlayWrapperState();
}

class _NetworkOverlayWrapperState extends State<NetworkOverlayWrapper> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isConnected = true;
  bool _showBanner = false;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }
    if (!mounted) return;
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final isOnline = !result.contains(ConnectivityResult.none);

    if (_isInit) {
      _isConnected = isOnline;
      _isInit = false;
      return;
    }

    if (isOnline != _isConnected) {
      setState(() {
        _isConnected = isOnline;
        _showBanner = true;
      });

      if (isOnline) {
        // Hide the "Back Online" banner after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showBanner = false;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner || !_isConnected)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SafeArea(
              child: AnimatedSlide(
                offset: (_showBanner || !_isConnected) ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: _isConnected ? Colors.green.shade800 : Colors.red.shade800,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          _isConnected ? LucideIcons.checkCircle2 : LucideIcons.wifiOff,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isConnected ? 'Back Online' : 'No Internet Connection',
                                style: AppTypography.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_isConnected) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Please check your internet connection.',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
