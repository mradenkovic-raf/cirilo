class LearningSettingsController < ApplicationController
  def update
    LearningSettings.update!(current_learner, mode: params[:learning_mode], selection: params[:letter_selection],
      through: params[:through_letter], letter_ids: params[:school_letter_ids], revision: params[:learning_settings_revision])
    message = current_learner.school_mode? ? "Школска слова су сачувана." : "Изабрана је цела азбука."
    message += current_learner.active_session ? " Започета мисија остаје иста; избор важи од следеће мисије." : " Следећа мисија је спремна по новом избору."
    redirect_to progress_path(anchor: "learning-settings"), notice: message, status: :see_other
  rescue LearningSettings::InvalidRequest => error
    redirect_to progress_path(anchor: "learning-settings"), alert: error.message, status: :see_other
  end
end
