module EggsHelper
  def egg_caption(egg)
    return "Изабери своје јаје" unless egg.chosen?
    return egg.name.presence || "Твој нови другар!" if egg.hatched?
    ["Још 3 мисије до другара", "Пук! Још 2 мисије", "Неко вири! Још 1 мисија", "Спреман је да изађе!"][egg.stage]
  end

  def egg_picture(stage)
    content_tag(:svg, viewBox: "0 0 160 170", fill: "none", class: "egg-picture", "aria-hidden": true) do
      safe_join([
        '<ellipse cx="80" cy="149" rx="67" ry="15" fill="#CAA776"/><path d="m23 145 19 9m-4-17 25 20m37-14 22 10m-2-19 21 13" stroke="#AE885B" stroke-width="5" stroke-linecap="round"/><path d="M80 13C56 13 31 64 31 99a49 49 0 0 0 98 0C129 64 104 13 80 13Z" fill="#FFE5A0" stroke="#CDA967" stroke-width="3"/><ellipse cx="62" cy="47" rx="9" ry="14" fill="#FFF5D9" transform="rotate(25 62 47)"/><circle cx="103" cy="74" r="9" fill="#F1C575"/><circle cx="53" cy="108" r="11" fill="#F1C575"/><circle cx="93" cy="128" r="7" fill="#F1C575"/>'.html_safe,
        (stage >= 1 ? '<path d="m78 15-9 26 16 15-17 18 12 18-9 21" stroke="#9A7849" stroke-width="4" stroke-linejoin="round"/>' : '').html_safe,
        (stage >= 2 ? '<path d="m69 65 14-11 18 12-5 23-19 5-13-13Z" fill="#294F36"/><ellipse cx="84" cy="73" rx="10" ry="13" fill="#FFFDF4"/><circle cx="88" cy="73" r="5" fill="#193E35"/><circle cx="90" cy="70" r="2" fill="white"/>' : '').html_safe
      ])
    end
  end
end
