import 'package:flutter/foundation.dart';
import 'paylisher_survey_question_type.dart';
import 'paylisher_display_survey_text_content_type.dart';

/// Base class for all survey questions
@immutable
abstract class PaylisherDisplaySurveyQuestion {
  const PaylisherDisplaySurveyQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.description,
    this.descriptionContentType = PaylisherDisplaySurveyTextContentType.text,
    this.optional = false,
    this.buttonText,
  });

  final String id;
  final PaylisherSurveyQuestionType type;
  final String question;
  final String? description;
  final PaylisherDisplaySurveyTextContentType descriptionContentType;
  final bool optional;
  final String? buttonText;
}
