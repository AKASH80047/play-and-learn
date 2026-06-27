import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../../domain/repositories/image_recognition_repository.dart';

class ImageRecognitionRepositoryImpl implements ImageRecognitionRepository {
  ImageLabeler? _imageLabeler;

  ImageLabeler _getLabeler() {
    return _imageLabeler ??= ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );
  }

  @override
  Future<List<String>> labelImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labeler = _getLabeler();
      final labels = await labeler.processImage(inputImage);
      
      // Map labels to clean lowercase tags for validation matching
      return labels.map((e) => e.label.toLowerCase()).toList();
    } catch (e) {
      // Return empty list on failure, allowing screen fallbacks or simulator tests
      debugPrint('ML Kit classification exception: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _imageLabeler?.close();
    _imageLabeler = null;
  }
}
