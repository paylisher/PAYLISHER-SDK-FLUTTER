/// Content type for text-based survey elements
enum PaylisherDisplaySurveyTextContentType {
  /// Content should be rendered as HTML
  html(0),

  /// Content should be rendered as plain text
  text(1);

  const PaylisherDisplaySurveyTextContentType(this.value);

  final int value;

  /// Create from raw int value
  static PaylisherDisplaySurveyTextContentType fromInt(int value) {
    return PaylisherDisplaySurveyTextContentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () =>
          PaylisherDisplaySurveyTextContentType.text, // Default to text
    );
  }
}
