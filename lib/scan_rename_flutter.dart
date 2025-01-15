import 'dart:io';
import 'package:pdf_render/pdf_render.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
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

// Keywords
const List<String> aktenzeichenKeywords = ["Bitte bei"];
const List<String> ausschlussListe = ["Postfach", "PLZ", "Postzentrum"];

// logging
void logMessage(String message) {
  final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  final logFile = File('Logeinträge.txt');
  logFile.writeAsStringSync('$timestamp - $message\n', mode: FileMode.append);
}

// temp PNG löschen
void deleteTempPng(String filePath) {
  final file = File(filePath);
  if (file.existsSync()) {
    file.deleteSync();
    logMessage('Temporäre Datei gelöscht: $filePath');
  }
}

// max zwischen Wörtern
String normalizeSpacing(String text) {
  return text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

// text aus fenster
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

    final ocrResult = await TesseractOcr.extractText(tempPngPath);
    deleteTempPng(tempPngPath);

    logMessage('OCR-Ergebnisse im Fenster: $ocrResult');
    return ocrResult.split('\n');
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
    final lineText = normalizeSpacing(results[idx]);

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

// pdf verarbeiten
Future<void> processPdf(String filePath) async {
  try {
    final fileName = path.basename(filePath);
    final document = await PdfDocument.openFile(filePath);
    final page = await document.getPage(1);
    final image = await page.render();

    final senderResults = await extractTextFromWindow(image!, 300, fileName, windowTopCm, windowHeightCm);
    final sender = extractSender(senderResults);
    logMessage('Gefundener Absender in $filePath: $sender');

    final subjectOrCase = extractCaseNumber(senderResults);
    logMessage('Gefundener Betreff oder Aktenzeichen in $filePath: ${subjectOrCase ?? "Kein relevanter Eintrag gefunden"}');
  } catch (e) {
    logMessage('Fehler bei der Verarbeitung von $filePath: $e');
  }
}

// current Ordner verarbeiten
void processPdfs(String folder) {
  final dir = Directory(folder);
  for (var file in dir.listSync()) {
    if (file.path.endsWith('.pdf')) {
      logMessage('Starte Verarbeitung für Datei: ${file.path}');
      processPdf(file.path);
    }
  }
}


void main() {
  final currentFolder = Directory.current.path;
  processPdfs(currentFolder);
}
