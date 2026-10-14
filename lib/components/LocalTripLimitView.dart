import 'package:flutter/material.dart';

class LocalTripLimitView extends StatelessWidget {
  final VoidCallback onOutstation;
  final VoidCallback onChangeDrop;

  const LocalTripLimitView({super.key, required this.onOutstation, required this.onChangeDrop});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.directions_car_outlined, size: 64, color: red),
        const SizedBox(height: 24),
        const Text('Book Outstation Instead', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Text('Selected location is out of the city limit. Book with outstation instead.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: red, side: const BorderSide(color: red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: onOutstation, child: const Text('Continue as Outstation', textAlign: TextAlign.center))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: red, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: onChangeDrop, child: const Text('Change Drop'))),
      ]),
    );
  }
}
