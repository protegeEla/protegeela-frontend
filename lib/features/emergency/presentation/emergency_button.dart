import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import 'widgets/hold_feedback.dart';

enum EmergencyConfirmationAction { sendNow, cancel, silent, shareOnMap }

class EmergencyButton extends StatefulWidget {
  const EmergencyButton({
    super.key,
    required this.onConfirmed,
    this.enabled = true,
  });

  final Future<void> Function(
      {required bool isSilent, required bool publicVisibility}) onConfirmed;
  final bool enabled;

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with TickerProviderStateMixin {
  late final AnimationController _holdController;
  late final AnimationController _pulseController;
  bool _busy = false;
  bool _confirming = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
      duration: const Duration(
        seconds: AppConstants.emergencyHoldSeconds,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _confirm();
      });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _resumePulse() {
    if (widget.enabled && !_busy && !_reduceMotion) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _pulseController.stop();
      _pulseController.value = 0;
    } else if (!_holdController.isAnimating && !_confirming) {
      _resumePulse();
    }
  }

  void _start() {
    if (!widget.enabled ||
        _busy ||
        _confirming ||
        _holdController.isAnimating) {
      return;
    }
    HapticFeedback.mediumImpact();
    _pulseController.stop();
    _holdController.forward(from: 0);
  }

  void _cancelHold() {
    if (_confirming || _holdController.isCompleted) return;
    _holdController.stop();
    _holdController.value = 0;
    _resumePulse();
  }

  Future<void> _confirm() async {
    if (_busy || _confirming || !mounted) return;
    _confirming = true;
    HapticFeedback.heavyImpact();
    final action = await showDialog<EmergencyConfirmationAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const EmergencyConfirmationDialog(),
    );
    _confirming = false;
    if (!mounted) return;
    if (action == null || action == EmergencyConfirmationAction.cancel) {
      _holdController.value = 0;
      _resumePulse();
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onConfirmed(
        isSilent: action == EmergencyConfirmationAction.silent,
        publicVisibility: action == EmergencyConfirmationAction.shareOnMap,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _holdController.value = 0;
        _resumePulse();
      }
    }
  }

  @override
  void didUpdateWidget(covariant EmergencyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _pulseController.stop();
      _holdController.stop();
      _holdController.value = 0;
    } else if (!oldWidget.enabled && !_busy) {
      _resumePulse();
    }
  }

  @override
  void dispose() {
    _holdController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || _busy;
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label:
            'Pedir ajuda. Pressione e segure por ${AppConstants.emergencyHoldSeconds} segundos.',
        child: MouseRegion(
          cursor: disabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Focus(
            onKeyEvent: (_, event) {
              if (event.logicalKey != LogicalKeyboardKey.enter &&
                  event.logicalKey != LogicalKeyboardKey.space) {
                return KeyEventResult.ignored;
              }
              if (event is KeyDownEvent) _start();
              if (event is KeyUpEvent) _cancelHold();
              return KeyEventResult.handled;
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _start(),
              onPointerUp: (_) => _cancelHold(),
              onPointerCancel: (_) => _cancelHold(),
              child: AnimatedBuilder(
                animation: _holdController,
                builder: (context, _) {
                  final hold = _holdController.value;
                  final secondsLeft = math.max(
                    1,
                    (AppConstants.emergencyHoldSeconds * (1 - hold)).ceil(),
                  );
                  return SizedBox.square(
                    dimension: 264,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_reduceMotion)
                          Positioned.fill(
                              child: IgnorePointer(
                                  child: CustomPaint(
                            painter: HoldFeedback(_holdController),
                          ))),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) => Transform.scale(
                            scale: 1 +
                                (disabled ? 0 : _pulseController.value * 0.09),
                            child: child,
                          ),
                          child: Container(
                            width: 238,
                            height: 238,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    AppColors.emergency.withValues(alpha: 0.07),
                                width: 12,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 238,
                          height: 238,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFE1DF),
                              width: 8,
                            ),
                          ),
                        ),
                        SizedBox.square(
                          dimension: 238,
                          child: CircularProgressIndicator(
                            value: hold,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            color: disabled
                                ? Colors.grey.shade400
                                : AppColors.emergency,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        Transform.scale(
                          scale: _reduceMotion
                              ? 1
                              : (1 - (hold * 0.025)) +
                                  (_hovered ? 0.012 : 0) +
                                  (hold > 0
                                      ? math.sin(hold * math.pi * 16) * 0.018
                                      : 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            width: 204,
                            height: 204,
                            decoration: BoxDecoration(
                              gradient: disabled
                                  ? LinearGradient(
                                      colors: [
                                        Colors.grey.shade500,
                                        Colors.grey.shade600,
                                      ],
                                    )
                                  : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFF1453D),
                                        Color(0xFFE42D22),
                                      ],
                                    ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 6),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: _hovered ? 34 : 26,
                                  spreadRadius: _hovered ? 3 : 1,
                                  color: const Color(0x38E42D22),
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                      height: 46,
                                      child: AnimatedSwitcher(
                                        duration: Duration(
                                            milliseconds:
                                                _reduceMotion ? 0 : 160),
                                        transitionBuilder: (child, animation) =>
                                            ScaleTransition(
                                                scale: animation,
                                                child: FadeTransition(
                                                    opacity: animation,
                                                    child: child)),
                                        child: hold > 0 && !_busy
                                            ? Text('$secondsLeft',
                                                key: ValueKey(secondsLeft),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 40,
                                                    height: 1,
                                                    fontWeight:
                                                        FontWeight.w900))
                                            : const Icon(
                                                Icons
                                                    .volunteer_activism_rounded,
                                                key: ValueKey('heart'),
                                                color: Colors.white,
                                                size: 41),
                                      )),
                                  const SizedBox(height: 7),
                                  Text(
                                    _busy ? 'ENVIANDO...' : 'PEDIR AJUDA',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  AnimatedSwitcher(
                                    duration: Duration(
                                        milliseconds: _reduceMotion ? 0 : 140),
                                    child: Text(
                                      _busy
                                          ? 'Aguardando confirmação'
                                          : hold > 0
                                              ? 'Continue segurando\nSolte para cancelar'
                                              : 'Pressione e segure por ${AppConstants.emergencyHoldSeconds} segundos',
                                      key: ValueKey(_busy
                                          ? 'sending'
                                          : hold > 0
                                              ? 'holding'
                                              : 'idle'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmergencyConfirmationDialog extends StatefulWidget {
  const EmergencyConfirmationDialog({super.key});

  @override
  State<EmergencyConfirmationDialog> createState() =>
      _EmergencyConfirmationDialogState();
}

class _EmergencyConfirmationDialogState
    extends State<EmergencyConfirmationDialog> {
  Timer? _timer;
  int _remaining = AppConstants.confirmationSeconds;
  bool _shareOnMap = false;

  void _send() => Navigator.of(context).pop(_shareOnMap
      ? EmergencyConfirmationAction.shareOnMap
      : EmergencyConfirmationAction.sendNow);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        _send();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.shield_outlined,
        color: AppColors.emergency,
        size: 36,
      ),
      title: Text('Enviar alerta em $_remaining s'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
            'O alerta será registrado no servidor ao terminar a contagem. Nenhum SMS, WhatsApp ou push será enviado aos contatos nesta versão.',
            textAlign: TextAlign.center),
        CheckboxListTile(
          value: _shareOnMap,
          onChanged: (value) => setState(() => _shareOnMap = value ?? false),
          title: const Text('Mostrar região aproximada no mapa compartilhado'),
          subtitle: const Text(
              'Sem nome ou coordenadas exatas. O modo silencioso mantém o alerta privado.'),
          contentPadding: EdgeInsets.zero,
        ),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(EmergencyConfirmationAction.cancel),
          child: const Text('Cancelar'),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop(EmergencyConfirmationAction.silent),
          child: const Text('Ativar silenciosamente'),
        ),
        FilledButton(
          onPressed: _send,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.emergency,
          ),
          child: const Text('Enviar agora'),
        ),
      ],
    );
  }
}
