abstract class ImageRecognitionRepository {
  /// Labels the image at [imagePath] and returns a list of matching tags/labels.
  Future<List<String>> labelImage(String imagePath);

  /// Releases resources.
  void dispose();
}
