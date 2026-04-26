import 'package:flutter/material.dart';

class RiskBadge extends StatefulWidget {
  const RiskBadge({required this.riskLevel, super.key});

  final String riskLevel;

  @override
  State<RiskBadge> createState() => _RiskBadgeState();
}

class _RiskBadgeState extends State<RiskBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _pulse = Tween<double>(
    begin: 1,
    end: 1.08,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  bool get _isCritical => widget.riskLevel.toLowerCase() == 'critical';

  @override
  void initState() {
    super.initState();
    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant RiskBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riskLevel != widget.riskLevel) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (_isCritical) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget chip = Chip(
      avatar: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      label: Text(
        widget.riskLevel,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      side: BorderSide.none,
      backgroundColor: _riskColor(widget.riskLevel),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );

    if (_isCritical) {
      return ScaleTransition(scale: _pulse, child: chip);
    }

    return chip;
  }

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return const Color(0xFF8B0000);
      default:
        return Colors.blueGrey;
    }
  }
}
