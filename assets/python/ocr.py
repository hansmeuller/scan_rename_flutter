import sys
import easyocr

def perform_ocr(image_path):
    reader = easyocr.Reader(['de'], gpu=False)
    results = reader.readtext(image_path)
    for (bbox, text, prob) in results:
        print(f"{text} (Confidence: {prob:.2f})")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        perform_ocr(sys.argv[1])
    else:
        print("No image path provided.")



