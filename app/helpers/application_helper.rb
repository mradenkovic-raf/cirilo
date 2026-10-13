module ApplicationHelper
  def school_alphabet_letter(letter, learner)
    return letter unless learner.school_mode?

    entries = SchoolWordBank.picture_entries(learner.school_letter_ids)
      .select { |entry| entry.fetch("word").include?(letter.fetch("upper")) }
    entry = entries.min_by { |item| [item.fetch("word").start_with?(letter.fetch("upper")) ? 0 : 1, item.fetch("word").length, item.fetch("word")] }
    letter.merge("word" => entry ? entry.fetch("word") : letter.fetch("upper"), "emoji" => entry ? entry.fetch("emoji") : "✦", "image" => entry&.fetch("image", nil))
  end

  def word_illustration(emoji, image: nil)
    return emoji unless image && SchoolWordBank.image_paths.include?(image)

    image_tag(static_asset_path(image.delete_prefix("/")), alt: "", class: "word-illustration", draggable: false)
  end

  # Plain public assets have no build pipeline. A content version keeps cached
  # CSS and all relative module imports in step with the rendered page.
  def static_asset_path(name)
    digest = Digest::SHA256.file(Rails.public_path.join(name)).hexdigest.first(12)
    "/#{name}?v=#{digest}"
  end

  def static_module_imports
    %w[application.js workshop.js battle.js shop.js fx.js writing.js variety.js mission_path.js trace_pad.js trace.js dino_drive.js dino_drive_engine.js].to_h do |name|
      ["/#{name}", static_asset_path(name)]
    end
  end

  def ui_icon(name, **options)
    paths = {
      play: '<path d="m9 5 11 7-11 7z" fill="currentColor" stroke="none"/>',
      arrow: '<path d="M5 12h14m-6-6 6 6-6 6"/>',
      star: '<path d="m12 3 2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-3-5.6 3 1.1-6.2L3 9.6l6.2-.9z"/>',
      sound: '<path d="m11 4-6 5H2v6h3l6 5zM15 8a6 6 0 0 1 0 8m3-11a10 10 0 0 1 0 14"/>',
      muted: '<path d="m11 4-6 5H2v6h3l6 5zM16 9l6 6m0-6-6 6"/>',
      home: '<path d="m3 11 9-8 9 8M5 9v12h14V9M10 21v-7h4v7"/>',
      map: '<path d="m3 5 6-2 6 2 6-2v16l-6 2-6-2-6 2zm6-2v16M15 5v16"/>',
      tool: '<path d="M14 6a5 5 0 0 0-6 6l-5 5a3 3 0 0 0 4 4l5-5a5 5 0 0 0 6-6l-3 3-4-4z"/>',
      book: '<path d="M12 6C9 3 5 3 2 4v16c4-1 7-1 10 1 3-2 6-2 10-1V4c-3-1-7-1-10 2zm0 0v15"/>',
      pencil: '<path d="m14 4 6 6M3 21l2-7L16 3a2 2 0 0 1 3 0l2 2a2 2 0 0 1 0 3L10 19zM5 14l5 5"/>',
      check: '<path d="m5 12 4 4L19 6"/>',
      lock: '<rect x="5" y="10" width="14" height="11" rx="3"/><path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2"/>',
      reset: '<path d="M3 10a9 9 0 1 1 2 9M3 4v6h6"/>',
      heart: '<path d="M20 5a5 5 0 0 0-8 1 5 5 0 0 0-8-1c-5 5 8 15 8 15S25 10 20 5z"/>',
      bolt: '<path d="m14 2-9 12h6l-1 8 9-12h-6z"/>',
      close: '<path d="m6 6 12 12M6 18 18 6"/>',
      target: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>'
    }
    content_tag(:svg, (paths[name.to_sym] || paths[:star]).html_safe, { viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true, class: "icon" }.merge(options))
  end

  def colored_dino(learner, variant: :hero, unlocked: nil, color: nil, species: nil)
    selected_species = species || learner.try(:selected_dino) || "rex"
    svg = dino_svg(unlocked: unlocked.nil? ? learner.part_unlocks.count : unlocked,
      variant: variant, species: selected_species).to_s
    # Only the creature's skin colors change; the mint scene and gear stay intact.
    palettes = {
      "blue" => {
        "#A9DF50" => "#79C7F3", "#84C846" => "#56ACDB",
        "#62AD3B" => "#3D89B4", "#77BD3F" => "#499BCD",
        "#91D249" => "#68BAEA", "#C9EE86" => "#B5E3FF",
        "#EAF0A4" => "#DDEFF2", "#CBD883" => "#B7D6E0",
        "#416C36" => "#315D70", "#5F9D38" => "#407F9F",
        "#6CAD3D" => "#438DB4", "#427B35" => "#396D86",
        "#5E9836" => "#41819F"
      },
      "peach" => {
        "#A9DF50" => "#FFBD83", "#84C846" => "#EA9D66",
        "#62AD3B" => "#C67F4E", "#77BD3F" => "#DD8B59",
        "#91D249" => "#F3AE74", "#C9EE86" => "#FFE0B0",
        "#EAF0A4" => "#FFF0C1", "#CBD883" => "#E9D39B",
        "#416C36" => "#795238", "#5F9D38" => "#B87847",
        "#6CAD3D" => "#C5814F", "#427B35" => "#94562F",
        "#5E9836" => "#AC6C3F"
      },
      "ice" => {
        "#A9DF50" => "#B6EBF2", "#84C846" => "#83C6D9",
        "#62AD3B" => "#5AA2BB", "#77BD3F" => "#73B6CF",
        "#91D249" => "#9EDAE8", "#C9EE86" => "#EBFBFF",
        "#EAF0A4" => "#E9F8FA", "#CBD883" => "#BEDDE6",
        "#416C36" => "#3D6C81", "#5F9D38" => "#53879B",
        "#6CAD3D" => "#5B9BB3", "#427B35" => "#40778C",
        "#5E9836" => "#57879A"
      },
      "lava" => {
        "#A9DF50" => "#F68C65", "#84C846" => "#D96250",
        "#62AD3B" => "#B54940", "#77BD3F" => "#C95849",
        "#91D249" => "#E97B5C", "#C9EE86" => "#FFC08B",
        "#EAF0A4" => "#FFDCA3", "#CBD883" => "#E9B275",
        "#416C36" => "#773C38", "#5F9D38" => "#A24B3D",
        "#6CAD3D" => "#B75240", "#427B35" => "#8D4036",
        "#5E9836" => "#A74F41"
      },
      "cosmic" => {
        "#A9DF50" => "#BEA0EC", "#84C846" => "#9673CB",
        "#62AD3B" => "#7253A6", "#77BD3F" => "#8966BD",
        "#91D249" => "#AF8FDE", "#C9EE86" => "#E4D0FF",
        "#EAF0A4" => "#ECE0FA", "#CBD883" => "#C5B0DD",
        "#416C36" => "#594174", "#5F9D38" => "#765794",
        "#6CAD3D" => "#8060A8", "#427B35" => "#624587",
        "#5E9836" => "#775498"
      }
    }
    palette = palettes.fetch(color || learner.try(:dino_color), {})
    svg.gsub(/#[0-9a-f]{6}/i) { |color| palette.fetch(color.upcase, color) }.html_safe
  end

  def nav_item(label, path, icon)
    active = current_page?(path)
    link_to(path, class: "nav-item #{'active' if active}", "aria-current": active ? "page" : nil) { ui_icon(icon) + content_tag(:span, label) }
  end
end
