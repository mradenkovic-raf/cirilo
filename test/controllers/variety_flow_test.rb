require "test_helper"
require_relative "../services/exercise_helpers"

class VarietyFlowTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  test "picture reading presents four written choices and a picture without selecting the answer" do
    session, task = prepare_task("picture_word")

    get practice_session_path(session)

    assert_response :success
    assert_select "[data-exercise][data-kind='picture_word']", 1
    assert_select "[data-task-body] [data-answer]", 4
    assert_equal task.fetch("options").sort,
      css_select("[data-task-body] [data-answer]").map { |node| node["data-answer"] }.sort
    assert_includes css_select("[data-task-body]").first.text, task.fetch("emoji")
    assert_select "[data-task-body] .correct, [data-task-body] [data-correct], [data-task-body] [data-speak]", 0
  end

  test "repair starts from a broken word and does not reveal the corrected word in markup" do
    session, task = prepare_task("repair_word")

    get practice_session_path(session)

    assert_response :success
    assert_select "[data-variety='repair_word']", 1
    assert_select "[data-repair-slot]", task.fetch("broken_word").length
    assert_equal task.fetch("broken_word").chars,
      css_select("[data-repair-slot]").map { |node| node["data-original-letter"] }
    assert_select "[data-repair-letter]", 4
    assert_select "[data-submit-variety][disabled]", 1
    assert_select "[data-variety='repair_word'] [data-answer], [data-variety='repair_word'] [data-correct]", 0
    refute_includes css_select("[data-task-body]").first.to_html, task.fetch("answer")
  end

  test "pairing exposes three words and neutral pictures without the answer mapping" do
    session, task = prepare_task("word_pairs")

    get practice_session_path(session)

    assert_response :success
    assert_select "[data-pair-word]", 3
    assert_select "[data-pair-picture]", 3
    assert_select "[data-submit-variety][disabled]", 1
    assert_select "[data-variety='word_pairs'] [data-answer], [data-variety='word_pairs'] [data-correct]", 0
    refute_includes css_select("[data-task-body]").first.to_html, task.fetch("answer")
    picture_markup = css_select("[data-pair-picture]").map(&:to_html).join
    task.fetch("pair_words").each do |word|
      assert_includes css_select("[data-task-body]").first.text, word.fetch("label")
      refute_includes picture_markup, word.fetch("label")
    end
  end

  test "each new kind awards ten XP once and supplies meaning only for its completed word" do
    %w[picture_word repair_word word_pairs].each_with_index do |kind, index|
      session, task = prepare_task(kind)
      post_answer(session, task, task.fetch("answer"))

      assert_response :success
      body = response.parsed_body
      assert body.fetch("correct"), kind
      assert_equal 10, body.fetch("xp_earned"), kind
      assert_equal 10 * (index + 1), test_learner.reload.xp
      assert_equal 1, session.reload.cursor
      if task["word"]
        assert_equal task.fetch("word"), body.fetch("meaning").fetch("word")
        assert_equal task.fetch("emoji"), body.fetch("meaning").fetch("emoji")
      else
        assert_nil body.fetch("meaning")
      end

      post_answer(session, task, task.fetch("answer"))
      assert_response :success
      assert response.parsed_body.fetch("duplicate")
      assert_equal 0, response.parsed_body.fetch("xp_earned")
      assert_equal 10 * (index + 1), test_learner.reload.xp
      assert_equal 1, session.attempts.where(exercise_id: task.fetch("id")).count
    end
  end

  test "malformed pair submissions cannot consume an attempt or earn XP" do
    session, task = prepare_task("word_pairs")
    malformed = [nil, ["P3", "P1", "P2"], "P3,P1", "P3,P1,P1", "P3,P1,P9", "P3,P1,P2,P3"]

    malformed.each do |answer|
      post_answer(session, task, answer)
      assert_response :unprocessable_entity
      assert response.parsed_body.fetch("error").present?
      assert_equal 0, session.attempts.count
      assert_equal 0, session.reload.cursor
      assert_equal 2, session.total_exercises
      assert_equal 0, test_learner.reload.xp
    end
  end

  test "repair rejects unchanged words and multiple edits without recording an attempt" do
    session, task = prepare_task("repair_word")

    [task.fetch("broken_word"), "ИУТО", "АУТ", "АУТАО", "АУТБ"].each do |answer|
      post_answer(session, task, answer)
      assert_response :unprocessable_entity
      assert_equal 0, session.attempts.count
      assert_equal 0, session.reload.cursor
      assert_equal 0, test_learner.reload.xp
    end
  end

  test "a wrong complete pairing requires a zero XP review before retrying the same puzzle" do
    session, task = prepare_task("word_pairs")
    post_answer(session, task, "P1,P3,P2")

    assert_response :success
    refute response.parsed_body.fetch("correct")
    assert response.parsed_body.fetch("recovery_required")
    assert_equal 0, response.parsed_body.fetch("xp_earned")
    recovery = session.reload.current_exercise
    assert_equal task.fetch("id"), recovery.fetch("recovery_of")
    assert_equal 3, session.total_exercises

    post_answer(session, task, task.fetch("answer"))
    assert_response :conflict
    assert_equal 1, session.attempts.count
    assert_equal 0, test_learner.reload.xp

    post practice_session_attempts_path(session), params: correct_attributes(recovery), as: :json
    assert_response :success
    assert response.parsed_body.fetch("correct")
    assert_equal 0, response.parsed_body.fetch("xp_earned")
    assert_equal task, session.reload.current_exercise

    post_answer(session, task, task.fetch("answer"))
    assert_response :success
    assert response.parsed_body.fetch("correct")
    assert_equal 10, test_learner.reload.xp
    assert_equal 3, session.attempts.count
  end

  test "reposting the final pairing cannot repeat the mission bonus or unlock" do
    session, task = prepare_task("word_pairs")
    session.update!(exercises: [task])
    post_answer(session, task, task.fetch("answer"))

    assert_response :success
    assert response.parsed_body.fetch("completed")
    assert_equal 35, response.parsed_body.fetch("xp_earned")
    assert session.reload.completed?

    post_answer(session, task, task.fetch("answer"))
    assert_response :success
    assert response.parsed_body.fetch("duplicate")
    assert_equal 0, response.parsed_body.fetch("xp_earned")
    assert_equal 35, test_learner.reload.xp
    assert_equal 1, test_learner.completed_missions
    assert_equal 1, test_learner.part_unlocks.count
    assert_equal 1, session.attempts.count
  end

  private

  def prepare_task(kind)
    session = PracticePlanner.start!(test_learner)
    trace = session.exercises.find { |exercise| exercise.fetch("kind") == "trace" }.deep_dup
    trace["id"] = SecureRandom.uuid
    task = {
      "id" => SecureRandom.uuid, "version" => PracticePlanner::VERSION, "kind" => kind,
      "letter_id" => trace.fetch("letter_id"), "case" => "upper", "display_case" => "upper",
      "review_only" => false, "prompt" => "Погледај и реши."
    }.merge(case kind
    when "picture_word"
      { "word" => "АУТО", "answer" => "АУТО", "emoji" => "🚗", "options" => %w[АУТА АУТО АВТО АУТЕ] }
    when "repair_word"
      { "word" => "АУТО", "answer" => "АУТО", "emoji" => "🚗", "broken_word" => "АУТА", "repair_options" => %w[И О Е У] }
    when "word_pairs"
      {
        "answer" => "P3,P1,P2",
        "pair_words" => [{ "id" => "W1", "label" => "КИТ" }, { "id" => "W2", "label" => "ЛАВ" }, { "id" => "W3", "label" => "МИШ" }],
        "pair_pictures" => [{ "id" => "P1", "emoji" => "🦁" }, { "id" => "P2", "emoji" => "🐭" }, { "id" => "P3", "emoji" => "🐋" }]
      }
    end)
    session.update!(exercises: [task, trace], cursor: 0, earned_xp: 0)
    [session, task]
  end

  def post_answer(session, task, answer)
    post practice_session_attempts_path(session), params: { exercise_id: task.fetch("id"), answer: answer }, as: :json
  end
end
