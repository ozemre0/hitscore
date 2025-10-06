import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../screens/onboarding_screen.dart';

class StartGate extends StatefulWidget {
  final Widget child;
  const StartGate({super.key, required this.child});

  @override
  State<StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<StartGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final done = await OnboardingService.isCompleted();
    if (!mounted) return;
    if (!done) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        if (mounted) setState(() => _checked = true);
      });
    } else {
      setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}


