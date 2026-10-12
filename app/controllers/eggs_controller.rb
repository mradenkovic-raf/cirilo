class EggsController < ApplicationController
  before_action :load_egg

  def create
    @egg.choose!(species: params[:species], generation: params[:shop_generation])
    redirect_to workshop_path(anchor: "egg"), notice: "Твоје јаје је спремно. Помози му кроз три мисије!", status: :see_other
  rescue EggCompanion::Error => error
    redirect_to workshop_path(anchor: "egg"), alert: error.message, status: :see_other
  end

  def hatch
    flash.delete(:egg_hatched)
    flash[:egg_hatched] = @egg.state.fetch("id") if @egg.hatch!(egg_id: params[:egg_id])
    redirect_to workshop_path(anchor: "egg"), status: :see_other
  rescue EggCompanion::Error => error
    redirect_to workshop_path(anchor: "egg"), alert: error.message, status: :see_other
  end

  def name
    @egg.name!(egg_id: params[:egg_id], name: params[:name])
    redirect_to workshop_path(anchor: "egg"), notice: "Другар сада има своје име!", status: :see_other
  rescue EggCompanion::Error => error
    redirect_to workshop_path(anchor: "egg"), alert: error.message, status: :see_other
  end

  private

  def load_egg
    @egg = EggCompanion.new(Learner.current)
  end
end
