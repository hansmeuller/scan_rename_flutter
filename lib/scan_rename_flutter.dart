import 'dart:io';
import 'package:pdf_render/pdf_render.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'dart:async';

// scanbereiche
const double windowLeftCm = 2.0;
const double windowTopCm = 4.5;
const double windowWidthCm = 9.0;
const double windowHeightCm = 4.5;

const double knickfalteTopCm = 10.0;
const double knickfalteHeightCm = 2.0;

// keywords
const List<String> aktenzeichenKeywords = ["Bitte bei"];
const List<String> ausschlussListe = ["Postfach", "PLZ", "Postzentrum"];
const Map<String, String> ocrCorrections = {"unaedeckte": "ungedeckte"};

// log func
void logMessage(String message) {
  final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  final logFile = File('Logeinträge.txt');
  logFile.writeAsStringSync('$timestamp - $message\n', mode: FileMode.append);
}

// temp löschen
void deleteTempPng(String filePath) {
  final file = File(filePath);
  if (file.existsSync()) {
    file.deleteSync();
    logMessage('Temporäre Datei gelöscht: $filePath');
  }
}

// rule
String normalizeSpacing(String text) {
  return text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

// auf kto prüfen
bool isKontoauszug(PdfPageImage image) {
  return image.height < 1500; // Bedingung für Kontoauszug
}

// text extrahieren
Future<List<String>> extractTextFromWindow(PdfPageImage image, double dpi, String fileName, double topCm, double heightCm) async {
  try {
    final pixelsPerCm = dpi / 2.54;
    final left = (windowLeftCm * pixelsPerCm).toInt();
    final right = ((windowLeftCm + windowWidthCm) * pixelsPerCm).toInt();
    final top = (topCm * pixelsPerCm).toInt();
    final bottom = ((topCm + heightCm) * pixelsPerCm).toInt();

    final croppedImage = image.subImage(Rect.fromLTWH(left.toDouble(), top.toDouble(), (right - left).toDouble(), (bottom - top).toDouble()));
    final tempPngPath = '$fileName_window_preview.png';

    final tempFile = File(tempPngPath);
    await tempFile.writeAsBytes(croppedImage.bytes);
    logMessage('Fensterbereich gespeichert: $tempPngPath');

    final result = await Process.run('python3', ['-m', 'easyocr', tempPngPath]);
    deleteTempPng(tempPngPath);

    if (result.exitCode == 0) {
      logMessage('OCR-Ergebnisse im Fenster: ${result.stdout}');
      return result.stdout.toString().split('\n');
    } else {
      logMessage('Fehler bei der Textauswertung: ${result.stderr}');
      return [];
    }
  } catch (e) {
    logMessage('Fehler bei der Textauswertung: $e');
    return [];
  }
}

// abs extrahieren
String extractSender(List<String> results) {
  if (results.isNotEmpty) {
    var firstLine = results.first;
    for (var exclusion in ausschlussListe) {
      firstLine = firstLine.replaceAll(exclusion, '');
    }
    firstLine = normalizeSpacing(firstLine);
    return 'Absender: $firstLine';
  }
  return 'Kein Absender gefunden';
}

// az extrahieren
String? extractCaseNumber(List<String> results) {
  for (var idx = 0; idx < results.length; idx++) {
    var lineText = normalizeSpacing(results[idx]);

    for (var correction in ocrCorrections.entries) {
      lineText = lineText.replaceAll(correction.key, correction.value);
    }

    if (aktenzeichenKeywords.any((keyword) => lineText.startsWith(keyword))) {
      logMessage('Keyword für Aktenzeichen gefunden: $lineText');

      if (idx + 3 < results.length) {
        final aktenzeichenLine = normalizeSpacing(results[idx + 3]);
        return aktenzeichenLine.substring(0, 13);
      }
    }
  }
  return null;
}

// woerk
Future<void> processPdf(String filePath) async {
  try {
    final fileName = path.basename(filePath);
    final document = await PdfDocument.openFile(filePath);
    final page = await document.getPage(1);
    final image = await page.render();

    if (isKontoauszug(image!)) {
      logMessage('Dokument erkannt als Kontoauszug: $filePath');
      logMessage('Betreff: Kontoauszug');
      return;
    }

    final senderResults = await extractTextFromWindow(image, 300, fileName, windowTopCm, windowHeightCm);
    final sender = extractSender(senderResults);
    logMessage('Gefundener Absender in $filePath: $sender');

    final subjectOrCase = extractCaseNumber(senderResults);
    logMessage('Gefundener Betreff oder Aktenzeichen in $filePath: ${subjectOrCase ?? "Kein relevanter Eintrag gefunden"}');
  } catch (e) {
    logMessage('Fehler bei der Verarbeitung von $filePath: $e');
  }
}

// pdf verarbeiten
void processPdfs(String folder) {
  final dir = Directory(folder);
  for (var file in dir.listSync()) {
    if (file.path.endsWith('.pdf')) {
      logMessage('Starte Verarbeitung für Datei: ${file.path}');
      processPdf(file.path);
    }
  }
}

// eintritt
void main() {
  final currentFolder = Directory.current.path;
  processPdfs(currentFolder);
}
