require "test_helper"

class StoryFlowTest < ActionDispatch::IntegrationTest
  test "all story dimensions render four native scenes without reading the tested sentence aloud" do
    learner = Learner.current
    session = PracticePlanner.start!(learner)
    index = session.exercises.index { |item| item["kind"] == "story_action" }
    12.times do |variation|
      tasks = session.exercises.deep_dup
      tasks[index].merge!(StoryBank.exercise(variation: variation))
      session.update!(exercises: tasks, cursor: index)
      get practice_session_path(session)
      assert_response :success
      assert_select ".story-choice[data-answer]", 4
      assert_select ".story-choice svg.story-scene", 4
      assert_select ".story-sentence", tasks[index].fetch("story_sentence")
      assert_select "[data-speak]", 0
      assert_not response.body.include?("data-speak=\"#{tasks[index].fetch('story_sentence')}")
      assert_select ".story-choice.correct", 0
      assert_select ".story-choice[aria-label='Слика 1']", 1
    end
  end

  test "story accepts only its options saves correct result and duplicate cannot reward twice" do
    learner = Learner.current
    session = PracticePlanner.start!(learner)
    session.update!(cursor: session.exercises.index { |item| item["kind"] == "story_action" })
    task = session.current_exercise
    post practice_session_attempts_path(session), params: { exercise_id: task.fetch("id"), answer: "INVALID" }, as: :json
    assert_response :unprocessable_entity
    assert_equal 0, session.attempts.count
    2.times do
      post practice_session_attempts_path(session), params: { exercise_id: task.fetch("id"), answer: task.fetch("answer") }, as: :json
      assert_response :success
      assert response.parsed_body.fetch("correct")
    end
    assert_equal 10, learner.reload.xp
    assert_equal 1, session.attempts.count
  end
end
