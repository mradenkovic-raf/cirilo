require "test_helper"
require_relative "../services/exercise_helpers"

class LearningSettingsControllerTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  test "new browser defaults to school letters through E and renders parent controls" do
    learner = school_learner
    assert learner.school_mode?
    assert_equal %w[a m i t o n s e], learner.school_letter_ids
    get progress_path
    assert_response :success
    assert_select "input[name=learning_mode][value=school][checked]", 1
    assert_select "input[name='school_letter_ids[]'][type=checkbox]", 30
    assert_select "input[name='school_letter_ids[]'][type=checkbox][checked]", 8
    assert_select "select[name=through_letter] option[selected][value=e]", 1

    get alphabet_path
    assert_response :success
    assert_select ".alphabet-card", 8
    assert_select ".alphabet-word" do |nodes|
      nodes.each { |node| assert SchoolCurriculum.known_text?(node.text, learner.school_letter_ids) }
    end
  end

  test "parent can extend in book order or choose a custom set without changing rewards" do
    learner = school_learner
    learner.update!(xp: 190)
    save_settings(through_letter: "j")
    assert_response :see_other
    assert_equal %w[a m i t o n s e r j], learner.reload.school_letter_ids
    assert_equal 190, learner.xp
    save_settings(letter_selection: "custom", school_letter_ids: ["", "r", "a", "m"])
    assert_equal %w[a m r], learner.reload.school_letter_ids
    get progress_path
    assert_select "input[name=letter_selection][value=custom][checked]", 1
    assert_select ".school-custom[open]", 1
  end

  test "switching modes preserves active mission and applies to the next mission" do
    learner = school_learner
    post practice_sessions_path
    session = learner.active_session
    assert session.school_mode?
    snapshot = session.exercises.deep_dup
    save_settings(learning_mode: "full")
    assert_equal "full", learner.reload.learning_mode
    post practice_sessions_path
    assert_redirected_to practice_session_path(session)
    assert_equal snapshot, session.reload.exercises
    assert_equal SchoolCurriculum.default_ids, session.school_letter_ids
    complete_practice_session(session)
    assert_equal 145, learner.reload.xp
    assert_equal 1, learner.part_unlocks.count

    post practice_sessions_path
    full_session = learner.active_session
    assert_equal "full", full_session.learning_mode
    assert_empty full_session.school_letter_ids
    full_snapshot = full_session.exercises.deep_dup
    save_settings(through_letter: "r")
    get practice_session_path(full_session)
    assert_response :success
    assert_equal full_snapshot, full_session.reload.exercises
    complete_practice_session(full_session)
    post practice_sessions_path
    assert_equal SchoolCurriculum.through("r"), learner.active_session.school_letter_ids
    assert_equal 2, learner.reload.part_unlocks.count
  end

  test "all school tasks render and a complete school mission earns the usual reward" do
    learner = school_learner
    session = PracticePlanner.start!(learner)
    while !session.reload.completed?
      if session.drive_pending?
        get practice_session_path(session)
        assert_redirected_to practice_session_drive_path(session)
        post skip_practice_session_drive_path(session)
        assert_redirected_to practice_session_path(session)
      end
      get practice_session_path(session)
      assert_response :success
      kind = session.current_exercise.fetch("kind")
      assert_select "[data-exercise][data-kind=?]", kind
      solve_current_exercise(session)
    end
    get practice_session_path(session)
    assert_response :success
    assert_equal 145, learner.reload.xp
    assert_select ".reward-screen", 1
    post practice_session_battle_path(session)
    assert_response :see_other
  end

  test "concrete school drawings appear in tasks and the meaning response" do
    learner = school_learner
    session = PracticePlanner.start!(learner)
    planner = SchoolPracticePlanner.new(learner, letter_ids: learner.school_letter_ids, variation: 0)
    task = planner.send(:build, SchoolWordBank.find("СТО"), Curriculum.find("s"), "build_word", "upper", 0)
    session.update!(exercises: [task] + session.exercises.drop(1))
    get practice_session_path(session)
    assert_response :success
    assert_select ".build-picture img.word-illustration[alt='']", count: 1 do |images|
      assert_match %r{\A/school_images/table\.svg\?v=[a-f0-9]{12}\z}, images.first["src"]
    end
    post practice_session_attempts_path(session), params: correct_attributes(task), as: :json
    assert_response :success
    assert_equal "СТО", response.parsed_body.fetch("meaning").fetch("word")
    assert_match %r{\A/school_images/table\.svg\?v=[a-f0-9]{12}\z}, response.parsed_body.fetch("meaning").fetch("image_url")
    assert_equal "", response.parsed_body.fetch("meaning").fetch("sentence")
  end

  test "empty forged and stale settings are rejected and another browser is untouched" do
    learner = school_learner
    other = Learner.create!(xp: 80)
    revision = learner.learning_settings_revision
    [[], [""], ["a", "invented"], ["a", { "id" => "m" }]].each do |ids|
      save_settings(letter_selection: "custom", school_letter_ids: ids, learner_id: other.id)
      assert_response :see_other
      assert_equal SchoolCurriculum.default_ids, learner.reload.school_letter_ids
      assert_equal revision, learner.learning_settings_revision
      assert flash[:alert].present?
    end
    save_settings(learning_mode: "forged")
    assert_equal revision, learner.reload.learning_settings_revision
    save_settings(through_letter: "r")
    save_settings(through_letter: "a", learning_settings_revision: revision)
    assert_equal SchoolCurriculum.through("r"), learner.reload.school_letter_ids
    assert_match(/већ промењена/, flash[:alert])
    assert_equal [80, "school", SchoolCurriculum.default_ids, 0], other.reload.values_at(:xp, :learning_mode, :school_letter_ids, :learning_settings_revision)
  end

  test "anonymous settings request cannot create a learner" do
    assert_no_difference "Learner.count" do
      patch learning_settings_path, params: { learning_mode: "full", learning_settings_revision: 0 }
      assert_response :unprocessable_entity
    end
  end

  test "persistent identity restores selected letters without a Rails session cookie" do
    learner = school_learner
    save_settings(through_letter: "r")
    second = ActionDispatch::Integration::Session.new(Rails.application)
    second.cookies[:cirilo_device] = cookies[:cirilo_device]
    second.get progress_path
    assert_equal 200, second.response.status
    second.post practice_sessions_path
    assert_equal 303, second.response.status
    assert_equal SchoolCurriculum.through("r"), learner.active_session.school_letter_ids
  end

  private

  def school_learner
    return @school_learner if @school_learner
    get root_path
    assert_response :success
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    @school_learner = Learner.for_device_token(jar.encrypted[:cirilo_device])
  end

  def save_settings(**attributes)
    patch learning_settings_path, params: { learning_mode: "school", letter_selection: "through", through_letter: "e",
      learning_settings_revision: school_learner.reload.learning_settings_revision }.merge(attributes)
  end
end
