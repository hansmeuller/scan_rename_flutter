Future<void> processPdfsWithProgress(String folder, Function(String) onProgress) async {
  final dir = Directory(folder);
  for (var file in dir.listSync()) {
    if (file.path.endsWith('.pdf')) {
      onProgress(file.path); // Fortschrittsmeldung
      await processPdf(file.path);
    }
  }
}

