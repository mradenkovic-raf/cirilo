module ShopHelper
  def shop_item_art(item, learner)
    case item.fetch("category")
    when "dino"
      colored_dino(nil, unlocked: 0, color: learner.dino_color, species: item.fetch("value"))
    when "color"
      colored_dino(nil, unlocked: 0, color: item.fetch("value"), species: learner.selected_dino)
    when "theme"
      shop_world_svg(item.fetch("value"))
    when "effect"
      symbols = { "stars" => ["✦", "★", "✧"], "lightning" => ["ϟ", "ϟ", "ϟ"], "comets" => ["☄", "✦", "☄"] }.fetch(item.fetch("value"))
      content_tag(:div, class: "effect-preview effect-preview--#{item.fetch('value')}", "aria-hidden": true) do
        safe_join(symbols.map { |symbol| content_tag(:span, symbol) }) + content_tag(:b, "БУМ!")
      end
    end
  end

  def shop_world_svg(world)
    scene = case world
    when "space"
      '<rect width="480" height="260" fill="#292b60"/><circle cx="363" cy="87" r="55" fill="#b7a4ff"/><ellipse cx="363" cy="87" rx="91" ry="18" stroke="#e7cf99" stroke-width="12" transform="rotate(-24 363 87)"/><circle cx="97" cy="179" r="82" fill="#5769b9"/><path d="M35 180Q99 119 159 180" stroke="#7287d0" stroke-width="18"/><path d="m115 45 3 9 10 3-10 3-3 9-3-9-10-3 10-3Zm112 70 4 13 13 4-13 4-4 13-4-13-13-4 13-4Z" fill="#ffe1a4"/><g fill="#fff4cf"><circle cx="54" cy="72" r="3"/><circle cx="182" cy="37" r="4"/><circle cx="438" cy="183" r="4"/><circle cx="279" cy="218" r="3"/></g>'
    when "volcano"
      '<rect width="480" height="260" fill="#ffe1b7"/><circle cx="369" cy="61" r="35" fill="#ffad60"/><path d="M0 221 148 64 201 69 391 260H0Z" fill="#8b5472"/><path d="m148 64 54 5 58 73-44-18-30-25-38 36-39 0Z" fill="#ff8058"/><path d="m176 93 25 47-9 38 26 38-2 44" fill="none" stroke="#ffcb5a" stroke-width="17"/><path d="M0 250q95-54 184-9t296-8v27H0" fill="#c37055"/><path d="M149 35q20-27 35-12t25-16" fill="none" stroke="#d8b2b4" stroke-width="18" stroke-linecap="round"/>'
    when "ocean"
      '<rect width="480" height="260" fill="#cbf1f1"/><path d="M0 72q60-25 120 0t120 0 120 0 120 0v188H0" fill="#4ab8cb"/><path d="M0 128q60-22 120 0t120 0 120 0 120 0v132H0" fill="#2388ac"/><path d="M0 226q75-28 149 4t160-1 171 5v26H0" fill="#f6d6a0"/><path d="M93 238v-61m0 23-23-20m23 37 27-31M360 241v-50m0 22-17-11m17 23 21-27" stroke="#ff9e8c" stroke-width="11" stroke-linecap="round"/><path d="m230 126-20-15v34l20-13q28 27 55-3-28-28-55-3" fill="#ffdb73"/><circle cx="275" cy="126" r="3" fill="#21485f"/><g fill="none" stroke="#b2ebee" stroke-width="3"><circle cx="328" cy="104" r="10"/><circle cx="342" cy="75" r="6"/><circle cx="187" cy="169" r="8"/></g>'
    else
      '<rect width="480" height="260" fill="#e1f0c6"/><circle cx="372" cy="69" r="35" fill="#ffda79"/><path d="M0 189q100-119 235-12T480 143v117H0" fill="#b6d77f"/><path d="M0 236q156-91 294-18t186-5v47H0" fill="#87b36c"/><path d="M89 214v-96m0 57-31-24m31-2 31-22" stroke="#638b52" stroke-width="12" stroke-linecap="round"/><circle cx="87" cy="106" r="47" fill="#78b376"/><circle cx="62" cy="128" r="32" fill="#78b376"/><circle cx="119" cy="121" r="30" fill="#78b376"/><path d="m320 215 4-10 4 10 11 1-9 7 3 10-9-6-9 6 3-10-9-7Z" fill="#ffedb0"/>'
    end
    content_tag(:svg, scene.html_safe, viewBox: "0 0 480 260", fill: "none", "aria-hidden": true, class: "shop-world")
  end
end
