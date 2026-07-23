import 'package:flutter/material.dart';

/// Temporary placeholder used for screens not yet built.
/// Replaced screen by screen as development progresses.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: Color(0xFF1E90FF)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Coming soon',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
          ],
        ),
      ),
    );
  }
}
