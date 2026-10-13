class RoadRunsController < ApplicationController
  before_action :load_mission

  def show
    @road_run = @practice_session.road_run
    unless @practice_session.drive_checkpoint? || @road_run&.resolved?
      return redirect_to practice_session_path(@practice_session)
    end
    @race_state = state_with_urls(@road_run)
  end

  def start
    run = DinoDrive.new(@practice_session).start!
    render json: { success: true, state: state_with_urls(run), **urls }
  rescue DinoDrive::InvalidRun => error
    invalid_run(error)
  end

  def finish
    moves = params[:moves]
    moves = moves.map { |move| move.is_a?(ActionController::Parameters) ? move.to_unsafe_h : move } if moves.is_a?(Array)
    run = DinoDrive.new(@practice_session).finish!(token: params[:token], moves: moves, elapsed_ms: params[:elapsed_ms])
    render json: { success: true, **state_with_urls(run) }
  rescue DinoDrive::InvalidRun => error
    invalid_run(error)
  end

  def skip
    run = DinoDrive.new(@practice_session).skip!
    respond_to do |format|
      format.html { redirect_to practice_session_path(@practice_session), status: :see_other }
      format.json { render json: { success: true, **state_with_urls(run) } }
    end
  rescue DinoDrive::InvalidRun => error
    respond_to do |format|
      format.html { redirect_to practice_session_path(@practice_session), status: :see_other }
      format.json { invalid_run(error) }
    end
  end

  private

  def load_mission
    @learner = current_learner
    @practice_session = @learner.practice_sessions.find(params[:practice_session_id])
  end

  def state_with_urls(run)
    DinoDrive.state(run).merge(urls)
  end

  def urls
    { next_url: practice_session_path(@practice_session), finish_url: finish_practice_session_drive_path(@practice_session) }
  end

  def invalid_run(error)
    render json: { success: false, error: error.message }, status: :unprocessable_entity
  end
end
