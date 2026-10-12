class AddBattleEquipmentPowers < ActiveRecord::Migration[8.1]
  def change
    add_column :battles, :power_state, :json, default: {}, null: false
    add_column :battles, :next_enemy_move, :string
    add_column :battles, :action_revision, :integer, default: 0, null: false
  end
end
