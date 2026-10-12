class AdventuresController < ApplicationController
  def show
    @learner = Learner.current
    @active_session = @learner.active_session
    @adventure = AdventureMap.new(@learner)
  end
end
