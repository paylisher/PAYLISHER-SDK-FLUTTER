import 'package:flutter/foundation.dart';
import 'paylisher_survey_question_type.dart';
import 'paylisher_display_survey_question.dart';

/// Link question type
@immutable
class PaylisherDisplayLinkQuestion extends PaylisherDisplaySurveyQuestion {
  const PaylisherDisplayLinkQuestion({
    required super.id,
    required super.question,
    required this.link,
    super.description,
    super.descriptionContentType,
    super.optional,
    super.buttonText,
  }) : super(
          type: PaylisherSurveyQuestionType.link,
        );

  final String link;
}
