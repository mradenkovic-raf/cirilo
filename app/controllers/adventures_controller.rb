class AdventuresController < ApplicationController
  def show
    @learner = current_learner
    @active_session = @learner.active_session
    @adventure = AdventureMap.new(@learner)
  end
end
