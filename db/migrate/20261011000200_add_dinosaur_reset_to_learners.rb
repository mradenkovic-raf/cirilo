class AddDinosaurResetToLearners < ActiveRecord::Migration[8.1]
  def change
    add_column :learners, :dinosaur_generation, :integer, default: 1, null: false
    add_column :learners, :last_dino_snapshot, :json, default: {}, null: false
  end
end
