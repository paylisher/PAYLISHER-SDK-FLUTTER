import 'package:flutter/foundation.dart';
import 'paylisher_survey_question_type.dart';
import 'paylisher_display_survey_question.dart';

/// Open text question type
@immutable
class PaylisherDisplayOpenQuestion extends PaylisherDisplaySurveyQuestion {
  const PaylisherDisplayOpenQuestion({
    required super.id,
    required super.question,
    super.description,
    super.descriptionContentType,
    super.optional,
    super.buttonText,
  }) : super(
          type: PaylisherSurveyQuestionType.openText,
        );
}
