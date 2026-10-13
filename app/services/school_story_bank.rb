class SchoolStoryBank
  # The pictures form a cross product. Recognizing only the person or only the
  # object always leaves two possible answers, so the whole sentence matters.
  PEOPLE = [
    { "id" => "mother", "word" => "Мама" },
    { "id" => "father", "word" => "Тата" },
    { "id" => "grandmother", "word" => "Баба" },
    { "id" => "grandfather", "word" => "Деда" }
  ].freeze

  OBJECTS = [
    { "id" => "clock", "word" => "сат" },
    { "id" => "meat", "word" => "месо" },
    { "id" => "sieve", "word" => "сито" },
    { "id" => "dough", "word" => "тесто" },
    { "id" => "cake", "word" => "торту", "emoji" => "🎂" },
    { "id" => "egg", "word" => "јаје", "emoji" => "🥚" },
    { "id" => "car", "word" => "ауто", "emoji" => "🚗" },
    { "id" => "hat", "word" => "шешир", "emoji" => "👒" },
    { "id" => "leaf", "word" => "лист", "emoji" => "🍁" },
    { "id" => "lemon", "word" => "лимун", "emoji" => "🍋" },
    { "id" => "plum", "word" => "шљиву", "emoji" => "" },
    { "id" => "ball", "word" => "лопту", "emoji" => "⚽" },
    { "id" => "pear", "word" => "крушку", "emoji" => "🍐" },
    { "id" => "banana", "word" => "банану", "emoji" => "🍌" },
    { "id" => "grapes", "word" => "грозд", "emoji" => "🍇" },
    { "id" => "honey", "word" => "мед", "emoji" => "🍯" },
    { "id" => "bread", "word" => "хлеб", "emoji" => "🍞" },
    { "id" => "candle", "word" => "свећу", "emoji" => "🕯️" },
    { "id" => "flower", "word" => "цвет", "emoji" => "🌷" },
    { "id" => "hammer", "word" => "чекић", "emoji" => "🔨" }
  ].freeze

  class << self
    def eligible(letter_ids)
      people = PEOPLE.select { |person| known?("#{person.fetch('word')} има", letter_ids) }
      objects = OBJECTS.select { |object| known?(object.fetch("word"), letter_ids) }
      ownership = if people.length >= 2 && objects.length >= 2
        objects.product(people).map do |object, person|
          { "story_sentence" => "#{person.fetch('word')} има #{object.fetch('word')}.",
            "school_story" => true, "person" => person, "object" => object,
            "people" => people, "objects" => objects }
        end
      else
        []
      end

      ownership + existing_stories.select { |story| known?(story.fetch("story_sentence"), letter_ids) }
    end

    def exercise(letter_ids:, variation:)
      candidates = eligible(letter_ids)
      return if candidates.empty?

      candidate = candidates.fetch(variation % candidates.length)
      return existing_exercise(candidate) unless candidate.fetch("school_story")

      person = candidate.fetch("person")
      object = candidate.fetch("object")
      other_people = candidate.fetch("people") - [person]
      other_objects = candidate.fetch("objects") - [object]
      # Advance the alternative pair after a full rotation of target sentences.
      rotation = variation / candidates.length
      people = [person, other_people.fetch(rotation % other_people.length)].shuffle
      objects = [object, other_objects.fetch(rotation % other_objects.length)].shuffle
      scenes = people.product(objects).map do |actor, item|
        { "dimension" => "ownership", "person" => actor.fetch("id"),
          "object" => item.fetch("id"), "emoji" => item["emoji"] }
      end.shuffle
      choices = scenes.each_with_index.map { |scene, index| { "value" => "S#{index + 1}", "scene" => scene } }
      answer = choices.find do |choice|
        scene = choice.fetch("scene")
        scene.fetch("person") == person.fetch("id") && scene.fetch("object") == object.fetch("id")
      end.fetch("value")

      { "school_story" => true, "story_context" => "", "story_sentence" => candidate.fetch("story_sentence"),
        "story_dimension" => "ownership", "choices" => choices, "answer" => answer,
        "options" => choices.map { |choice| choice.fetch("value") },
        "prompt" => "Прочитај и изабери слику." }
    end

    private

    def known?(text, letter_ids)
      SchoolCurriculum.known_text?(text, letter_ids)
    end

    def existing_stories
      @existing_stories ||= (
        12.times.map { |variation| StoryBank.exercise(variation: variation) } +
        20.times.map { |variation| StoryBank.position_exercise(variation: variation) }
      ).map do |story|
        # The optional narrative contains harder words and is unnecessary here.
        story.merge("school_story" => false, "story_context" => "")
      end.freeze
    end

    def existing_exercise(candidate)
      candidate.deep_dup.tap do |task|
        # Reassign opaque answer values after shuffling, so their number never
        # identifies the target object, person, or position across missions.
        correct_scene = task.fetch("choices").find { |choice| choice.fetch("value") == task.fetch("answer") }.fetch("scene")
        task.fetch("choices").shuffle!.each_with_index do |choice, index|
          choice["value"] = "S#{index + 1}"
          task["answer"] = choice.fetch("value") if choice.fetch("scene") == correct_scene
        end
        task["options"] = task.fetch("choices").map { |choice| choice.fetch("value") }
      end
    end
  end
end
