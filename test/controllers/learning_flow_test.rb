require "test_helper"
require_relative "../services/exercise_helpers"

class LearningFlowTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  test "new full alphabet drawings render and survive the successful answer response" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    task = PracticePlanner.send(:exercise, Curriculum.find("s"), WordBank.find("СИТО"), "build_word", "upper")
    learner.letter_progresses.find_or_create_by!(letter_id: task.fetch("letter_id"))
    session.update!(exercises: [task] + session.exercises.drop(1))
    get practice_session_path(session)
    assert_response :success
    assert_select ".build-picture img.word-illustration[alt='']", count: 1 do |images|
      assert_match %r{\A/school_images/sieve\.svg\?v=[a-f0-9]{12}\z}, images.first["src"]
    end
    post practice_session_attempts_path(session), params: correct_attributes(task), as: :json
    assert_response :success
    assert response.parsed_body.fetch("correct")
    assert_match %r{\A/school_images/sieve\.svg\?v=[a-f0-9]{12}\z}, response.parsed_body.fetch("meaning").fetch("image_url")
  end

  test "every main page renders with all thirty letters and matching reward names" do
    test_learner
    get root_path
    assert_response :success
    assert_select "h1", 1
    assert_select "form[action=?]", practice_sessions_path

    get workshop_path
    assert_response :success
    assert_select ".hangar-part", Curriculum::PARTS.length
    assert_equal DinoHelper::DINO_PART_NAMES, Curriculum.parts.map { |part| part.fetch("name") }

    get alphabet_path
    assert_response :success
    assert_select ".alphabet-card", 30

    get progress_path
    assert_response :success
    assert_select ".progress-table tbody tr", 30
  end

  test "mission creation resumes the same session and renders every exercise type" do
    test_learner
    post practice_sessions_path
    assert_response :see_other
    session = test_learner.active_session
    assert_redirected_to practice_session_path(session)

    post practice_sessions_path
    assert_redirected_to practice_session_path(session)
    assert_equal 1, test_learner.practice_sessions.count

    # The first mission has whole-word handwriting; the next mission has gaps.
    # Cover both renderers without making coverage depend on the rotation.
    session.update!(exercises: session.exercises + [planned_exercise("fill_letters")])
    session.exercises.map { |exercise| exercise.fetch("kind") }.uniq.each do |kind|
      cursor = session.exercises.index { |exercise| exercise.fetch("kind") == kind }
      session.update!(cursor: cursor)
      # This test visits renderers out of order; the drive has its own flow test.
      DinoDrive.new(session).skip! if session.drive_pending?
      get practice_session_path(session)
      assert_response :success
      assert_select "[data-exercise][data-kind=?]", kind
      if kind == "trace"
        assert_select "canvas.trace-canvas", 1
        assert_select "script#trace-data", 1
      elsif %w[write_word fill_letters].include?(kind)
        assert_select "canvas.word-writing-canvas", 1
        assert_select "script#writing-data", 1
        assert_select ".writing-prompt .writing-picture[role=img]", text: WordBank.find(session.current_exercise.fetch("word")).fetch("emoji")
        assert_select ".writing-prompt .writing-word button[data-writing-slot]", session.current_exercise.fetch("writing_letters").length
      elsif %w[build_word memory_word].include?(kind)
        exercise = session.current_exercise
        assert_select "button[data-tile]", exercise.fetch("tiles").length
        assert_select "button[data-slot]", exercise.fetch("word").length
        assert_select "[data-submit-word][disabled]", 1
        assert_select "[data-memory-study]", kind == "memory_word" ? 1 : 0
        assert_select "[data-composer][hidden]", kind == "memory_word" ? 1 : 0
      elsif kind == "repair_word"
        assert_select "button[data-repair-slot]", session.current_exercise.fetch("broken_word").length
        assert_select "button[data-repair-letter]", 4
        assert_select "[data-submit-variety][disabled]", 1
      elsif kind == "word_pairs"
        assert_select "button[data-pair-word]", 3
        assert_select "button[data-pair-picture]", 3
        assert_select "[data-submit-variety][disabled]", 1
      else
        assert_select "button[data-answer]", 4
      end
    end
  end

  test "completing a mission displays the exact unlocked reward and earned energy" do
    session = complete_mission
    get practice_session_path(session)
    assert_response :success
    assert_select ".reward-screen h2", "Турбо чизмице"
    assert_select ".reward-xp", /145/
    assert_select "[data-celebrate]", 1

    get workshop_path
    assert_response :success
    assert_select ".hangar-part.is-earned", 1
  end

  test "crystal rewards after all parts render every page and the next mission" do
    last_session = nil
    (Curriculum::PARTS.length + 1).times { last_session = complete_mission }
    assert_equal "energy_#{Curriculum::PARTS.length + 1}", last_session.part_unlock.part_key
    [root_path, workshop_path, alphabet_path, progress_path, practice_session_path(last_session)].each do |path|
      get path
      assert_response :success
    end
    assert_select ".reward-screen h2", "Кристал енергије 1"

    post practice_sessions_path
    follow_redirect!
    assert_response :success
    assert_select "[data-exercise]", 1
  end

  test "color preference persists and unsupported color cannot change it" do
    patch customize_workshop_path, params: { dino_color: "blue", shop_generation: test_learner.shop_generation }
    assert_redirected_to workshop_path
    assert_equal "blue", test_learner.reload.dino_color
    follow_redirect!
    assert_response :success
    assert_select ".color-swatch.blue.selected[aria-pressed=true]", 1

    patch customize_workshop_path, params: { dino_color: "invalid", shop_generation: test_learner.shop_generation }
    assert_redirected_to workshop_path
    assert_equal "blue", test_learner.reload.dino_color
  end

  test "unknown mission identifiers return not found" do
    test_learner
    get practice_session_path(id: 9_999_999)
    assert_response :not_found
    post practice_session_attempts_path(practice_session_id: 9_999_999), params: {
      exercise_id: "missing", answer: "А"
    }, as: :json
    assert_response :not_found
  end

  private

  def complete_mission
    session = PracticePlanner.start!(test_learner)
    complete_practice_session(session)
  end
end
