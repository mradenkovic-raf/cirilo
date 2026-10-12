class CreateShopPurchases < ActiveRecord::Migration[8.1]
  def change
    add_column :learners, :xp_spent, :integer, default: 0, null: false
    add_column :learners, :selected_dino, :string, default: "rex", null: false
    add_column :learners, :selected_theme, :string, default: "meadow", null: false
    add_column :learners, :selected_effect, :string, default: "stars", null: false
    add_check_constraint :learners, "xp_spent >= 0 AND xp_spent <= xp", name: "learner_wallet_nonnegative"

    create_table :shop_purchases do |t|
      t.references :learner, null: false, foreign_key: true
      t.string :item_key, null: false
      t.integer :price_paid, null: false
      t.timestamps
      t.index [:learner_id, :item_key], unique: true
      t.check_constraint "price_paid > 0", name: "shop_purchase_positive_price"
    end
  end
end
