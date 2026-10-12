module StoryHelper
  def story_scene_svg(scene)
    scene = scene.to_h.with_indifferent_access
    art = case scene[:dimension]
    when "size"
      radius = scene[:size] == "small" ? 18 : 37
      story_object_svg(scene[:object], x: 100, y: 110 - radius, radius: radius)
    when "action"
      story_animal_svg(scene[:object], sleeping: scene[:action] == "sleep")
    when "place"
      object = story_object_svg(scene[:object], x: 100, y: 81, radius: 23)
      if scene[:place] == "backpack"
        <<~SVG
          <path d="M61 66Q39 67 50 116M140 66Q161 68 150 117" stroke="#72A9B0" stroke-width="10" stroke-linecap="round"/>
          <path d="M85 39V29Q100 16 116 29V39" stroke="#437E89" stroke-width="7"/>
          <rect x="58" y="34" width="85" height="94" rx="20" fill="#84C6CD" stroke="#467D88" stroke-width="3"/>
          <path d="M69 53H132" stroke="#E9FAF2" stroke-width="5" stroke-linecap="round"/>
          <path d="M69 98V73Q100 61 132 73V98Z" fill="#3F7280"/>
          #{object}
          <path d="M68 96Q100 106 133 96V113Q133 123 120 123H81Q68 123 68 113Z" fill="#5BABB7" stroke="#467D88" stroke-width="3"/>
          <path d="M81 113H120" stroke="#B3E9E6" stroke-width="3" stroke-linecap="round"/>
        SVG
      else
        <<~SVG
          <path d="M52 69 98 53 148 69 146 119 100 131 53 119Z" fill="#CB9972"/>
          <path d="M53 70 99 57 147 70 100 87Z" fill="#785B47"/>
          <path d="m53 70-19-12 46-16 19 15m48 13 20-13-47-15-21 15" fill="#EDD2A9" stroke="#B28B64" stroke-width="2" stroke-linejoin="round"/>
          #{object}
          <path d="M53 89 100 103 147 89 146 122 100 135 53 122Z" fill="#D8B184" stroke="#B28B64" stroke-width="2" stroke-linejoin="round"/>
          <path d="M100 103V135" stroke="#B28B64" stroke-width="2"/>
        SVG
      end
    else
      ""
    end
    content_tag(:svg, viewBox: "0 0 200 150", fill: "none", class: "story-scene", "aria-hidden": true, focusable: false) do
      raw('<ellipse cx="100" cy="132" rx="66" ry="7" fill="#233E35" opacity=".08"/>' + art)
    end
  end

  private

  def story_object_svg(object, x:, y:, radius:)
    if object == "apple"
      %(<g transform="translate(#{x} #{y}) scale(#{radius / 30.0})"><path d="M0-21C-31-45-46 0-20 27C-10 39-4 30 0 31C6 30 14 40 24 25C47-6 27-42 0-21Z" fill="#E8826A" stroke="#AB5149" stroke-width="3"/><path d="M0-21Q-3-32 4-41" stroke="#7D6946" stroke-width="5" stroke-linecap="round"/><path d="M4-32Q9-53 25-46Q29-34 4-32Z" fill="#7FAB59"/><path d="M-20-11Q-30-1-22 11" stroke="#FFD0A9" stroke-width="6" stroke-linecap="round"/></g>)
    else
      %(<g transform="translate(#{x} #{y})"><circle r="#{radius}" fill="#F6C268" stroke="#BE8750" stroke-width="2.5"/><path d="M#{-radius * 0.8} #{-radius * 0.56}Q#{-radius * 0.2} #{radius * 0.35} #{radius * 0.8} #{radius * 0.56}M#{radius * 0.56} #{-radius * 0.8}Q#{-radius * 0.3} #{-radius * 0.1} #{-radius * 0.56} #{radius * 0.8}" stroke="#629CA2" stroke-width="#{radius * 0.28}"/><circle cx="#{-radius * 0.23}" cy="#{-radius * 0.3}" r="#{radius * 0.14}" fill="#FFF1BC"/></g>)
    end
  end

  def story_animal_svg(object, sleeping:)
    cat = object == "cat"
    fill = cat ? "#E6AF79" : "#BA9577"
    dark = cat ? "#B78151" : "#886A58"
    if sleeping
      <<~SVG
        <ellipse cx="101" cy="121" rx="66" ry="11" fill="#D8E6CB"/>
        <path d="M152 95Q163 66 141 63" stroke="#{dark}" stroke-width="12" stroke-linecap="round"/>
        <ellipse cx="115" cy="99" rx="41" ry="26" fill="#{fill}"/>
        <path d="M130 95Q139 118 113 120H72" stroke="#{dark}" stroke-width="13" stroke-linecap="round"/>
        #{cat ? %(<path d="M51 85 47 60 69 73 87 65 92 91" fill="#{fill}" stroke="#{dark}" stroke-width="2"/>) : %(<ellipse cx="54" cy="83" rx="14" ry="23" transform="rotate(24 54 83)" fill="#{dark}"/>)}
        <ellipse cx="73" cy="94" rx="28" ry="22" fill="#{fill}"/>
        <path d="M56 92q6 6 12 0m8 0q6 6 12 0" stroke="#5E5148" stroke-width="3" stroke-linecap="round"/>
        <path d="m69 101 4 4 4-4" fill="#5E5148"/>
        #{cat ? '<path d="M52 101H37m17 5-15 4m49-9h16m-15 5 14 4" stroke="#9F724D" stroke-width="2" stroke-linecap="round"/>' : '<ellipse cx="74" cy="105" rx="13" ry="7" fill="#EAD6B9"/><ellipse cx="74" cy="100" rx="4" ry="3" fill="#66564B"/>'}
        <path d="M133 21a17 17 0 1 0 22 23 19 19 0 0 1-22-23Z" fill="#E8C677"/>
        <path d="m104 41 2 4 5 1-4 3 1 5-4-2-5 2 1-5-3-3 5-1z" fill="#E8C677"/>
      SVG
    else
      <<~SVG
        <path d="M54 83Q35 79 34 58" stroke="#{dark}" stroke-width="10" stroke-linecap="round"/>
        <path d="M72 100 59 119 43 120M109 103 129 123 146 119M80 103 97 122M117 94 141 104" stroke="#{dark}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
        <ellipse cx="91" cy="86" rx="41" ry="24" transform="rotate(-10 91 86)" fill="#{fill}"/>
        #{cat ? %(<path d="M119 65 113 33 138 46 155 36 158 69" fill="#{fill}" stroke="#{dark}" stroke-width="2"/>) : %(<ellipse cx="118" cy="59" rx="13" ry="26" transform="rotate(-28 118 59)" fill="#{dark}"/>)}
        <ellipse cx="137" cy="67" rx="27" ry="23" fill="#{fill}"/>
        <ellipse cx="155" cy="76" rx="16" ry="10" fill="#{cat ? fill : '#EAD6B9'}"/>
        <circle cx="142" cy="62" r="4" fill="#5E5148"/><circle cx="143" cy="61" r="1.3" fill="white"/>
        <circle cx="168" cy="73" r="3.5" fill="#5E5148"/>
        <path d="M146 82q9 6 15 0" stroke="#5E5148" stroke-width="2.5" stroke-linecap="round"/>
        #{cat ? '<path d="m155 68 17-5m-13 15 17 4" stroke="#9F724D" stroke-width="2" stroke-linecap="round"/>' : '<path d="M154 85v5q4 5 8-1v-5" fill="#E6998E"/>'}
        <path d="M22 86H39M17 97H36M25 108H39" stroke="#AAC1AA" stroke-width="4" stroke-linecap="round"/>
      SVG
    end
  end
end
