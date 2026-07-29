import 'package:flutter/material.dart';
import 'package:tunefy/theme/tunefy_colors.dart';

enum ToastIcon { check, download, heart, queue, library, radio, share, remove }

class TunefyToast {
  static void show(BuildContext context, String message, {ToastIcon icon = ToastIcon.check, Duration duration = const Duration(seconds: 2)}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TunefyToastWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _TunefyToastWidget extends StatefulWidget {
  final String message;
  final ToastIcon icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TunefyToastWidget({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TunefyToastWidget> createState() => _TunefyToastWidgetState();
}

class _TunefyToastWidgetState extends State<_TunefyToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    Future.delayed(widget.duration, () {
      _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _iconData() {
    switch (widget.icon) {
      case ToastIcon.check: return Icons.check_circle;
      case ToastIcon.download: return Icons.download;
      case ToastIcon.heart: return Icons.favorite;
      case ToastIcon.queue: return Icons.queue_music;
      case ToastIcon.library: return Icons.library_music;
      case ToastIcon.radio: return Icons.radio;
      case ToastIcon.share: return Icons.share;
      case ToastIcon.remove: return Icons.remove_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 12;
    return Positioned(
      top: 0, left: 20, right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            margin: EdgeInsets.only(top: top),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: TunefyColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: TunefyColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconData(), color: TunefyColors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.message,
                  style: const TextStyle(fontFamily: 'AM', fontSize: 14, color: TunefyColors.white),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
