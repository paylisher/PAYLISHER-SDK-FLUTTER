import 'paylisher_display_survey.dart';

/// Called when a survey is shown to the user
typedef OnSurveyShown = void Function(PaylisherDisplaySurvey survey);

/// Called when a user responds to a survey question
typedef OnSurveyResponse = Future<PaylisherSurveyNextQuestion> Function(
  PaylisherDisplaySurvey survey,
  int questionIndex,
  Object? response,
);

/// Called when a survey is closed
typedef OnSurveyClosed = void Function(PaylisherDisplaySurvey survey);

/// Represents the next question to show in a survey
class PaylisherSurveyNextQuestion {
  const PaylisherSurveyNextQuestion({
    required this.questionIndex,
    required this.isSurveyCompleted,
  });

  final int questionIndex;
  final bool isSurveyCompleted;
}
