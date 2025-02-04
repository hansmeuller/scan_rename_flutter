import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<void> setupPythonEnvironment() async {
  final appDir = await getApplicationDocumentsDirectory();
  final pythonDir = Directory('${appDir.path}/python');

  if (!pythonDir.existsSync()) {
    pythonDir.createSync(recursive: true);

    // extrahiere
    final ocrScript = await rootBundle.loadString('assets/python/ocr.py');
    final ocrFile = File('${pythonDir.path}/ocr.py');
    await ocrFile.writeAsString(ocrScript);

    print('Python-Skript wurde bereitgestellt: ${ocrFile.path}');
  }
}

Future<String> performOcr(String imagePath) async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final pythonDir = Directory('${appDir.path}/python');
    final ocrScriptPath = '${pythonDir.path}/ocr.py';

    // python ausführen
    final result = await Process.run(
      'python3',
      [ocrScriptPath, imagePath],
    );

    if (result.exitCode == 0) {
      return result.stdout;
    } else {
      throw Exception('OCR-Fehler: ${result.stderr}');
    }
  } catch (e) {
    throw Exception('Fehler bei der OCR-Ausführung: $e');
  }
}

Future<void> prepareDependencies() async {
  await setupPythonEnvironment();
}
