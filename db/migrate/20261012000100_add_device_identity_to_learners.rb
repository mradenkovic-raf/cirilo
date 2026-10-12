class AddDeviceIdentityToLearners < ActiveRecord::Migration[8.1]
  def up
    add_column :learners, :device_token_digest, :string
    add_index :learners, :device_token_digest, unique: true
    # Existing progress remains archived in place, without a browser key.
    # Never let the first visitor claim the former shared child's progress.
    remove_column :learners, :singleton_key, :string
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Multiple browsers cannot safely become one child. Restore the v14 database backup with the v14 Git tag."
  end
end
