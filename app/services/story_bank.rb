class StoryBank
  POSITION_OBJECTS = { "apple" => "Јабука", "ball" => "Лопта" }.freeze
  POSITION_ANCHORS = {
    "backpack" => { locative: "ранцу", genitive: "ранца" },
    "box" => { locative: "кутији", genitive: "кутије" }
  }.freeze
  POSITIONS = {
    "inside" => { word: "у", grammatical_case: :locative },
    "on" => { word: "на", grammatical_case: :locative },
    "beside" => { word: "поред", grammatical_case: :genitive },
    "in_front" => { word: "испред", grammatical_case: :genitive },
    "behind" => { word: "иза", grammatical_case: :genitive }
  }.freeze
  POSITION_CONFUSERS = {
    "inside" => "on", "on" => "inside", "beside" => "in_front",
    "in_front" => "behind", "behind" => "in_front"
  }.freeze

  # Every group is a 2x2 cross product: matching the noun alone leaves two
  # possible pictures, as does matching only the attribute/action/place.
  GROUPS = [
    { dimension: "size", objects: %w[ball apple], values: %w[small large],
      context: "Клик бира шта носи на пут.",
      sentences: ["Узми малу лопту.", "Узми велику лопту.", "Узми малу јабуку.", "Узми велику јабуку."] },
    { dimension: "place", objects: %w[apple ball], values: %w[backpack box],
      context: "Клик је спаковао ствари за пут.",
      sentences: ["Пронађи јабуку у ранцу.", "Пронађи јабуку у кутији.", "Пронађи лопту у ранцу.", "Пронађи лопту у кутији."] },
    { dimension: "action", objects: %w[cat dog], values: %w[sleep run],
      context: "Клик тражи свог друга.",
      sentences: ["Покажи мачку која спава.", "Покажи мачку која трчи.", "Покажи пса који спава.", "Покажи пса који трчи."] }
  ].freeze

  def self.exercise(variation:)
    group = GROUPS.fetch(variation % GROUPS.length)
    target = (variation / GROUPS.length) % 4
    choices = group.fetch(:objects).product(group.fetch(:values)).each_with_index.map do |(object, value), index|
      { "value" => "S#{index + 1}", "scene" => { "dimension" => group.fetch(:dimension), "object" => object,
        group.fetch(:dimension) => value } }
    end
    # Size is a rendering property; the remaining dimensions have matching keys.
    choices.shuffle!
    { "story_context" => group.fetch(:context), "story_sentence" => group.fetch(:sentences).fetch(target),
      "story_dimension" => group.fetch(:dimension), "choices" => choices,
      "options" => choices.map { |choice| choice.fetch("value") }, "answer" => "S#{target + 1}",
      "prompt" => "Прочитај и уради шта прича тражи." }
  end

  def self.position_exercise(variation:)
    # The 5-position and 4-object/anchor cycles cover all 20 sentences before
    # repeating. Neighbouring missions change the object or anchor as well.
    position = POSITIONS.keys.fetch(variation % POSITIONS.length)
    object = POSITION_OBJECTS.keys.fetch(variation % POSITION_OBJECTS.length)
    anchor = POSITION_ANCHORS.keys.fetch((variation / POSITION_OBJECTS.length) % POSITION_ANCHORS.length)
    relation = POSITIONS.fetch(position)
    location = POSITION_ANCHORS.fetch(anchor).fetch(relation.fetch(:grammatical_case))
    positions = [position, POSITION_CONFUSERS.fetch(position)]
    positions += (POSITIONS.keys - positions).rotate(variation / POSITIONS.length).first(2)
    choices = positions.map do |option|
      { "value" => "S#{POSITIONS.keys.index(option) + 1}",
        "scene" => { "dimension" => "position", "object" => object, "anchor" => anchor, "position" => option } }
    end.shuffle

    { "story_context" => "", "story_sentence" => "#{POSITION_OBJECTS.fetch(object)} је #{relation.fetch(:word)} #{location}.",
      "story_dimension" => "position", "choices" => choices,
      "options" => choices.map { |choice| choice.fetch("value") },
      "answer" => "S#{POSITIONS.keys.index(position) + 1}",
      "prompt" => "Прочитај реченицу и пронађи слику." }
  end
end
