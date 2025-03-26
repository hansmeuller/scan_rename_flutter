import 'package:flutter/material.dart';
import 'logic.dart';

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
  String status = "Bereit"; // status
  bool isProcessing = false; // show verarbeitung

  void startProcessing() async {
    setState(() {
      isProcessing = true;
      status = "Verarbeitung gestartet ";
    });

    
    try {
      final currentFolder = Directory.current.path;
      await processPdfsWithProgress(
        currentFolder,
            (fileName) {
          setState(() {
            status = "Verarbeite: $fileName";
          });
        },
      );

      setState(() {
        status = "Verarbeitung abgeschlossen.";
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        status = "Fehler: $e";
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan & Rename"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isProcessing ? null : startProcessing,
              child: Text(isProcessing ? "In Bearbeitung..." : "Start"),
            ),
          ],
        ),
      ),
    );
  }
}

//todo
  //tests
  //gui

