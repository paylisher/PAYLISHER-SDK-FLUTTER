/// Rating type for survey questions
enum PaylisherDisplaySurveyRatingType {
  number(0),
  emoji(1);

  const PaylisherDisplaySurveyRatingType(this.value);
  final int value;

  static PaylisherDisplaySurveyRatingType fromInt(int type) {
    return PaylisherDisplaySurveyRatingType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => PaylisherDisplaySurveyRatingType.number,
    );
  }

  @override
  String toString() => name;
}
