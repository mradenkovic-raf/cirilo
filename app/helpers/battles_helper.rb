module BattlesHelper
  BATTLE_MOVE_NAMES = { "attack" => "Удар", "guard" => "Штит", "feint" => "Варка" }.freeze
  BATTLE_POWERS = {
    "goggles" => { name: "Наочаре", action: "Откриј потез", description: "Погледај шта ће Мргуд изабрати. Затим бираш ти.", gear: "Истраживачке наочаре", icon: "goggles" },
    "shield" => { name: "Светлосни штит", action: "Укључи штит", description: "Чува те од првог поготка. Чека и кад погодиш ти!", gear: "Светлосни штит", icon: "guard" },
    "rockets" => { name: "Ракетни скок", action: "Избегни потез", description: "Нико не губи живот. Ову рунду не нападаш.", gear: "Ракетне чизмице", icon: "dodge" }
  }.freeze

  def battle_result_title(state)
    return "Наочаре су откриле потез!" if state[:pending_power] == "goggles"
    return "Светлосни штит је укључен!" if state[:pending_power] == "shield"
    { "win" => "Клик погађа!", "lose" => "Мргуд погађа.", "tie" => "Исто! Нико није погођен.",
      "blocked" => "Штит је сачувао Клика!", "dodge" => "Хоп! Клик је избегао потез." }[state[:outcome]] || "Додирни један потез."
  end

  def battle_result_detail(state)
    if state[:pending_power] == "goggles"
      return "Мргуд бира: #{BATTLE_MOVE_NAMES[state[:revealed_enemy_move]]}. Сада бираш ти!"
    end
    return "Изабери потез. Штит те чува." if state[:pending_power] == "shield"
    return state[:feedback] if %w[blocked dodge].include?(state[:outcome])
    return "Пробај други потез!" if state[:outcome] == "tie"
    return "Оклоп чува срца." unless state[:outcome]
    if %w[win lose].include?(state[:outcome])
      enemy = state[:outcome] == "win"
      armor_lost = (enemy ? state[:enemy_hp] : state[:player_hp]).to_i >= Battle::BASE_HP
      return "#{enemy ? 'Мргуд' : 'Клик'} губи #{armor_lost ? 'део оклопа' : 'срце'}."
    end
    winner = state[:outcome] == "win" ? state[:player_move] : state[:enemy_move]
    { "attack" => "Удар прекида варку.", "guard" => "Штит зауставља удар.", "feint" => "Варка пролази поред штита." }[winner]
  end

  def battle_power_status(power, status)
    return "Освоји: #{BATTLE_POWERS.fetch(power).fetch(:gear)}" unless status[:owned]
    return "Штит укључен" if status[:armed]
    return "Искоришћено" if status[:used]
    "1×"
  end

  def battle_player_svg(state)
    state = state.with_indifferent_access
    colored_dino(nil, variant: :compact, unlocked: state.fetch(:armor_remaining).to_i,
      color: state[:dino_color], species: state[:dino_species] || "rex")
  end

  def battle_move_icon(move)
    shapes = {
      "attack" => '<path d="M18 42L31 29L35 12L52 12L52 27L40 43L28 49Z" fill="#FFD36C"/><path d="M33 28L38 17H46V25L36 36" fill="#FFF0B1"/><path d="M17 41L26 34L39 46L30 56Z" fill="#E66C50"/><path d="M14 22L20 27M10 34H17M29 9L27 17" stroke="currentColor" stroke-width="4" stroke-linecap="round"/>',
      "guard" => '<path d="M32 8L53 17V34C50 46 42 54 32 59C22 54 14 46 11 34V17Z" fill="#83D9CD"/><path d="M32 15L46 22V33C44 42 38 48 32 51C26 48 20 42 18 33V22Z" fill="#328C84"/><path d="M25 32L30 37L41 25" stroke="#E4FFF2" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>',
      "feint" => '<path d="M12 20C24 8 43 9 50 23L43 24L53 36L60 20L54 22C46 2 22 2 8 15Z" fill="#D4B0F1"/><path d="M50 44C37 55 20 51 13 38L20 37L9 26L3 42L9 40C18 60 40 64 55 49Z" fill="#AB7ACF"/><circle cx="33" cy="31" r="9" fill="#F4E5FF"/><path d="M29 31H29.1M36 31H36.1" stroke="#77528D" stroke-width="3" stroke-linecap="round"/>',
      "goggles" => '<path d="M5 22H59V43H5Z" rx="8" fill="#397581"/><rect x="8" y="20" width="20" height="27" rx="8" fill="#8AE7E4"/><rect x="36" y="20" width="20" height="27" rx="8" fill="#8AE7E4"/><path d="M28 30H36M13 26L21 26M41 26L49 26" stroke="#ECFFFD" stroke-width="4" stroke-linecap="round"/><circle cx="19" cy="35" r="5" fill="#337484"/><circle cx="45" cy="35" r="5" fill="#337484"/>',
      "dodge" => '<path d="M24 37C24 22 33 11 49 7C54 23 46 37 32 43Z" fill="#ACDCDD"/><path d="M24 29L14 33L10 45L25 39M36 42L32 54L44 50L48 35" fill="#6B98C2"/><circle cx="39" cy="23" r="6" fill="#FFF6C5"/><path d="M25 42L18 56L12 51L8 54L11 42Z" fill="#FFB862"/><path d="M24 46L17 51L16 43Z" fill="#FFF2AC"/><path d="M8 22L5 17M20 13L19 7" stroke="#9AB6B4" stroke-width="3" stroke-linecap="round"/>',
      "heart" => '<path d="M32 55C26 50 8 38 8 24C8 8 25 7 32 19C40 7 56 8 56 24C56 38 39 50 32 55Z" fill="currentColor"/>',
      "armor" => '<path d="M19 7L10 14L5 29L16 34L18 57H46L48 34L59 29L54 14L45 7L40 16H24Z" fill="currentColor" stroke="currentColor" stroke-width="3" stroke-linejoin="round"/><path d="M24 8L26 15H38L40 8M19 23L23 49H41L45 23" stroke="#ECFFFF" stroke-opacity=".75" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M32 22V45M25 35H39" stroke="#163B4A" stroke-opacity=".45" stroke-width="4" stroke-linecap="round"/>',
      "medal" => '<path d="M17 38L9 61L27 54L33 62L38 37M36 37L40 61L49 55L60 60L53 36" fill="#FF8467"/><circle cx="34" cy="27" r="23" fill="#DFA74C"/><circle cx="34" cy="25" r="20" fill="#FFD779"/><path d="M34 12L38 20L48 21L41 28L43 38L34 33L25 38L27 28L20 21L30 20Z" fill="#B17A32"/>',
      "crystal" => '<path d="M20 9H45L57 27L32 59L7 27Z" fill="#72C9D1"/><path d="M20 9L25 27H7ZM45 9L40 27H57Z" fill="#B4EDF0"/><path d="M25 27H40L32 59Z" fill="#C6F4E5"/><path d="M20 9H45L40 27H25Z" fill="#83D7CB"/><path d="M11 27H53" stroke="#E2FFF1" stroke-width="2"/>'
    }
    %(<svg class="battle-move-icon" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">#{shapes.fetch(move.to_s, shapes['attack'])}</svg>).html_safe
  end

  def battle_enemy_svg(state)
    state = state.with_indifferent_access
    armor = [state.fetch(:enemy_hp).to_i - 3, 0].max
    <<~SVG.html_safe
      <svg class="enemy-scene" viewBox="0 0 520 440" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Мргуд, противнички диносаурус, #{armor} делова оклопа">
        <title>Мргуд, чувар арене</title>
        <ellipse cx="281" cy="391" rx="157" ry="15" fill="#291E45" fill-opacity=".16"/>
        <g class="enemy-character">
          <path d="M330 298C383 325 424 307 451 275C458 266 468 271 464 282C448 333 405 363 337 343Z" fill="#8254AA"/>
          <path d="M363 326C403 335 441 305 449 289" stroke="#63398D" stroke-width="7" stroke-linecap="round"/>
          <path d="M360 309L370 293L384 315M394 309L400 289L413 303M427 291L433 273L443 277" fill="#E87981"/>
          #{armor >= 4 ? '<path d="M394 309L411 301L423 322L407 332Z" fill="#3B3158"/><path d="M404 306L415 326" stroke="#FF9A94" stroke-width="6"/><path d="M374 316L389 313L397 336L380 340Z" fill="#3B3158"/>' : ''}
          <path d="M253 324L247 363L231 371C220 376 224 388 235 389H281L292 328Z" fill="#8254AA"/>
          #{armor >= 1 ? '<path d="M247 357H285L282 374C297 379 291 391 281 394H230C218 390 224 377 237 372Z" fill="#3B3158"/><path d="M249 362H277L274 375H241Z" fill="#E87981"/>' : ''}
          <path d="M345 211L373 220L357 238L383 252L363 270L380 291L350 297L335 263Z" fill="#D96979"/>
          #{armor >= 10 ? '<path d="M348 208L375 209L365 236L390 249L371 270L387 293L354 306L338 261Z" fill="#3B3158"/><path d="M357 218L364 216L355 241L379 251L359 272L374 289L358 294" stroke="#FF9989" stroke-width="5" stroke-linejoin="round"/>' : ''}
          #{armor >= 12 ? '<path d="M365 307L371 355L383 341L394 354L399 309" fill="#F8BA6B"/><path d="M374 311L380 339L386 326L390 338L393 309" fill="#EE7A80"/><rect x="358" y="239" width="44" height="79" rx="17" fill="#3B3158"/><path d="M374 252V292" stroke="#D4A2F1" stroke-width="9" stroke-linecap="round"/><path d="M356 265L342 276L351 310L367 304" fill="#E87981"/>' : ''}
          <path d="M239 215C219 235 211 272 219 307C230 349 263 367 310 357C345 350 360 324 356 283C353 249 334 216 308 205Z" fill="#A677C7"/>
          <path d="M330 232C355 273 348 325 319 346C351 339 362 314 354 280C350 259 343 246 330 232Z" fill="#8254AA"/>
          <path d="M268 250C246 249 229 268 232 292C234 322 253 344 278 340C302 336 312 309 305 282C300 263 286 250 268 250Z" fill="#D4B4E4"/>
          <path d="M243 280C258 285 279 284 294 279M243 297C260 303 278 301 298 295M252 317C265 321 279 319 293 314" stroke="#B592CC" stroke-width="4" stroke-linecap="round"/>
          #{armor >= 3 ? '<path d="M235 259L264 247L300 256L305 294L273 325L239 304Z" fill="#3B3158"/><path d="M243 265L265 256L292 263L297 291L273 314L247 298Z" fill="#D96979"/><path d="M269 267L280 285L274 299L264 282Z" fill="#FFCF9B"/>' : ''}
          #{armor >= 7 ? '<path d="M233 326C267 339 308 337 341 319L344 331C310 350 267 351 237 340Z" fill="#3B3158"/><rect x="274" y="331" width="24" height="16" rx="4" fill="#F7BE74"/><rect x="279" y="335" width="14" height="7" rx="2" fill="#6D457E"/>' : ''}
          <path d="M319 323C331 335 334 356 329 371L341 377C352 383 345 394 334 394H289C280 389 284 378 297 375L289 337Z" fill="#A677C7"/>
          <path d="M308 385V393M324 385V393" stroke="#63398D" stroke-width="4" stroke-linecap="round"/>
          #{armor >= 1 ? '<path d="M293 361L329 362L332 375C346 375 355 387 345 395H286C279 389 282 379 291 375Z" fill="#3B3158"/><path d="M299 365L325 366L328 378H294Z" fill="#E87981"/><path d="M286 395H344" stroke="#29243D" stroke-width="6" stroke-linecap="round"/>' : ''}
          #{armor >= 8 ? '<path d="M289 331L307 325L323 335L319 353L300 358L289 349Z" fill="#3B3158"/><path d="M296 335L306 332L315 338L312 347L301 351L296 346Z" fill="#E87981"/>' : ''}
          <path d="M233 270C218 282 205 277 197 266C190 257 180 262 184 275C192 298 219 303 239 290" fill="#B98ED6"/>
          <path d="M199 280L194 287M208 284L205 292" stroke="#8254AA" stroke-width="3" stroke-linecap="round"/>
          #{armor >= 2 ? '<path d="M207 272L195 258C185 256 176 266 180 276L191 291L210 286Z" fill="#3B3158"/><path d="M196 266L201 278L190 282L184 273L188 266Z" fill="#E87981"/>' : ''}
          #{armor >= 5 ? '<path d="M226 258C233 251 246 255 249 266L242 282L226 281L216 269Z" fill="#3B3158"/><path d="M230 260L239 262L240 270L233 276L224 268Z" fill="#D4A2F1"/><path d="M334 252L350 250L362 266L355 282L337 280L328 264Z" fill="#3B3158"/><path d="M340 257L349 256L355 266L350 274L342 273L335 264Z" fill="#E87981"/>' : ''}
          #{armor >= 11 ? '<path d="M181 259L207 271V291C204 306 193 318 181 324C168 318 158 306 155 291V271Z" fill="#3B3158"/><path d="M181 269L199 277V289C195 301 189 308 181 314C173 308 166 301 164 289V277Z" fill="#D4A2F1"/><path d="M183 276L173 290L182 289L178 303L192 285H183Z" fill="#FFDCB9"/>' : ''}
          <path d="M334 130C327 88 295 65 253 74C223 80 204 102 204 136C169 130 137 141 129 166C119 198 150 225 188 230L265 234C310 234 340 211 342 177C343 159 339 143 334 130Z" fill="#A677C7"/>
          <path d="M333 139C339 174 328 205 296 221L231 232C278 241 316 230 333 207C344 190 346 164 333 139Z" fill="#8254AA"/>
          <path d="M313 110C301 91 281 86 266 88" stroke="#CBA6E4" stroke-width="9" stroke-linecap="round"/>
          <path d="M189 151C170 143 149 152 141 163" stroke="#CBA6E4" stroke-width="6" stroke-linecap="round"/>
          <path d="M240 79L243 54L261 73M280 75L294 54L304 88M313 89L335 76L335 110" fill="#D96979"/>
          <ellipse cx="232" cy="140" rx="18" ry="26" fill="#FFF3CD"/><ellipse cx="229" cy="144" rx="9" ry="14" fill="#392D4C"/><circle cx="226" cy="138" r="3.5" fill="#FFF"/>
          <ellipse cx="282" cy="143" rx="26" ry="33" fill="#FFF3CD"/><ellipse cx="275" cy="148" rx="12" ry="18" fill="#392D4C"/><circle cx="271" cy="141" r="5" fill="#FFF"/>
          <path d="M211 115L240 123M264 125L302 115" stroke="#583B76" stroke-width="8" stroke-linecap="round"/>
          <ellipse cx="152" cy="174" rx="4" ry="5" fill="#70438F"/><ellipse cx="176" cy="171" rx="4" ry="5" fill="#70438F"/>
          <path d="M169 196C191 209 221 208 250 194" stroke="#503665" stroke-width="5" stroke-linecap="round"/><path d="M189 204L194 214L201 207M224 206L231 215L234 202" fill="#FFF4D9"/>
          <circle cx="315" cy="164" r="5" fill="#8254AA"/><circle cx="319" cy="178" r="3" fill="#8254AA"/>
          #{armor >= 6 ? '<path d="M306 90L325 59L332 66L324 109" fill="#3B3158"/><path d="M324 110L339 88L347 94L339 135" fill="#E87981"/>' : ''}
          #{armor >= 9 ? '<path d="M213 110L227 88L270 80L311 96L319 113L292 105L264 112L242 101Z" fill="#3B3158"/><path d="M236 93L267 87L291 96L270 97L262 105L247 95Z" fill="#E87981"/>' : ''}
        </g>
      </svg>
    SVG
  end
end
