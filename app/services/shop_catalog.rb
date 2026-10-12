class ShopCatalog
  CATEGORY_ATTRIBUTES = {
    "dino" => "selected_dino", "color" => "dino_color",
    "theme" => "selected_theme", "effect" => "selected_effect"
  }.freeze

  ITEMS = [
    ["dino_rex", "dino", "Клик рекс", "Твој први диносаурус, спреман за сваку мисију.", 0, "rex"],
    ["dino_tricera", "dino", "Трицератопс", "Три рога и велики штит око главе.", 240, "tricera"],
    ["dino_stego", "dino", "Стегосаурус", "Нови друг са великим плочама на леђима.", 420, "stego"],
    ["dino_robo", "dino", "Робо-дино", "Метални истраживач са светлећим очима.", 600, "robo"],
    ["color_green", "color", "Зелена", "Боја шуме за твог диносауруса.", 0, "green"],
    ["color_blue", "color", "Плава", "Освежи диносауруса небескоплавом бојом.", 0, "blue"],
    ["color_peach", "color", "Бресква", "Топла наранџаста боја за нови дан.", 0, "peach"],
    ["color_ice", "color", "Ледена", "Боје леда и снежних кристала.", 120, "ice"],
    ["color_lava", "color", "Лава", "Жарке боје за вулканске пустоловине.", 120, "lava"],
    ["color_cosmic", "color", "Космичка", "Љубичасти сјај далеког свемира.", 180, "cosmic"],
    ["theme_meadow", "theme", "Ливада", "Позната зелена ливада за твоје мисије.", 0, "meadow"],
    ["theme_space", "theme", "Свемир", "Учи међу звездама и далеким планетама.", 220, "space"],
    ["theme_volcano", "theme", "Вулкан", "Пресели мисије у свет топлих вулканских боја.", 260, "volcano"],
    ["theme_ocean", "theme", "Океан", "Заплови кроз плави свет морских мисија.", 220, "ocean"],
    ["effect_stars", "effect", "Звездице", "Прослави тачан одговор сјајним звездицама.", 0, "stars"],
    ["effect_lightning", "effect", "Муње", "Нека твој успех засветли као муња.", 160, "lightning"],
    ["effect_comets", "effect", "Комете", "За сваки успех пролећу мале комете.", 220, "comets"]
  ].map do |row|
    %w[id category name description price value].zip(row).to_h.transform_values do |value|
      value.is_a?(String) ? value.freeze : value
    end.freeze
  end.freeze

  class << self
    def items
      ITEMS
    end

    def find(id)
      return unless id.is_a?(String)
      ITEMS.find { |item| item.fetch("id") == id }
    end

    def resolve(item_or_id)
      find(item_or_id.is_a?(Hash) ? item_or_id["id"] || item_or_id[:id] : item_or_id)
    end

    def values_for(category)
      ITEMS.select { |item| item.fetch("category") == category }.map { |item| item.fetch("value") }
    end

    def selection_attribute(item)
      CATEGORY_ATTRIBUTES.fetch(item.fetch("category"))
    end

    def previous_paid_items(item_or_id)
      item = resolve(item_or_id)
      return [] unless item && item.fetch("price").positive?

      category = ITEMS.select do |candidate|
        candidate.fetch("category") == item.fetch("category") && candidate.fetch("price").positive?
      end
      category.take(category.index(item))
    end

    def prerequisite_for(item_or_id)
      previous_paid_items(item_or_id).last
    end
  end
end
