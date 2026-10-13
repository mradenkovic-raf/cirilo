module SchoolStoriesHelper
  include StoryHelper

  def school_spatial_scene_svg(scene)
    scene = scene.to_h.with_indifferent_access
    anchor = scene.fetch(:anchor)
    position = scene.fetch(:position)
    back, front = school_spatial_anchor_svg(anchor)
    x, y = school_spatial_coordinates(anchor, position)
    item = school_spatial_object_svg(scene.fetch(:object), x: x, y: y)
    art = case position
    when "inside" then back + item + front
    when "behind" then item + back + front
    else back + front + item
    end

    content_tag(:svg, viewBox: "0 0 200 150", fill: "none", class: "story-scene school-story-scene school-spatial-scene",
      "aria-hidden": true, focusable: false) do
      raw('<ellipse cx="107" cy="136" rx="86" ry="7" fill="#233E35" opacity=".08"/>' + art)
    end
  end

  private

  def school_spatial_coordinates(anchor, position)
    case position
    when "inside" then [107, anchor == "car" ? 77 : 80]
    # A box is open in all four choices. Rest the object on its left flap,
    # rather than letting it float over the opening.
    when "on" then anchor == "box" ? [74, 53] : [107, { "car" => 31, "table" => 55, "backpack" => 41 }.fetch(anchor)]
    when "beside" then [177, 116]
    when "in_front" then [105, 123]
    when "behind" then [{ "table" => 144, "car" => 151, "box" => 143, "backpack" => 143 }.fetch(anchor), anchor == "table" ? 82 : 109]
    end
  end

  def school_spatial_anchor_svg(anchor)
    case anchor
    when "car"
      back = <<~SVG
        <rect x="58" y="100" width="20" height="35" rx="7" fill="#394850"/>
        <rect x="138" y="100" width="20" height="35" rx="7" fill="#394850"/>
        <path d="M69 80 79 53Q107 44 135 53L146 80 154 94V120Q153 130 141 131H75Q61 130 61 119V95Z" fill="#F5B44E" stroke="#AA712D" stroke-width="3"/>
        <path d="M81 57Q107 49 133 57L141 84H74Z" fill="#BCE3E7" stroke="#AA712D" stroke-width="3" stroke-linejoin="round"/>
        <path d="m85 59-7 21M129 58l7 22" stroke="#ECFFFF" stroke-width="3" stroke-linecap="round"/>
        <path d="M61 80H55M154 80H161" stroke="#AA712D" stroke-width="6" stroke-linecap="round"/>
      SVG
      front = <<~SVG
        <path d="M64 92Q107 87 151 92V119Q151 130 140 130H76Q64 130 64 119Z" fill="#F5B44E" stroke="#AA712D" stroke-width="3"/>
        <path d="M78 95H138L143 106H72Z" fill="#E89A3F"/>
        <path d="M82 113H132" stroke="#AA712D" stroke-width="7" stroke-linecap="round"/>
        <ellipse cx="75" cy="109" rx="9" ry="6" fill="#FFF8C4" stroke="#AA712D" stroke-width="2"/>
        <ellipse cx="140" cy="109" rx="9" ry="6" fill="#FFF8C4" stroke="#AA712D" stroke-width="2"/>
        <path d="M75 124H141" stroke="#D6E0DC" stroke-width="5" stroke-linecap="round"/>
      SVG
      [back, front]
    when "table"
      [<<~SVG, ""]
        <path d="M59 87V127Q64 133 69 127V88M138 83V125Q143 131 148 125V81M92 96V137H103V96" fill="#A06D47" stroke="#795434" stroke-width="2" stroke-linejoin="round"/>
        <path d="m49 80 66-20 45 20v9L94 109 49 89Z" fill="#B78653" stroke="#795434" stroke-width="2" stroke-linejoin="round"/>
        <path d="m49 80 66-20 45 20-66 20Z" fill="#E5BF81" stroke="#795434" stroke-width="2" stroke-linejoin="round"/>
        <path d="m69 80 47-14m-34 20 48-14m-34 19 47-14" stroke="#C99E67" stroke-width="2" stroke-linecap="round"/>
      SVG
    else
      story_position_anchor_svg(anchor)
    end
  end

  def school_spatial_object_svg(object, x:, y:)
    art = case object
    when "clock"
      <<~SVG
        <circle r="19" fill="#75B8C7" stroke="#386C7B" stroke-width="2.5"/><circle r="14.5" fill="#FFFBEC"/>
        <path d="M0-12V-10M12 0H10M0 12V10M-12 0H-10" stroke="#546D67" stroke-width="1.5"/>
        <path d="M0-8V0H7" stroke="#405C55" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
      SVG
    when "egg"
      '<path d="M0-21C-10-21-20-1-18 10Q-17 21 0 21Q17 21 18 10C20-1 10-21 0-21Z" fill="#FFF1D9" stroke="#AC895D" stroke-width="2.5"/><path d="M-7-9Q-12 0-11 5" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>'
    when "leaf"
      '<path d="M-16 17Q-29-12 15-24Q29 13-16 17Z" fill="#77AD50" stroke="#467736" stroke-width="2"/><path d="M-21 24 12-16M-11 13-14 0M-4 5 10 6M3-3 1-12" stroke="#467736" stroke-width="2.5" stroke-linecap="round"/>'
    when "apple", "ball"
      return story_object_svg(object, x: x, y: object == "apple" ? y - 2 : y, radius: 19)
    else
      raise ArgumentError, "Unknown school story object: #{object}"
    end
    %(<g transform="translate(#{x} #{y})">#{art}</g>)
  end
end
