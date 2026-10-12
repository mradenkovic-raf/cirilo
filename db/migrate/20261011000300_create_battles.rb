class CreateBattles < ActiveRecord::Migration[8.1]
  def change
    create_table :battles do |t|
      t.references :learner, null: false, foreign_key: true
      t.references :practice_session, null: false, foreign_key: true, index: { unique: true }
      t.string :status, default: "active", null: false
      t.string :dino_color, default: "green", null: false
      t.json :gear_snapshot, default: [], null: false
      t.integer :player_hp, null: false
      t.integer :player_max_hp, null: false
      t.integer :enemy_hp, null: false
      t.integer :enemy_max_hp, null: false
      t.integer :round, default: 0, null: false
      t.json :turn_history, default: [], null: false
      t.datetime :finished_at
      t.timestamps
    end
    add_index :battles, [:learner_id, :status]
  end
end
