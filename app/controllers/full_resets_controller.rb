class FullResetsController < ApplicationController
  def create
    FullReset.reset!(current_learner, confirmation: params[:confirm_reset], reset_word: params[:reset_word],
      shop_generation: params[:shop_generation], dinosaur_generation: params[:dinosaur_generation])
    redirect_to progress_path,
      notice: "Све је враћено на почетак. Нема поена, куповина, опреме, спасених другара ни старих мисија. Нова авантура почиње од првог корака.",
      status: :see_other
  rescue FullReset::InvalidRequest => error
    redirect_to progress_path, alert: error.message, status: :see_other
  end
end
