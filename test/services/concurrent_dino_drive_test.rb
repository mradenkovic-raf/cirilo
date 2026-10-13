require "test_helper"

class ConcurrentDinoDriveTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup { Learner.destroy_all }
  teardown { Learner.destroy_all }

  test "two tabs start the same saved course" do
    learner, mission = checkpoint
    start = -> { DinoDrive.new(PracticeSession.find(mission.id)).start! }
    results = together(start, start)
    assert results.all? { |result| result.is_a?(RoadRun) }, results.inspect
    assert_equal 1, results.map(&:id).uniq.size
    assert_equal 1, results.map(&:obstacles).uniq.size
    assert_equal 1, RoadRun.count
    assert_equal 0, learner.reload.xp
  end

  test "simultaneous finishes save only one result and shield" do
    _learner, mission = checkpoint
    run = DinoDrive.new(mission).start!
    run.update!(started_at: 30.seconds.ago, obstacles: [{ "at_ms" => 3500, "lane" => 0 }])
    finish = -> { DinoDrive.new(PracticeSession.find(mission.id)).finish!(token: run.token, moves: [], elapsed_ms: 24_000) }
    results = together(finish, finish)
    assert results.all? { |result| result.is_a?(RoadRun) && result.shield_earned? }, results.inspect
    assert_equal 1, results.map(&:attributes).uniq.size
    assert_equal 1, RoadRun.count
  end

  test "full restart racing a final result leaves no orphan shield or road run" do
    learner, mission = checkpoint
    run = DinoDrive.new(mission).start!
    run.update!(started_at: 30.seconds.ago, obstacles: [{ "at_ms" => 3500, "lane" => 0 }])
    drive = DinoDrive.new(mission)
    results = together(
      -> { drive.finish!(token: run.token, moves: [], elapsed_ms: 24_000) },
      -> { FullReset.reset!(Learner.find(learner.id), confirmation: "1", reset_word: "RESET", shop_generation: 1, dinosaur_generation: 1) }
    )
    assert results.all? { |result| result.is_a?(RoadRun) || result.is_a?(Learner) || result.is_a?(ActiveRecord::RecordNotFound) }, results.inspect
    assert_empty RoadRun.all
    assert_empty learner.reload.practice_sessions
    assert_equal [0, 0], learner.values_at(:xp, :completed_missions)
  end

  private

  def checkpoint
    learner = Learner.create!
    mission = PracticePlanner.start!(learner)
    mission.update!(cursor: 6)
    [learner, mission]
  end

  def together(*jobs)
    gate, results = Queue.new, Queue.new
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
