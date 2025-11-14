import 'package:flutter/foundation.dart';
import 'paylisher_survey_question_type.dart';
import 'paylisher_display_survey_question.dart';
import 'paylisher_display_survey_rating_type.dart';

/// Rating question type
@immutable
class PaylisherDisplayRatingQuestion extends PaylisherDisplaySurveyQuestion {
  const PaylisherDisplayRatingQuestion({
    required super.id,
    required super.question,
    required this.ratingType,
    required this.scaleLowerBound,
    required this.scaleUpperBound,
    required this.lowerBoundLabel,
    required this.upperBoundLabel,
    super.description,
    super.descriptionContentType,
    super.optional,
    super.buttonText,
  }) : super(
          type: PaylisherSurveyQuestionType.rating,
        );

  final PaylisherDisplaySurveyRatingType ratingType;
  final int scaleLowerBound;
  final int scaleUpperBound;
  final String lowerBoundLabel;
  final String upperBoundLabel;
}
