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
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedSlide(
                offset: (_showBanner || !_isConnected) ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: Material(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: _isConnected ? Colors.green.shade600 : Colors.red.shade600,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isConnected ? LucideIcons.wifi : LucideIcons.wifiOff,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected ? 'Back Online' : 'No Internet Connection',
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
