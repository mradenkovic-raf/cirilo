require "test_helper"

class SchoolStoryBankTest < ActiveSupport::TestCase
  test "the default learned set has twenty distinct short comprehension sentences" do
    candidates = SchoolStoryBank.eligible(SchoolCurriculum.default_ids)
    assert_equal 20, candidates.length
    expected = %w[Мама Тата].product(%w[сат месо сито тесто семе сено тост со ананас сома]).map { |person, object| "#{person} има #{object}." }
    assert_equal expected.sort, candidates.map { |candidate| candidate.fetch("story_sentence") }.sort
    candidates.each do |candidate|
      assert SchoolCurriculum.known_text?(candidate.fetch("story_sentence"), SchoolCurriculum.default_ids)
      assert_operator candidate.fetch("story_sentence").scan(/[[:alpha:]]+/).map(&:length).max, :<=, 6
    end
  end

  test "every school stage uses only known letters including inflected word endings" do
    SchoolCurriculum.letters.each do |letter|
      ids = SchoolCurriculum.through(letter.fetch("id"))
      candidates = SchoolStoryBank.eligible(ids)
      candidates.each_index do |variation|
        task = SchoolStoryBank.exercise(letter_ids: ids, variation: variation)
        assert SchoolCurriculum.known_text?(task.fetch("story_sentence"), ids), task.fetch("story_sentence")
        assert_equal "", task.fetch("story_context")
        assert_equal 4, task.fetch("options").uniq.length
        assert_equal task.fetch("choices").map { |choice| choice.fetch("value") }, task.fetch("options")
        assert_equal 1, task.fetch("options").count(task.fetch("answer"))
        assert_nil task["word"]
      end
    end
    through_r = SchoolStoryBank.eligible(SchoolCurriculum.through("r"))
    assert_not through_r.any? { |candidate| candidate.fetch("story_sentence").include?("торту") }, "The accusative introduces У, so knowing ТОРТА is insufficient"
  end

  test "arbitrary parent selection cannot introduce missing letters through a story" do
    ids = %w[a m i s t o]
    candidates = SchoolStoryBank.eligible(ids)
    assert_equal ["Мама има сат.", "Тата има сат."], candidates.map { |candidate| candidate.fetch("story_sentence") }.grep(/сат/)
    candidates.each { |candidate| assert SchoolCurriculum.known_text?(candidate.fetch("story_sentence"), ids) }
    assert_not candidates.any? { |candidate| candidate.fetch("story_sentence").include?("месо") }
    assert_nil SchoolStoryBank.exercise(letter_ids: %w[a m], variation: 0)
    assert_empty SchoolStoryBank.eligible([])
  end

  test "ownership choices require reading both the person and the object" do
    ids = SchoolCurriculum.letters.map { |letter| letter.fetch("id") }
    (SchoolStoryBank.eligible(ids).length * 2).times do |variation|
      task = SchoolStoryBank.exercise(letter_ids: ids, variation: variation)
      next unless task["story_dimension"] == "ownership"

      scenes = task.fetch("choices").map { |choice| choice.fetch("scene") }
      assert_equal 4, scenes.uniq.length
      correct = task.fetch("choices").find { |choice| choice.fetch("value") == task.fetch("answer") }.fetch("scene")
      assert_equal 2, scenes.count { |scene| scene.fetch("person") == correct.fetch("person") }
      assert_equal 2, scenes.count { |scene| scene.fetch("object") == correct.fetch("object") }
      person = SchoolStoryBank::PEOPLE.find { |item| item.fetch("id") == correct.fetch("person") }
      object = SchoolStoryBank::OBJECTS.find { |item| item.fetch("id") == correct.fetch("object") }
      alternative = SchoolStoryBank::OBJECTS.find { |item| scenes.any? { |scene| scene.fetch("object") == item.fetch("id") && item != object } }
      if object["picture_group"]
        assert_not_equal object["picture_group"], alternative["picture_group"], "Related pictures must not provide two valid interpretations"
      end
      assert_equal "#{person.fetch('word')} има #{object.fetch('word')}.", task.fetch("story_sentence")
      assert_not_includes task.fetch("prompt"), person.fetch("word")
      assert_not_includes task.fetch("prompt"), object.fetch("word")
      task.fetch("choices").each { |choice| assert_match(/\AS[1-4]\z/, choice.fetch("value")) }
    end
  end

  test "illustrated ownership stories use the word bank artwork without exposing its name" do
    ids = SchoolCurriculum.default_ids
    candidates = SchoolStoryBank.eligible(ids)
    %w[seeds hay toast catfish].each do |object_id|
      variation = candidates.index { |candidate| candidate.fetch("object").fetch("id") == object_id }
      task = SchoolStoryBank.exercise(letter_ids: ids, variation: variation)
      correct_scene = task.fetch("choices").find { |choice| choice.fetch("value") == task.fetch("answer") }.fetch("scene")
      assert_includes SchoolWordBank.image_paths, correct_scene.fetch("image")
      html = ApplicationController.render(partial: "practice_sessions/school_story", locals: { exercise: task })
      document = Nokogiri::HTML.fragment(html)
      correct = document.at_css("button[data-answer='#{task.fetch('answer')}']")
      assert_match %r{\A/school_images/[a-z_]+\.svg\?v=[a-f0-9]{12}\z}, correct.at_css("image")["href"]
      assert_no_match(/[А-Яа-яЂђЈјЉљЊњЋћЏџ]/, correct.text)
    end
  end

  test "a complete rotation covers every eligible sentence before any repeats" do
    ids = SchoolCurriculum.default_ids
    count = SchoolStoryBank.eligible(ids).length
    sentences = (count * 2).times.map do |variation|
      SchoolStoryBank.exercise(letter_ids: ids, variation: variation).fetch("story_sentence")
    end
    assert_equal count, sentences.first(count).uniq.length
    assert_equal sentences.first(count), sentences.last(count)
  end

  test "the default mission's two consecutive stories change both person and object" do
    ids = SchoolCurriculum.default_ids
    count = SchoolStoryBank.eligible(ids).length
    scenes = count.times.map do |variation|
      task = SchoolStoryBank.exercise(letter_ids: ids, variation: variation)
      task.fetch("choices").find { |choice| choice.fetch("value") == task.fetch("answer") }.fetch("scene")
    end
    scenes.each_slice(2) do |first, second|
      assert_not_equal first.fetch("person"), second.fetch("person")
      assert_not_equal first.fetch("object"), second.fetch("object")
    end
  end

  test "borrowed stories retain their correct scene after answer ids are shuffled" do
    ids = SchoolCurriculum.letters.map { |letter| letter.fetch("id") }
    candidates = SchoolStoryBank.eligible(ids)
    candidates.each_with_index do |candidate, variation|
      next if candidate.fetch("school_story")

      original = candidate.fetch("choices").find { |choice| choice.fetch("value") == candidate.fetch("answer") }.fetch("scene")
      task = SchoolStoryBank.exercise(letter_ids: ids, variation: variation)
      actual = task.fetch("choices").find { |choice| choice.fetch("value") == task.fetch("answer") }.fetch("scene")
      assert_equal original, actual
      assert_equal "", task.fetch("story_context")
    end
  end

  test "school pictures render at every stage without exposing text answers inside choices" do
    ids = SchoolCurriculum.letters.map { |letter| letter.fetch("id") }
    SchoolStoryBank.eligible(ids).each_with_index do |candidate, variation|
      next unless candidate.fetch("school_story")

      task = SchoolStoryBank.exercise(letter_ids: ids, variation: variation)
      html = ApplicationController.render(partial: "practice_sessions/school_story", locals: { exercise: task })
      document = Nokogiri::HTML.fragment(html)
      assert_equal task.fetch("story_sentence"), document.at_css(".story-sentence").text
      assert_equal 4, document.css("button[data-answer]").length
      assert_equal 4, document.css("svg.school-story-scene").length
      document.css("button[data-answer]").each do |button|
        assert_no_match(/[А-Яа-яЂђЈјЉљЊњЋћЏџ]/, button.text)
        assert_match(/\AСлика [1-4]\z/, button["aria-label"])
        assert_equal "true", button.at_css("svg")["aria-hidden"]
      end
    end
  end
end
