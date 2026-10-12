module WorkshopHelper
  FRIEND_ACTIVITIES = {
    "forest" => { label: "Игра се лоптом", description: "Игра се лоптом у дворишту.", cheer: "ХВАЛА, ДРУГАРУ!", greeting: "Лиско: Спасио си ме! Хајде да се играмо!" },
    "cave" => { label: "Слаже кристале", description: "Слаже своје светлеће кристале.", cheer: "СИЈАМО ЗАЈЕДНО!", greeting: "Искра: Хвала ти! Ови кристали су за нас." },
    "volcano" => { label: "Гради кулу", description: "Гради кулу од шарених коцки.", cheer: "КУЛА ЗА ЕКИПУ!", greeting: "Жарко: Спасио си ме! Градим нам кулу." },
    "space" => { label: "Спрема ракету", description: "Спрема своју малу ракету за нову авантуру.", cheer: "ДО ЗВЕЗДА!", greeting: "Звездан: Вратио си ме кући! До звезда!" }
  }.transform_values(&:freeze).freeze

  def workshop_friend_activity(world)
    FRIEND_ACTIVITIES.fetch(world.fetch(:id))
  end

  # The saved friend artwork stays recognizable; local props turn each into a small scene.
  def workshop_friend_scene(world)
    props = case world.fetch(:id)
    when "forest"
      '<g class="friend-prop friend-ball"><circle cx="149" cy="131" r="19" fill="#F5CB6C"/><path d="M133 121q18 3 22 27m-25-13q23-20 31-15" stroke="#DB885C" stroke-width="4"/><circle cx="147" cy="129" r="5" fill="#FFF0AC"/></g><path d="M33 149v-10m-5 6 5 2 5-5" stroke="#96BD68" stroke-width="3" stroke-linecap="round"/>'
    when "cave"
      '<g class="friend-prop friend-crystals"><path d="m125 145-5-23 13-23 14 24-5 22z" fill="#C4B7FA"/><path d="m147 145-5-17 13-18 14 18-5 17z" fill="#8ACDE0"/><path d="m134 106-1 36m23-25-3 24" stroke="#EFF0FF" stroke-width="3"/><path d="m116 96 3-6 3 6 6 3-6 3-3 6-3-6-6-3zm43-15 2-4 2 4 5 2-5 2-2 5-2-5-4-2z" fill="#F7E59B"/></g>'
    when "volcano"
      '<g class="friend-prop friend-tower"><rect x="127" y="121" width="38" height="25" rx="4" fill="#EDBE68"/><rect x="133" y="96" width="28" height="25" rx="4" fill="#80B5C7"/><path d="m133 95 13-22 15 22z" fill="#E99179"/><path d="M133 130h25m-18-26h14" stroke="#FFF4CB" stroke-width="3" stroke-linecap="round"/></g><rect x="106" y="133" width="15" height="14" rx="3" fill="#A8CB7D"/>'
    else
      '<g class="friend-prop friend-rocket"><path d="m150 120-8 25 8-6 8 6-8-25" fill="#FAC16B"/><path d="m141 94-10 29 11-4m18-25 10 29-11-4" fill="#CE98BD"/><path d="M140 123V98q0-18 10-29 11 11 11 29v25z" fill="#E1E3DF"/><path d="M143 84q3-9 7-15 5 6 8 15z" fill="#A1CDE7"/><circle cx="150" cy="100" r="6" fill="#688FA8"/><path d="M144 119h13" stroke="#9CAEC2" stroke-width="3"/></g><path d="m123 73 3-6 3 6 7 2-7 3-3 6-3-6-6-3z" fill="#F7DD8F"/>'
    end
    content_tag(:svg, viewBox: "0 0 190 165", fill: "none", class: "friend-activity-scene", "aria-hidden": true) do
      safe_join([
        '<ellipse cx="97" cy="148" rx="83" ry="13" fill="#B4CC84" opacity=".18"/><g class="friend-body"><svg x="5" y="0" width="143" height="155" viewBox="0 0 160 160">'.html_safe,
        adventure_friend(world),
        '</svg></g>'.html_safe,
        props.html_safe
      ])
    end
  end
end
