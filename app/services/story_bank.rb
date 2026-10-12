class StoryBank
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
end
