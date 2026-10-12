require "test_helper"

class ConcurrentShopPurchaseTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup { Learner.destroy_all }
  teardown { Learner.destroy_all }

  test "simultaneous requests for one item charge exactly once" do
    learner = Learner.current
    learner.update!(xp: 240)
    results = buy_together(learner, ["dino_tricera", "dino_tricera"])
    assert results.all? { |result| result.is_a?(Hash) }, results.inspect
    assert_equal 1, results.count { |result| result.fetch(:purchased) }
    assert_equal 240, learner.reload.xp_spent
    assert_equal 0, learner.xp_balance
    assert_equal 240, learner.xp
    assert_equal 1, learner.shop_purchases.count
  end

  test "different simultaneous purchases cannot overdraw the shared wallet" do
    learner = Learner.current
    learner.update!(xp: 200)
    results = buy_together(learner, ["color_ice", "effect_lightning"])
    assert_equal 1, results.count { |result| result.is_a?(Hash) }, results.inspect
    assert_equal 1, results.count { |result| result.is_a?(ShopService::InsufficientFunds) }, results.inspect
    assert_equal learner.shop_purchases.sum(:price_paid), learner.reload.xp_spent
    assert_includes [40, 80], learner.xp_balance
    assert_equal 1, learner.shop_purchases.count
  end

  private

  def buy_together(learner, ids)
    gate = Queue.new
    results = Queue.new
    workers = ids.map do |id|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          shop = ShopService.new(Learner.find(learner.id))
          gate.pop
          results << shop.purchase!(item_id: id)
        rescue StandardError => error
          results << error
        end
      end
    end
    ids.length.times { gate << true }
    workers.each(&:join)
    ids.length.times.map { results.pop }
  end
end
