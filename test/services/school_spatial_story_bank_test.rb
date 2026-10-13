require "test_helper"

class SchoolSpatialStoryBankTest < ActiveSupport::TestCase
  test "short spatial phrases unlock only when the inflected nouns and relation are readable" do
    assert_empty SchoolSpatialStoryBank.eligible(SchoolCurriculum.default_ids)
    assert_empty SchoolSpatialStoryBank.eligible(SchoolCurriculum.through("j"))
    through_u = SchoolSpatialStoryBank.eligible(SchoolCurriculum.through("u"))
    assert_equal ["Јаје на ауту.", "Јаје у ауту.", "Сат на ауту.", "Сат у ауту."].sort,
      through_u.map { |candidate| candidate.fetch("story_sentence") }.sort
    assert_includes sentences_through("l"), "Сат на столу."
    assert_includes sentences_through("z"), "Сат иза стола."
    assert_not sentences_through("k").any? { |sentence| sentence.include?("поред") || sentence.include?("испред") }
    assert_includes sentences_through("d"), "Лопта поред стола."
    assert_includes sentences_through("d"), "Лопта испред стола."
    assert_includes sentences_through("ts"), "Јабука у ранцу."
  end

  test "all stages and an arbitrary subset have only readable short target phrases" do
    scopes = SchoolCurriculum.letters.map { |letter| SchoolCurriculum.through(letter.fetch("id")) }
    scopes += [%w[a t s u o], %w[a j b u k r n ts i z], %w[a l o p t n s u]]
    scopes.each do |ids|
      SchoolSpatialStoryBank.eligible(ids).each do |candidate|
        sentence = candidate.fetch("story_sentence")
        assert SchoolCurriculum.known_text?(sentence, ids), sentence
        assert_equal 3, sentence.split.length
        assert_operator sentence.scan(/[[:alpha:]]+/).map(&:length).max, :<=, 6
      end
    end
  end

  test "every target has four distinct spatial answers with no noun-only shortcut" do
    candidates = SchoolSpatialStoryBank.eligible(SchoolCurriculum.letters.map { |letter| letter.fetch("id") })
    assert_equal 95, candidates.length
    assert_equal candidates.length, candidates.map { |candidate| candidate.fetch("story_sentence") }.uniq.length
    candidates.each_with_index do |candidate, variation|
      task = SchoolSpatialStoryBank.exercise(candidate, variation: variation)
      scenes = task.fetch("choices").map { |choice| choice.fetch("scene") }
      assert_equal [candidate.fetch("object")], scenes.map { |scene| scene.fetch("object") }.uniq
      assert_equal [candidate.fetch("anchor")], scenes.map { |scene| scene.fetch("anchor") }.uniq
      assert_equal 4, scenes.map { |scene| scene.fetch("position") }.uniq.length
      assert_equal 4, task.fetch("options").uniq.length
      correct = task.fetch("choices").find { |choice| choice.fetch("value") == task.fetch("answer") }
      assert_equal candidate.fetch("position"), correct.fetch("scene").fetch("position")
      assert_not scenes.any? { |scene| scene.fetch("anchor") == "table" && scene.fetch("position") == "inside" }
    end
  end

  test "spatial practice appears in each eligible mission while reading and writing stay balanced" do
    learner = Learner.create!(school_letter_ids: SchoolCurriculum.through("u"))
    6.times do |variation|
      tasks = SchoolPracticePlanner.exercises(learner, letter_ids: learner.school_letter_ids, variation: variation)
      assert_equal 12, tasks.length
      assert_equal "ownership", tasks.fetch(1).fetch("story_dimension")
      assert_equal "position", tasks.fetch(10).fetch("story_dimension")
      assert tasks.fetch(10).fetch("school_spatial")
      assert_equal 2, tasks.count { |task| %w[trace write_word fill_letters].include?(task.fetch("kind")) }
    end
  end

  test "each readable relation appears within the first five spatial missions" do
    SchoolCurriculum.letters.each do |letter|
      ids = SchoolCurriculum.through(letter.fetch("id"))
      candidates = SchoolSpatialStoryBank.eligible(ids)
      assert_equal candidates.map { |candidate| candidate.fetch("position") }.uniq.sort,
        candidates.first(5).map { |candidate| candidate.fetch("position") }.uniq.sort
    end
    through_d = SchoolSpatialStoryBank.eligible(SchoolCurriculum.through("d"))
    assert_equal StoryBank::POSITIONS.keys.sort, through_d.first(5).map { |candidate| candidate.fetch("position") }.sort
    assert_operator through_d.first(6).map { |candidate| candidate.fetch("object") }.uniq.length, :>=, 2
    assert_operator through_d.first(6).map { |candidate| candidate.fetch("anchor") }.uniq.length, :>=, 2
  end

  test "spatial rendering uses visible drawings and no written answer labels" do
    ids = SchoolCurriculum.letters.map { |letter| letter.fetch("id") }
    SchoolSpatialStoryBank.eligible(ids).each_with_index do |candidate, variation|
      task = SchoolSpatialStoryBank.exercise(candidate, variation: variation)
      html = ApplicationController.render(partial: "practice_sessions/school_story", locals: { exercise: task })
      document = Nokogiri::HTML.fragment(html)
      assert_equal candidate.fetch("story_sentence"), document.at_css(".story-sentence").text
      buttons = document.css("button[data-answer]")
      assert_equal 4, buttons.length
      assert_equal 4, document.css("svg.school-spatial-scene").length
      assert_equal 4, buttons.map { |button| button.at_css("svg").inner_html }.uniq.length
      buttons.each do |button|
        assert_no_match(/[А-Яа-яЂђЈјЉљЊњЋћЏџ]/, button.text)
        assert_equal "true", button.at_css("svg")["aria-hidden"]
        assert_match(/\AСлика [1-4]\z/, button["aria-label"])
      end
    end
  end

  private

  def sentences_through(letter_id)
    SchoolSpatialStoryBank.eligible(SchoolCurriculum.through(letter_id)).map { |candidate| candidate.fetch("story_sentence") }
  end
end
