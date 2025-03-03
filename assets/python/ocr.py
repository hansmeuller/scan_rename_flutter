import sys
import os
import easyocr
from pdf2image import convert_from_path
from PyPDF2 import PdfReader

# initialisieren
reader = easyocr.Reader(['de'], gpu=False)

# Log-Funktion
def log_message(message):
    print(message)  # Später durch Datei-Logging ersetzen

# umwandeln und verarbeiten
def process_pdf(pdf_path):
    try:
        images = convert_from_path(pdf_path, dpi=300)
        if not images:
            log_message(f"Keine Bilder extrahiert für {pdf_path}")
            return

        for i, image in enumerate(images):
            text_results = reader.readtext(image)
            extracted_text = " ".join([text for _, text, _ in text_results])

            log_message(f"OCR-Ergebnisse für {pdf_path} - Seite {i+1}: {extracted_text}")

    except Exception as e:
        log_message(f"Fehler bei der Verarbeitung von {pdf_path}: {e}")

# im Ordner verarbeiten
def process_pdfs(folder_path):
    for file_name in os.listdir(folder_path):
        if file_name.lower().endswith(".pdf"):
            pdf_path = os.path.join(folder_path, file_name)
            process_pdf(pdf_path)

# start
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Bitte einen Ordner oder eine PDF-Datei angeben.")
        sys.exit(1)

    input_path = sys.argv[1]

    if os.path.isdir(input_path):
        process_pdfs(input_path)
    elif os.path.isfile(input_path) and input_path.lower().endswith(".pdf"):
        process_pdf(input_path)
    else:
        print("Ungültiger Pfad oder keine PDF-Datei.")
