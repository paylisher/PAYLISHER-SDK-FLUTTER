package com.paylisher.flutter

import android.os.Handler
import android.os.Looper
import com.paylisher.surveys.OnPaylisherSurveyClosed
import com.paylisher.surveys.OnPaylisherSurveyResponse
import com.paylisher.surveys.OnPaylisherSurveyShown
import com.paylisher.surveys.PaylisherDisplayChoiceQuestion
import com.paylisher.surveys.PaylisherDisplayLinkQuestion
import com.paylisher.surveys.PaylisherDisplayOpenQuestion
import com.paylisher.surveys.PaylisherDisplayRatingQuestion
import com.paylisher.surveys.PaylisherDisplaySurvey
import com.paylisher.surveys.PaylisherDisplaySurveyQuestion
import com.paylisher.surveys.PaylisherNextSurveyQuestion
import com.paylisher.surveys.PaylisherSurveyResponse
import com.paylisher.surveys.PaylisherSurveysDelegate
import io.flutter.plugin.common.MethodChannel

/**
 * Separate surveys delegate to avoid class loading issues in the main plugin
 */
class PaylisherFlutterSurveysDelegate(
    private val channel: MethodChannel,
) : PaylisherSurveysDelegate {
    private var currentSurvey: PaylisherDisplaySurvey? = null
    private var onSurveyShownCallback: OnPaylisherSurveyShown? = null
    private var onSurveyResponseCallback: OnPaylisherSurveyResponse? = null
    private var onSurveyClosedCallback: OnPaylisherSurveyClosed? = null

    override fun renderSurvey(
        survey: PaylisherDisplaySurvey,
        onSurveyShown: OnPaylisherSurveyShown,
        onSurveyResponse: OnPaylisherSurveyResponse,
        onSurveyClosed: OnPaylisherSurveyClosed,
    ) {
        currentSurvey = survey
        onSurveyShownCallback = onSurveyShown
        onSurveyResponseCallback = onSurveyResponse
        onSurveyClosedCallback = onSurveyClosed

        // Convert survey to map and send to Flutter
        invokeFlutterMethod("showSurvey", survey.toMap())
    }

    override fun cleanupSurveys() {
        currentSurvey = null
        onSurveyShownCallback = null
        onSurveyResponseCallback = null
        onSurveyClosedCallback = null
    }

    fun handleSurveyAction(
        action: String,
        payload: Map<String, Any>?,
        result: MethodChannel.Result,
    ) {
        val survey = currentSurvey
        if (survey == null) {
            result.error("InvalidArguments", "No active survey", null)
            return
        }

        when (action) {
            "shown" -> {
                onSurveyShownCallback?.invoke(survey)
            }
            "response" -> {
                val index = payload?.get("index") as? Int
                val responsePayload = payload?.get("response")

                if (index != null && responsePayload != null && index < survey.questions.size) {
                    val question = survey.questions[index]

                    // Create PaylisherSurveyResponse based on question type
                    val surveyResponse =
                        when (question) {
                            is PaylisherDisplayLinkQuestion -> {
                                // For link questions
                                val boolValue = responsePayload as? Boolean ?: false
                                PaylisherSurveyResponse.Link(boolValue)
                            }
                            is PaylisherDisplayRatingQuestion -> {
                                // For rating questions
                                val ratingValue = responsePayload as? Int
                                PaylisherSurveyResponse.Rating(ratingValue)
                            }
                            is PaylisherDisplayChoiceQuestion -> {
                                // For single/multiple choice questions
                                if (question.isMultipleChoice) {
                                    // Multiple choice: accept array directly from Flutter
                                    val selectedOptions = responsePayload as? List<*>
                                    val stringOptions = selectedOptions?.mapNotNull { it as? String }
                                    PaylisherSurveyResponse.MultipleChoice(stringOptions ?: emptyList())
                                } else {
                                    // Single choice: Flutter sends as a list with one element
                                    val selectedOptions = responsePayload as? List<*>
                                    val firstOption = selectedOptions?.firstOrNull() as? String
                                    PaylisherSurveyResponse.SingleChoice(firstOption)
                                }
                            }
                            else -> {
                                // Default to open text question
                                val textValue = responsePayload as? String
                                PaylisherSurveyResponse.Text(textValue)
                            }
                        }

                    // Call the callback with the constructed response
                    onSurveyResponseCallback?.invoke(survey, index, surveyResponse)?.let { nextQuestion ->
                        result.success(
                            mapOf(
                                "nextIndex" to nextQuestion.questionIndex,
                                "isSurveyCompleted" to nextQuestion.isSurveyCompleted,
                            ),
                        )
                        return
                    }
                    result.success(null)
                    return
                }
            }
            "closed" -> {
                onSurveyClosedCallback?.invoke(survey)
                // Clear the callbacks after survey is closed
                currentSurvey = null
                onSurveyShownCallback = null
                onSurveyResponseCallback = null
                onSurveyClosedCallback = null
            }
        }

        result.success(null)
    }

    /**
     * Invoke a Flutter method on the main/UI thread
     */
    private fun invokeFlutterMethod(
        method: String,
        arguments: Any? = null,
    ) {
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod(method, arguments)
        }
    }
}
