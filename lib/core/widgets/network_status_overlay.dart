import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../services/network_status_service.dart';

class NetworkStatusOverlay extends ConsumerStatefulWidget {
  const NetworkStatusOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NetworkStatusOverlay> createState() =>
      _NetworkStatusOverlayState();
}

class _NetworkStatusOverlayState extends ConsumerState<NetworkStatusOverlay> {
  Timer? _hideTimer;
  bool _showRestored = false;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(networkStatusProvider, (previous, next) {
      if (previous?.valueOrNull == false && next.valueOrNull == true) {
        _hideTimer?.cancel();
        if (mounted) setState(() => _showRestored = true);
        _hideTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showRestored = false);
        });
      }
    });
    final online = ref.watch(networkStatusProvider).valueOrNull ?? true;

    return Stack(
      children: [
        widget.child,
        if (!online || _showRestored)
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Center(
                child: Semantics(
                  liveRegion: true,
                  child: Material(
                    color: online ? AppColors.safe : AppColors.emergency,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            online
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_off_outlined,
                            color: Colors.white,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              online
                                  ? 'Conexão restabelecida.'
                                  : 'Sem internet. Ações pendentes serão sincronizadas quando a conexão voltar.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
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
