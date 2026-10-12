class AddDinoSpeciesToBattles < ActiveRecord::Migration[8.1]
  def change
    add_column :battles, :dino_species, :string, null: false, default: "rex"
  end
end
