class CreateRoadRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :road_runs do |t|
      t.references :practice_session, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "active"
      t.string :token, null: false
      t.json :obstacles, null: false, default: []
      t.json :moves, null: false, default: []
      t.integer :elapsed_ms, null: false, default: 0
      t.integer :hits, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end
  end
end
