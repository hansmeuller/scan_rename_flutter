import 'dart:io';
import 'package:pdf_render/pdf_render.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

// scanbereich
const double windowLeftCm = 2.0;
const double windowTopCm = 4.5;
const double windowWidthCm = 9.0;
const double windowHeightCm = 4.5;

const double knickfalteTopCm = 10.0;
const double knickfalteHeightCm = 2.0;

// Keywords
const List<String> aktenzeichenKeywords = ["Bitte bei"];
const List<String> ausschlussListe = ["Postfach", "PLZ", "Postzentrum"];
const Map<String, String> ocrCorrections = {"unaedeckte": "ungedeckte"};

// log
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

// max Leerzeichen
String normalizeSpacing(String text) {
  return text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

// check kto
bool isKontoauszug(PdfPageImage image) {
  return image.height < 1500;
}

// unicorn generieren
String getUniqueFilename(String filePath) {
  var base = path.withoutExtension(filePath);
  var ext = path.extension(filePath);
  var counter = 1;
  var newPath = filePath;
  while (File(newPath).existsSync()) {
    newPath = "$base ($counter)$ext";
    counter++;
  }
  return newPath;
}

// aus fenster extrahieren
Future<List<String>> extractTextFromWindow(Uint8List imageBytes, double dpi, String fileName, double topCm, double heightCm) async {
  try {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      logMessage('Fehler beim Dekodieren des Bildes');
      return [];
    }
    final pixelsPerCm = dpi / 2.54;
    final left = (windowLeftCm * pixelsPerCm).toInt();
    final right = ((windowLeftCm + windowWidthCm) * pixelsPerCm).toInt();
    final top = (topCm * pixelsPerCm).toInt();
    final bottom = ((topCm + heightCm) * pixelsPerCm).toInt();

    final croppedImage = img.copyCrop(image, left, top, right - left, bottom - top);
    final tempPngPath = '$fileName_window_preview.png';
    File(tempPngPath).writeAsBytesSync(img.encodePng(croppedImage));
    logMessage('Fensterbereich gespeichert: $tempPngPath');

    final result = await Process.run('python', ['assets/python/ocr.py', tempPngPath]);
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

// verarbeiten
Future<void> processPdf(String filePath) async {
  try {
    final fileName = path.basename(filePath);
    final document = await PdfDocument.openFile(filePath);
    final page = await document.getPage(1);
    final image = await page.render();
    final imageBytes = image?.bytes;

    if (imageBytes == null) {
      logMessage('Fehler beim Rendern der PDF-Seite');
      return;
    }

    if (isKontoauszug(image!)) {
      logMessage('Dokument erkannt als Kontoauszug: $filePath');
      logMessage('Betreff: Kontoauszug');
      return;
    }

    final senderResults = await extractTextFromWindow(imageBytes, 300, fileName, windowTopCm, windowHeightCm);
    final sender = senderResults.isNotEmpty ? senderResults.first : "Unbekannter Absender";
    logMessage('Gefundener Absender in $filePath: $sender');

    final caseNumberResults = await extractTextFromWindow(imageBytes, 300, fileName, knickfalteTopCm, knickfalteHeightCm);
    final subjectOrCase = caseNumberResults.isNotEmpty ? caseNumberResults.first : "Kein Eintrag gefunden";
    logMessage('Gefundener Betreff oder Aktenzeichen in $filePath: $subjectOrCase');

    final newFileName = normalizeSpacing('$sender_$subjectOrCase.pdf').replaceAll('__', '_');
    final newFilePath = getUniqueFilename(path.join(path.dirname(filePath), newFileName));
    File(filePath).renameSync(newFilePath);
    logMessage('Datei umbenannt: $filePath -> $newFilePath');
  } catch (e) {
    logMessage('Fehler bei der Verarbeitung von $filePath: $e');
  }
}

// PDFs im Ordner verarbeiten
void processPdfs(String folder) {
  final dir = Directory(folder);
  for (var file in dir.listSync()) {
    if (file.path.endsWith('.pdf')) {
      logMessage('Starte Verarbeitung für Datei: ${file.path}');
      processPdf(file.path);
    }
  }
}

// Hauptprogramm
void main() {
  final currentFolder = Directory.current.path;
  processPdfs(currentFolder);
}
