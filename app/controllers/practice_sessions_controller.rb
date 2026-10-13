class PracticeSessionsController < ApplicationController
  def create
    session = PracticePlanner.start!(current_learner)
    redirect_to practice_session_path(session), status: :see_other
  end

  def show
    @learner = current_learner
    @practice_session = @learner.practice_sessions.find(params[:id])
    PracticePlanner.upgrade!(@practice_session)
    return redirect_to practice_session_drive_path(@practice_session) if @practice_session.drive_pending?
    @mission = @practice_session
    @exercise = @practice_session.current_exercise_for_display
    @letter = @exercise && Curriculum.find(@exercise.fetch("letter_id"))
    @progress = @practice_session.progress_percent
    @stats = @learner.statistics
    @unlocked_part = @practice_session.part_unlock&.part
    @next_part = Curriculum.part_at(@learner.part_unlocks.count + 1)
  end

  def memorize
    session = current_learner.practice_sessions.find(params[:id])
    render json: AttemptRecorder.new(session).memorize!(exercise_id: params[:exercise_id])
  rescue AttemptRecorder::InvalidSubmission => error
    render json: { success: false, error: error.message }, status: :unprocessable_entity
  rescue AttemptRecorder::StaleExercise => error
    render json: { success: false, error: error.message, next_url: practice_session_path(session) }, status: :conflict
  end
end
