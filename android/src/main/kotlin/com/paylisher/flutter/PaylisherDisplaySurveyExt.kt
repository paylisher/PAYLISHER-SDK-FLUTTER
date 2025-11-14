package com.paylisher.flutter

import com.paylisher.surveys.PaylisherDisplayChoiceQuestion
import com.paylisher.surveys.PaylisherDisplayLinkQuestion
import com.paylisher.surveys.PaylisherDisplayOpenQuestion
import com.paylisher.surveys.PaylisherDisplayRatingQuestion
import com.paylisher.surveys.PaylisherDisplaySurvey
import com.paylisher.surveys.PaylisherDisplaySurveyQuestion

// Convert the survey object to a map for communication with the Dart layer
// Native platform model -> Map -> Dart model
fun PaylisherDisplaySurvey.toMap(): Map<String, Any?> {
    val map =
        mutableMapOf<String, Any?>(
            "id" to id,
            "name" to name,
            "questions" to
                questions.map { question: PaylisherDisplaySurveyQuestion ->
                    val questionMap =
                        mutableMapOf<String, Any?>(
                            "question" to question.question,
                            "isOptional" to question.isOptional,
                            "id" to question.id,
                        )

                    questionMap["questionDescription"] = question.questionDescription
                    questionMap["questionDescriptionContentType"] = question.questionDescriptionContentType?.value
                    questionMap["buttonText"] = question.buttonText

                    // Add question type-specific properties
                    when (question) {
                        is PaylisherDisplayLinkQuestion -> {
                            questionMap["type"] = "link"
                            questionMap["link"] = question.link
                        }
                        is PaylisherDisplayRatingQuestion -> {
                            questionMap["type"] = "rating"
                            questionMap["ratingType"] = question.ratingType.value
                            questionMap["scaleLowerBound"] = question.scaleLowerBound
                            questionMap["scaleUpperBound"] = question.scaleUpperBound
                            questionMap["lowerBoundLabel"] = question.lowerBoundLabel
                            questionMap["upperBoundLabel"] = question.upperBoundLabel
                        }
                        is PaylisherDisplayChoiceQuestion -> {
                            questionMap["type"] = if (question.isMultipleChoice) "multiple_choice" else "single_choice"
                            questionMap["choices"] = question.choices
                            questionMap["hasOpenChoice"] = question.hasOpenChoice
                            questionMap["shuffleOptions"] = question.shuffleOptions
                        }
                        else -> {
                            questionMap["type"] = "open"
                        }
                    }

                    questionMap
                },
        )

    // Add appearance if available
    appearance?.let { app ->
        map["appearance"] =
            mapOf(
                "backgroundColor" to app.backgroundColor,
                "submitButtonColor" to app.submitButtonColor,
                "submitButtonText" to app.submitButtonText,
                "submitButtonTextColor" to app.submitButtonTextColor,
                "descriptionTextColor" to app.descriptionTextColor,
                "ratingButtonColor" to app.ratingButtonColor,
                "ratingButtonActiveColor" to app.ratingButtonActiveColor,
                "borderColor" to app.borderColor,
                "placeholder" to app.placeholder,
                "displayThankYouMessage" to app.displayThankYouMessage,
                "thankYouMessageHeader" to app.thankYouMessageHeader,
                "thankYouMessageDescription" to app.thankYouMessageDescription,
                "thankYouMessageDescriptionContentType" to app.thankYouMessageDescriptionContentType?.value,
            )
    }

    // Add dates if available (convert to milliseconds since epoch)
    startDate?.let { date ->
        map["startDate"] = date.time
    }

    endDate?.let { date ->
        map["endDate"] = date.time
    }

    return map
}
