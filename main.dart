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

class ScanRenameScreen extends StatefulWidget {
  const ScanRenameScreen({Key? key}) : super(key: key);

  @override
  _ScanRenameScreenState createState() => _ScanRenameScreenState();
}

class _ScanRenameScreenState extends State<ScanRenameScreen> {
  String status = "Bereit"; // Initiale Statusmeldung
  bool isProcessing = false; // Flag für die Verarbeitung


