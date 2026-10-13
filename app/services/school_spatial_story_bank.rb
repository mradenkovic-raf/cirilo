class SchoolSpatialStoryBank
  # Use the actual inflected noun, not its dictionary form, when checking a
  # child's letters. A short phrase is enough to practise the relation.
  OBJECTS = {
    "clock" => "Сат", "egg" => "Јаје", "leaf" => "Лист",
    "ball" => "Лопта", "apple" => "Јабука"
  }.freeze
  ANCHORS = {
    "car" => { locative: "ауту", genitive: "аута", positions: %w[inside on beside in_front behind] },
    "table" => { locative: "столу", genitive: "стола", positions: %w[on beside in_front behind] },
    "box" => { locative: "кутији", genitive: "кутије", positions: %w[inside on beside in_front behind] },
    "backpack" => { locative: "ранцу", genitive: "ранца", positions: %w[inside on beside in_front behind] }
  }.freeze

  class << self
    def eligible(letter_ids)
      groups = StoryBank::POSITIONS.map do |position, relation|
        ANCHORS.flat_map do |anchor, forms|
          next [] unless forms.fetch(:positions).include?(position)

          OBJECTS.filter_map do |object, noun|
            sentence = "#{noun} #{relation.fetch(:word)} #{forms.fetch(relation.fetch(:grammatical_case))}."
            next unless SchoolCurriculum.known_text?(sentence, letter_ids)

            { "school_story" => true, "school_spatial" => true, "story_dimension" => "position",
              "story_sentence" => sentence, "object" => object, "anchor" => anchor, "position" => position }
          end
        end
      end
      # Mix relation families immediately, including a newly learned relation.
      # Offsetting each family's nouns/locations also varies consecutive scenes.
      groups = groups.each_with_index.map { |group, index| group.rotate(index * 2) }
      groups.map(&:length).max.to_i.times.flat_map { |index| groups.filter_map { |group| group[index] } }
    end

    def exercise(candidate, variation:)
      position = candidate.fetch("position")
      available = ANCHORS.fetch(candidate.fetch("anchor")).fetch(:positions)
      confuser = StoryBank::POSITION_CONFUSERS.fetch(position)
      positions = [position, confuser].select { |item| available.include?(item) }.uniq
      positions += (available - positions).rotate(variation).first(4 - positions.length)
      choices = positions.shuffle.each_with_index.map do |relation, index|
        { "value" => "S#{index + 1}", "scene" => { "dimension" => "position", "school_spatial" => true,
          "object" => candidate.fetch("object"), "anchor" => candidate.fetch("anchor"), "position" => relation } }
      end
      answer = choices.find { |choice| choice.fetch("scene").fetch("position") == position }.fetch("value")
      { "school_story" => true, "school_spatial" => true, "story_dimension" => "position",
        "story_context" => "", "story_sentence" => candidate.fetch("story_sentence"),
        "choices" => choices, "options" => choices.map { |choice| choice.fetch("value") },
        "answer" => answer, "prompt" => "Прочитај и изабери слику." }
    end
  end
end
