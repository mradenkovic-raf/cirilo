require "test_helper"

class LearningSettingsTest < ActiveSupport::TestCase
  test "changing one browser settings never changes another browser or their saved sessions" do
    first = Learner.create!
    second = Learner.create!(school_letter_ids: %w[a m])
    first_session = PracticePlanner.start!(first)
    second_session = PracticePlanner.start!(second)
    saved = [first_session.attributes.deep_dup, second_session.attributes.deep_dup]
    LearningSettings.update!(first, mode: "school", selection: "through", through: "sh", letter_ids: nil, revision: 0)
    assert_equal SchoolCurriculum.through("sh"), first.reload.school_letter_ids
    assert_equal %w[a m], second.reload.school_letter_ids
    assert_equal saved, [first_session.reload.attributes, second_session.reload.attributes]
  end

  test "old settings cannot overwrite a later edit even if form sends foreign learner attributes" do
    learner = Learner.create!
    LearningSettings.update!(learner, mode: "full", selection: nil, through: nil, letter_ids: nil, revision: "0")
    assert_raises LearningSettings::InvalidRequest do
      LearningSettings.update!(learner, mode: "school", selection: "through", through: "a", letter_ids: nil, revision: "0")
    end
    assert_equal "full", learner.reload.learning_mode
    assert_equal SchoolCurriculum.default_ids, learner.school_letter_ids
  end

  test "mode and letter shape validation does not silently accept partial forged sets" do
    learner = Learner.create!
    [nil, "a", { "a" => "m" }, ["a", "zz"], ["a", nil]].each do |ids|
      assert_raises LearningSettings::InvalidRequest do
        LearningSettings.update!(learner, mode: "school", selection: "custom", through: nil, letter_ids: ids, revision: 0)
      end
      assert_equal SchoolCurriculum.default_ids, learner.reload.school_letter_ids
    end
  end
end
