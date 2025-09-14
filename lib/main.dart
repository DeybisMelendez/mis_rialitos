import 'package:flutter/material.dart';

void main() {
  runApp(const MisRialitosApp());
}

class MisRialitosApp extends StatelessWidget {
  const MisRialitosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
