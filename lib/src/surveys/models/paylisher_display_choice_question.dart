import 'package:flutter/foundation.dart';
import 'paylisher_survey_question_type.dart';
import 'paylisher_display_survey_question.dart';

/// choice question type
@immutable
class PaylisherDisplayChoiceQuestion extends PaylisherDisplaySurveyQuestion {
  const PaylisherDisplayChoiceQuestion({
    required super.id,
    required super.question,
    required this.choices,
    required this.isMultipleChoice,
    this.hasOpenChoice = false,
    this.shuffleOptions = false,
    super.description,
    super.descriptionContentType,
    super.optional,
    super.buttonText,
  }) : super(
          type: isMultipleChoice
              ? PaylisherSurveyQuestionType.multipleChoice
              : PaylisherSurveyQuestionType.singleChoice,
        );

  final List<String> choices;
  final bool isMultipleChoice;
  final bool hasOpenChoice;
  final bool shuffleOptions;
}
