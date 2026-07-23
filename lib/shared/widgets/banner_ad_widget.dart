import 'package:flutter/material.dart';

/// Placeholder banner ad widget displayed above the bottom navigation bar.
/// In a future release this will integrate with a real ad network SDK.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Centred content ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 16,
                color: Color(0xFFAAAAAA),
              ),
              const SizedBox(width: 6),
              Text(
                'Financial Services Ad',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),

          // ── 'Ad' badge – top-right corner ────────────────────────────────
          Positioned(
            top: 4,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Ad',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF888888),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
