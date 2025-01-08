import 'package:flutter/material.dart';

class MyCard extends StatelessWidget {
  const MyCard({super.key, required Column child});

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 4,
    );
  }
}