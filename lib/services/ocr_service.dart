import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import '../utils/expiry_parser.dart';

class OcrService {
  final textRecognizer = GoogleMlKit.vision.textRecognizer();

  Future<String?> extractExpiryDate(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await textRecognizer.processImage(inputImage);
    final text = recognizedText.text;
    final expiryDate = ExpiryParser.parse(text);
    if (expiryDate != null) {
      return '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';
    }
    return null;
  }

  Future<String> extractAllText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  void dispose() {
    textRecognizer.close();
  }
}
