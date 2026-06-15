import 'dart:math';
import 'package:flutter/material.dart';

class EqualizerBars extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final int barCount;
  final double width;
  final double height;

  const EqualizerBars({
    super.key,
    required this.isPlaying,
    this.color = const Color(0xFFA855F7),
    this.barCount = 4,
    this.width = 24,
    this.height = 18,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + _random.nextInt(400)),
      );
    });

    _animations = _controllers.map((ctrl) {
      return Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isPlaying) _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  void _stopAnimations() {
    for (final ctrl in _controllers) {
      ctrl.animateTo(0.15);
    }
  }

  @override
  void didUpdateWidget(EqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barW = widget.width / widget.barCount - 2;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) {
              return Container(
                width: barW,
                height: widget.height * _animations[i].value,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(barW / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
