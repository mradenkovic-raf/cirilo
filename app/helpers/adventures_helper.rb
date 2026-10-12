module AdventuresHelper
  # Local SVG art uses a fixed palette, with no external images or scripts.
  def adventure_friend(world, rescued: false)
    color = world.fetch(:color)
    shade = world.fetch(:shade)
    content_tag(:svg, viewBox: "0 0 160 160", fill: "none", class: "adventure-friend", "aria-hidden": true) do
      raw(<<~SVG)
        <ellipse cx="81" cy="141" rx="48" ry="9" fill="#193E35" opacity=".1"/>
        <path d="M44 112Q17 116 22 89Q26 106 47 94" fill="#{shade}"/>
        <path d="M49 83 39 71 54 68 47 54 66 57" fill="#{shade}"/>
        <path d="M46 106Q39 71 75 72Q106 76 107 108L101 136H86L83 117 70 117 65 136H48Z" fill="#{color}"/>
        <ellipse cx="76" cy="103" rx="19" ry="24" fill="#FFF9DD" opacity=".8"/>
        <path d="M68 76Q44 58 56 35Q64 18 91 26Q107 28 109 43Q138 43 135 63Q130 82 103 79L84 92Z" fill="#{color}"/>
        <path d="M61 100Q45 99 46 91M96 98Q111 98 113 88" stroke="#{shade}" stroke-width="10" stroke-linecap="round"/>
        <ellipse cx="91" cy="45" rx="7" ry="9" fill="#FFFDF4"/>
        <circle cx="94" cy="46" r="4" fill="#193E35"/><circle cx="95" cy="44" r="1.4" fill="white"/>
        <circle cx="122" cy="54" r="2" fill="#{shade}"/>
        <path d="M103 66Q115 74 124 65" stroke="#{shade}" stroke-width="3" stroke-linecap="round"/>
        <ellipse cx="98" cy="60" rx="7" ry="4" fill="#F58285" opacity=".55"/>
        #{rescued ? '<path d="m121 10 4 8 9 1-6 6 1 9-8-4-8 4 2-9-7-6 9-1z" fill="#FFD66D"/><path d="m29 45 3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1z" fill="#FFD66D"/>' : '<path d="M121 17v9m-4-5h8" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"/>'}
      SVG
    end
  end

  def adventure_landscape(world)
    scene = case world.fetch(:id)
    when "forest"
      '<path d="M0 81Q66 40 128 82T300 67V130H0Z" fill="#BBD4A1"/><path d="M20 95V24m42 79V47m186 52V27" stroke="#739468" stroke-width="8"/><path d="m20 1-24 53h49zm42 28-22 51h46zM248 0l-30 67h62z" fill="#82B976"/><path d="M170 82Q123 101 194 130h50q-81-30-49-42" fill="#9DD3DF"/>'
    when "cave"
      '<path d="M0 0h300v130H0Z" fill="#6F718D"/><path d="m0 0 24 49 27-33 22 34L99 8l37 21L170 0l37 45 25-22 25 47 43-27V0Z" fill="#555E7D"/><path d="m14 119 10-42 20 28 10-35 28 49zM220 126l-13-31 20-28 13 32 29-21 15 48z" fill="#B6AFE8"/><path d="m29 99 6 30m22-37 4 29m166-29 6 31m28-30 2 29" stroke="#E0D7FF" stroke-width="3"/>'
    when "volcano"
      '<path d="M0 130 97 17h63l105 113Z" fill="#BE7961"/><path d="m96 17-21 28 42 15 31-10 36 18-25-51Z" fill="#FFD17E"/><path d="m128 33-10 36 21 22-7 39h39l-16-43-17-18 17-36" fill="#F3A46A"/><path d="M0 117q60-19 113 2t187-6v17H0Z" fill="#EEB57F"/><path d="m213 60 9-10m-47-36 4-7m-100 0-7-9" stroke="#D28963" stroke-width="4" stroke-linecap="round"/>'
    else
      '<path d="M0 0h300v130H0Z" fill="#56678A"/><circle cx="235" cy="42" r="26" fill="#B8AEDF"/><ellipse cx="235" cy="43" rx="45" ry="9" transform="rotate(-20 235 43)" fill="none" stroke="#D7D4EE" stroke-width="6"/><path d="M0 113q140-43 300 7v10H0Z" fill="#93AAB7"/><g fill="#FDEBBB"><circle cx="30" cy="26" r="3"/><circle cx="121" cy="16" r="2"/><circle cx="177" cy="64" r="2"/><circle cx="286" cy="17" r="2"/><path d="m73 43 3 7 8 1-6 5 2 8-7-4-7 4 2-8-6-5 8-1z"/></g>'
    end
    content_tag(:svg, scene.html_safe, viewBox: "0 0 300 130", preserveAspectRatio: "xMidYMid slice", class: "adventure-landscape", "aria-hidden": true)
  end
end
