import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp()); // Use const
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Use super parameter shorthand

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco EV App',
      home: Scaffold(
        appBar: AppBar(title: Text('Eco EV App')),
        body: Center(child: Text('Hello, world!')),
      ),
    );
  }
}
