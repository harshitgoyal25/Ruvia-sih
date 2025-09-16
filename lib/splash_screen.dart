import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final bool showLoadingBar;
  const SplashScreen({super.key, this.showLoadingBar = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<Offset> _slideInAnimation;
  late Animation<Offset> _slideOutAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideInAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _fadeOutAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );
    _slideOutAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.12)).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.7, 1.0, curve: Curves.easeInCubic),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 14, 14, 15),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double opacity = 1.0;
            Offset offset = Offset.zero;
            if (_controller.value <= 0.7) {
              opacity = _fadeInAnimation.value;
              offset = _slideInAnimation.value;
            } else {
              opacity = 1 - _fadeOutAnimation.value;
              offset = _slideOutAnimation.value;
            }
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(
                  0,
                  offset.dy * MediaQuery.of(context).size.height,
                ),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 28),
              Text(
                'Ruvia',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  fontSize: 38,
                  letterSpacing: 2,
                  color: const Color(0xFF79c339),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Run. Compete. Win.',
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 38),
              // Only show bar while loading (during splash period)
              if (widget.showLoadingBar)
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    color: const Color(0xFF79c339),
                    backgroundColor: Colors.white12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
