class DashboardController < ApplicationController
  before_action :load_dashboard

  def index; end
  def workshop; end
  def alphabet; end
  def progress; end

  def customize
    color = params[:dino_color]
    item_id = color.is_a?(String) ? "color_#{color}" : nil
    ShopService.new(@learner).equip!(item_id: item_id, generation: params[:shop_generation] || "")
    redirect_to workshop_path, notice: "Твој дино има нову боју!", status: :see_other
  rescue ShopService::Error => error
    redirect_to workshop_path, alert: error.message, status: :see_other
  end

  def reset_dino
    DinoReset.reset!(@learner, confirmation: params[:confirm_reset], generation: params[:dinosaur_generation])
    redirect_to workshop_path, notice: "Нови дино је спреман! Слова, енергија и мисије су сачувани.", status: :see_other
  rescue DinoReset::InvalidRequest => error
    redirect_to workshop_path, alert: error.message, status: :see_other
  end

  def restore_dino
    DinoReset.restore!(@learner, generation: params[:dinosaur_generation])
    redirect_to workshop_path, notice: "Претходни делови су враћени. Настављамо учење!", status: :see_other
  rescue DinoReset::InvalidRequest => error
    redirect_to workshop_path, alert: error.message, status: :see_other
  end

  private

  def load_dashboard
    @learner = current_learner
    @active_session = @learner.active_session
    @active_mission = @active_session
    @stats = @learner.statistics
    @letters = @learner.school_mode? ? SchoolCurriculum.letters_for(@learner.school_letter_ids) : Curriculum.letters
    @progress_by_letter = @learner.letter_progresses.index_by(&:letter_id)
    @next_letters = PracticePlanner.next_letters(@learner)
    @unlocks = @learner.part_unlocks.order(:position).to_a
    unlocked_by_key = @unlocks.index_by(&:part_key)
    @parts = (Curriculum.parts + @unlocks.drop(Curriculum::PARTS.length).map(&:part)).map do |part|
      part.merge("unlocked" => unlocked_by_key.key?(part.fetch("id")))
    end
    @next_part = Curriculum.part_at(@learner.part_unlocks.count + 1)
    @recent_sessions = @learner.practice_sessions.where(status: "completed").order(completed_at: :desc).limit(5)
    @arena_session = @learner.battles.where(status: "active").order(created_at: :desc).first&.practice_session || @recent_sessions.first
  end
end
