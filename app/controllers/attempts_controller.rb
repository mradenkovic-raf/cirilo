class AttemptsController < ApplicationController
  def create
    session = Learner.current.practice_sessions.find(params[:practice_session_id])
    raw_metrics = params[:trace_metrics]
    metrics = if raw_metrics.respond_to?(:permit)
      raw_metrics.permit(:coverage, :precision, :points, :drawnLength, :guideLength).to_h
    else
      raw_metrics || {}
    end
    raw_traces = params[:letter_traces]
    letter_traces = if raw_traces.is_a?(Array)
      raw_traces.map do |item|
        item.respond_to?(:permit) ? item.permit(:index, :letter, :score,
          metrics: [:coverage, :precision, :points, :drawnLength, :guideLength]).to_h : item
      end
    else
      raw_traces
    end
    result = AttemptRecorder.new(session).submit!(
      exercise_id: params[:exercise_id], answer: params[:answer],
      assisted: params[:assisted] == true,
      trace_score: params[:trace_score], trace_metrics: metrics, letter_traces: letter_traces
    )
    render json: result
  rescue AttemptRecorder::InvalidSubmission => error
    render json: { success: false, error: error.message }, status: :unprocessable_entity
  rescue AttemptRecorder::StaleExercise => error
    render json: { success: false, error: error.message, next_url: practice_session_path(session) }, status: :conflict
  end
end
