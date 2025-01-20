import 'package:flutter/material.dart';
import 'logic.dart';

void main() {
  runApp(const ScanRenameApp());
}

void main() {
  runApp(const ScanRenameApp());
}

class ScanRenameApp extends StatelessWidget {
  const ScanRenameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const ScanRenameScreen(),
    );
  }
}