class AddEggStateToLearners < ActiveRecord::Migration[8.1]
  def change
    add_column :learners, :egg_state, :json, null: false, default: {}
  end
end
