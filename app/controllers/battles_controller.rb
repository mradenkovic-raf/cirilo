class BattlesController < ApplicationController
  def create
    learner = Learner.current
    practice_session = learner.practice_sessions.find(params[:practice_session_id])
    battle = BattleArena.start!(learner, practice_session)
    redirect_to battle_path(battle), status: :see_other
  rescue BattleArena::InvalidBattle => error
    redirect_to practice_session_path(practice_session), alert: error.message, status: :see_other
  end

  def show
    @learner = Learner.current
    @battle = @learner.battles.find(params[:id])
    @practice_session = @battle.practice_session
    @state = BattleArena.state(@battle)
  end

  def move
    battle = Learner.current.battles.find(params[:id])
    result = BattleArena.new(battle).move!(move: params[:move], expected_round: params[:expected_round],
      expected_revision: params[:expected_revision])
    render json: with_art(result)
  rescue BattleArena::InvalidMove => error
    render json: { success: false, error: error.message }, status: :unprocessable_entity
  rescue BattleArena::StaleMove => error
    render json: { success: false, error: error.message,
      state: with_art(BattleArena.state(battle.reload)) }, status: :conflict
  end

  def power
    battle = Learner.current.battles.find(params[:id])
    result = BattleArena.new(battle).power!(power: params[:power], expected_round: params[:expected_round],
      expected_revision: params[:expected_revision])
    render json: with_art(result)
  rescue BattleArena::InvalidMove => error
    render json: { success: false, error: error.message }, status: :unprocessable_entity
  rescue BattleArena::StaleMove => error
    render json: { success: false, error: error.message,
      state: with_art(BattleArena.state(battle.reload)) }, status: :conflict
  end

  private

  def with_art(state)
    state.merge(player_svg: helpers.battle_player_svg(state), enemy_svg: helpers.battle_enemy_svg(state))
  end
end
