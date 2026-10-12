require "test_helper"

class ConcurrentShopResetTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup { Learner.destroy_all }
  teardown { Learner.destroy_all }

  test "two reset requests with one generation apply once" do
    learner = Learner.current
    learner.update!(xp: 500)
    reset = -> {
      ShopReset.reset!(Learner.find(learner.id), confirmation: "1", reset_word: "RESET", generation: 1)
    }
    results = together(reset, reset)
    assert_equal 1, results.count { |result| result.is_a?(Learner) }, results.inspect
    assert_equal 1, results.count { |result| result.is_a?(ShopReset::InvalidRequest) }, results.inspect
    assert_equal 2, learner.reload.shop_generation
    assert_equal 0, learner.xp_balance
  end

  test "an old purchase racing the reset cannot spend the new generation" do
    learner = Learner.current
    learner.update!(xp: 500)
    results = together(
      -> { ShopService.new(Learner.find(learner.id)).purchase!(item_id: "dino_tricera", generation: 1) },
      -> { ShopReset.reset!(Learner.find(learner.id), confirmation: "1", reset_word: "RESET", generation: 1) }
    )
    assert results.all? { |item| item.is_a?(Learner) || item.is_a?(Hash) || item.is_a?(ShopService::StaleRequest) }, results.inspect
    assert_equal 2, learner.reload.shop_generation
    assert_equal [0, 0, "rex"], learner.values_at(:xp, :xp_spent, :selected_dino)
    assert_empty learner.shop_purchases
  end

  private

  def together(*jobs)
    gate = Queue.new
    results = Queue.new
    workers = jobs.map do |job|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.pop
          results << job.call
        rescue StandardError => error
          results << error
        end
      end
    end
    jobs.length.times { gate << true }
    workers.each(&:join)
    jobs.length.times.map { results.pop }
  end
end
