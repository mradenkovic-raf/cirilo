require "test_helper"

class StoryFlowTest < ActionDispatch::IntegrationTest
  test "all story dimensions render four native scenes without reading the tested sentence aloud" do
    learner = test_learner
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

  test "all twenty position stories render distinct pictures with neutral labels and no spoken answer" do
    session = PracticePlanner.start!(test_learner)
    index = session.exercises.index { |item| item["kind"] == "story_action" }
    20.times do |variation|
      tasks = session.exercises.deep_dup
      tasks[index].merge!(StoryBank.position_exercise(variation: variation))
      session.update!(exercises: tasks, cursor: index)

      get practice_session_path(session)

      assert_response :success
      assert_select ".story-sentence", text: tasks[index].fetch("story_sentence"), count: 1
      assert_select ".story-choice[data-answer]", 4
      assert_select ".story-choice svg.story-scene[aria-hidden='true']", 4
      images = css_select(".story-choice svg.story-scene")
      assert_equal 4, images.map(&:to_html).uniq.length
      images.each { |svg| assert_operator svg.css("path, circle, rect, polygon").length, :>=, 3 }
      assert_select "[data-task-body] [data-speak], [data-task-body] [data-correct], .story-choice.correct", 0
      css_select(".story-choice").each_with_index do |choice, choice_index|
        assert_equal "Слика #{choice_index + 1}", choice["aria-label"]
        assert_equal (choice_index + 1).to_s, choice.text.strip
      end
    end
  end

  test "story accepts only its options saves correct result and duplicate cannot reward twice" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    session.update!(cursor: session.exercises.index { |item| item["kind"] == "story_action" })
    task = session.current_exercise
    progress_before = learner.letter_progresses.order(:id).map(&:attributes)
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
    assert_equal progress_before, learner.letter_progresses.order(:id).map(&:attributes)
  end
end
