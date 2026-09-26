import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestAmbulanceButton extends StatelessWidget {
  const RequestAmbulanceButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const Key('requestAmbulanceButton'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFD92D2D),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(20),
        minimumSize: const Size.fromHeight(108),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0x26FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_share_rounded, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REQUEST_AMBULANCE'.tr,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  'IMMEDIATE_ASSISTANCE'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 22),
        ],
      ),
    );
  }
}
