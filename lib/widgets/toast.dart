import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class ToastMessage {
  final String id;
  final String text;
  final ToastType type;
  ToastMessage(this.id, this.text, this.type);
}

class ToastService {
  static final ValueNotifier<List<ToastMessage>> _messages =
      ValueNotifier<List<ToastMessage>>(<ToastMessage>[]);

  static void show(
    String text, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final msg = ToastMessage(id, text, type);
    final list = List<ToastMessage>.from(_messages.value)..add(msg);
    _messages.value = list;
    Timer(duration, () => dismiss(id));
  }

  static void success(String text) => show(text, type: ToastType.success);
  static void error(String text) => show(text, type: ToastType.error);
  static void info(String text) => show(text, type: ToastType.info);
  static void warning(String text) => show(text, type: ToastType.warning);

  static void dismiss(String id) {
    final list = List<ToastMessage>.from(_messages.value)
      ..removeWhere((m) => m.id == id);
    _messages.value = list;
  }
}

class Toaster extends StatelessWidget {
  const Toaster({super.key});

  Color _bg(ToastType t) {
    switch (t) {
      case ToastType.success:
        return const Color(0xFF16A34A); // green-600
      case ToastType.error:
        return const Color(0xFFDC2626); // red-600
      case ToastType.warning:
        return const Color(0xFFF59E0B); // amber-500
      case ToastType.info:
      default:
        return const Color(0xFF2563EB); // blue-600
    }
  }

  IconData _icon(ToastType t) {
    switch (t) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ValueListenableBuilder<List<ToastMessage>>(
              valueListenable: ToastService._messages,
              builder: (context, items, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final m in items)
                      _ToastChip(
                        message: m,
                        color: _bg(m.type),
                        icon: _icon(m.type),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastChip extends StatefulWidget {
  final ToastMessage message;
  final Color color;
  final IconData icon;
  const _ToastChip({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  State<_ToastChip> createState() => _ToastChipState();
}

class _ToastChipState extends State<_ToastChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut)),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _ac, curve: Curves.easeOut),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => ToastService.dismiss(widget.message.id),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
