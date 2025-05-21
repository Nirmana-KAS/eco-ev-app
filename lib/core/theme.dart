import 'package:flutter/material.dart';

class WelcomeText extends StatelessWidget {
  const WelcomeText({super.key}); // <-- Add this constructor

  @override
  Widget build(BuildContext context) {
    return Text(
      "Welcome to ECO EV!",
      style: Theme.of(context).textTheme.displayLarge,
    );
  }
}
