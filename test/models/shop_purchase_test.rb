require "test_helper"

class ShopPurchaseTest < ActiveSupport::TestCase
  test "a purchase records a real paid catalog item at its catalog price" do
    learner = test_learner
    %w[missing color_green].each do |key|
      assert_not learner.shop_purchases.build(item_key: key, price_paid: 120).valid?
    end
    [-120, 0, 1, 120.5].each do |price|
      assert_not learner.shop_purchases.build(item_key: "color_ice", price_paid: price).valid?
    end
    purchase = learner.shop_purchases.create!(item_key: "color_ice", price_paid: 120)
    assert_equal 120, purchase.reload.price_paid
    assert_not learner.shop_purchases.build(item_key: "color_ice", price_paid: 120).valid?
  end

  test "wallet and selections reject invalid values while keeping lifetime level" do
    learner = test_learner
    learner.update!(xp: 300, xp_spent: 120)
    assert_equal 180, learner.xp_balance
    assert_equal 4, learner.level
    [-1, 301, 1.5].each do |spent|
      learner.xp_spent = spent
      assert_not learner.valid?
    end
    learner.reload
    assert_not learner.update(selected_dino: "unknown")
    learner.reload
    assert_not learner.update(selected_theme: "unknown")
    learner.reload
    assert_not learner.update(selected_effect: "unknown")
  end

  test "ownership resolves catalog definitions instead of trusting a forged hash" do
    learner = test_learner
    assert learner.owns_shop_item?("color_blue")
    assert learner.selected_shop_item?("dino_rex")
    assert_not learner.owns_shop_item?({ "id" => "dino_robo", "price" => 0 })
    assert_not learner.owns_shop_item?({ "id" => "unknown", "price" => 0 })
    assert_not learner.selected_shop_item?("unknown")
  end

  test "database cannot store an overdrawn wallet or duplicate purchase" do
    learner = test_learner
    assert_raises(ActiveRecord::StatementInvalid) { learner.update_columns(xp_spent: 1) }
    assert_equal 0, learner.reload.xp_balance
    purchase = learner.shop_purchases.create!(item_key: "color_ice", price_paid: 120)
    attributes = purchase.attributes.except("id")
    assert_raises(ActiveRecord::RecordNotUnique) { ShopPurchase.insert_all!([attributes]) }
  end
end
