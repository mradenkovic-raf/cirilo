module DinoHelper
  DINO_SPECIES = { "rex" => "Тираносаурус", "tricera" => "Трицератопс", "stego" => "Стегосаурус", "robo" => "Робо-дино" }.freeze
  DINO_PART_NAMES = ["Турбо чизмице", "Репни појачивач", "Храбро срце", "Радар антена", "Штитови за рамена", "Енергетска леђа", "Истраживачке наочаре", "Млазни ранац", "Плашт храбрости", "Круна истраживача", "Светлосни штит", "Ракетне чизмице", "Звезда знања", "Музичке слушалице", "Дронови чувари", "Холо-постоље"].freeze

  # Parts are numbered 1–16, in the same order as the learning rewards.
  # The illustration deliberately uses no SVG ids, so several can share a page.
  def dino_svg(unlocked: 0, variant: :hero, species: "rex")
    level = unlocked.to_i.clamp(0, DINO_PART_NAMES.length)
    compact = variant.to_s == "compact"
    species = DINO_SPECIES.key?(species.to_s) ? species.to_s : "rex"
    return dino_species_svg(species, level, compact) unless species == "rex"
    <<~SVG.html_safe
      <svg class="dino-scene dino-scene--#{compact ? 'compact' : 'hero'}" viewBox="0 0 520 440" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Твој диносаурус, #{level} од #{DINO_PART_NAMES.length} делова опреме">
        <title>Твој мали диносаурус</title>
        <circle cx="272" cy="215" r="179" fill="#E7F2E2"/>
        <circle cx="403" cy="116" r="22" fill="#F6F4DC"/>
        <circle cx="118" cy="96" r="8" fill="#CBE6C5"/>
        <circle cx="431" cy="277" r="7" fill="#CBE6C5"/>
        <ellipse cx="266" cy="389" rx="168" ry="17" fill="#173E35" fill-opacity=".09"/>
        #{compact ? '' : dino_orbit_svg}
        #{level >= 16 ? dino_pedestal_svg : ''}
        #{level >= 15 ? dino_guardians_svg : ''}

        <g class="dino-character">
        #{level >= 9 ? dino_cape_svg : ''}
        #{level >= 12 ? dino_bootflames_svg : ''}
        <!-- Tail and far leg sit behind the body. -->
        <path d="M213 291C164 319 124 317 88 284C79 276 71 279 72 290C77 341 128 366 201 347L242 325Z" fill="#84C846"/>
        <path d="M81 287C95 314 136 338 185 327" stroke="#62AD3B" stroke-width="8" stroke-linecap="round"/>
        <path d="M111 310L105 291L127 299L139 319" fill="#173E35" fill-opacity=".13"/>
        #{level >= 2 ? dino_tail_svg : ''}
        <path d="M273 311C265 333 270 352 286 366L287 383H336C344 375 338 365 326 361L319 327Z" fill="#77BD3F"/>
        <path d="M312 378V383M324 376V383" stroke="#416C36" stroke-width="4" stroke-linecap="round"/>
        #{level >= 1 ? '<path d="M281 358L323 355L332 364C349 365 353 378 345 386H283C278 377 277 368 281 358Z" fill="#22574C"/><path d="M285 362H322L328 372H286Z" fill="#62CAB2"/><path d="M286 386H345" stroke="#173E35" stroke-width="7" stroke-linecap="round"/>' : ''}

        <!-- Rounded back plates and optional power pack. -->
        <path d="M215 217L190 210L186 242L207 253Z" fill="#62AD3B"/>
        <path d="M200 254L175 258L181 286L209 286Z" fill="#62AD3B"/>
        <path d="M197 291L180 311L204 326L224 306Z" fill="#62AD3B"/>
        #{level >= 6 ? dino_fins_svg : ''}
        #{level >= 8 ? dino_jetpack_svg : ''}

        <!-- Soft, bean-shaped body. -->
        <path d="M237 204C207 217 194 258 197 300C200 344 228 364 276 354C314 347 335 320 326 283L307 215Z" fill="#A9DF50"/>
        <path d="M209 252C200 296 214 338 253 350C226 352 204 337 199 311C193 288 197 265 209 252Z" fill="#84C846"/>
        <path d="M280 242C254 238 235 260 234 288C232 322 250 341 275 338C305 335 320 312 314 285C310 263 298 246 280 242Z" fill="#EAF0A4"/>
        <path d="M265 270C279 274 291 273 302 269M257 289C275 294 296 293 308 286M258 309C272 313 291 312 302 306" stroke="#CBD883" stroke-width="4" stroke-linecap="round"/>
        #{level >= 3 ? dino_chest_svg : ''}
        #{level >= 13 ? dino_badge_svg : ''}

        <!-- A little hand, held out to invite the learner. -->
        <path d="M306 268C322 277 337 273 347 261C353 252 364 258 360 270C352 293 326 301 309 289" fill="#91D249"/>
        <path d="M345 274L350 281M336 280L341 287" stroke="#5F9D38" stroke-width="3" stroke-linecap="round"/>
        #{level >= 5 ? dino_shoulder_svg : ''}
        #{level >= 11 ? dino_shield_svg : ''}

        <!-- The front leg and its three tiny toes. -->
        <path d="M225 321C216 333 217 354 223 365L212 373C204 379 207 389 218 390H269C279 385 274 374 262 371L266 337Z" fill="#A9DF50"/>
        <path d="M229 382V389M244 382V389" stroke="#6CAD3D" stroke-width="4" stroke-linecap="round"/>
        #{level >= 1 ? '<path d="M220 362H264L269 372C284 375 287 386 277 393H214C204 389 204 379 212 373Z" fill="#22574C"/><path d="M223 366H260L264 378H216Z" fill="#62CAB2"/><path d="M214 393H277" stroke="#173E35" stroke-width="7" stroke-linecap="round"/><path d="M230 369H247" stroke="#D8F4C4" stroke-width="4" stroke-linecap="round"/>' : ''}

        <!-- Head: big, friendly eyes and an unmistakable dinosaur snout. -->
        <path d="M221 131C226 87 259 65 300 74C333 80 352 106 352 134C389 132 414 149 414 177C414 210 386 231 347 230L289 230C246 231 215 208 215 172C215 156 218 143 221 131Z" fill="#A9DF50"/>
        <path d="M225 150C220 185 233 207 267 219L340 227C293 239 252 233 229 210C215 196 211 173 225 150Z" fill="#84C846"/>
        <path d="M238 116C248 93 270 84 290 86" stroke="#C9EE86" stroke-width="10" stroke-linecap="round"/>
        <path d="M338 149C361 142 387 147 399 159" stroke="#C9EE86" stroke-width="6" stroke-linecap="round"/>
        <ellipse cx="325" cy="131" rx="18" ry="25" fill="#F9FCED"/>
        <ellipse cx="326" cy="135" rx="9" ry="14" fill="#173E35"/>
        <circle cx="329" cy="130" r="3.7" fill="#FFF"/>
        <ellipse cx="280" cy="138" rx="26" ry="34" fill="#F9FCED"/>
        <ellipse cx="286" cy="143" rx="12" ry="19" fill="#173E35"/>
        <circle cx="291" cy="136" r="5" fill="#FFF"/>
        <circle cx="282" cy="151" r="2.5" fill="#FFF" fill-opacity=".5"/>
        <path d="M261 102C270 97 281 97 289 101M317 102C324 99 331 101 334 105" stroke="#427B35" stroke-width="5" stroke-linecap="round"/>
        <ellipse cx="371" cy="169" rx="4" ry="5" fill="#5E9836"/>
        <ellipse cx="394" cy="169" rx="3" ry="4" fill="#5E9836"/>
        <ellipse cx="258" cy="183" rx="14" ry="8" fill="#FF9973" fill-opacity=".7"/>
        <path d="M292 191C309 208 351 212 377 195" stroke="#173E35" stroke-width="5" stroke-linecap="round"/>
        <path d="M319 204L324 214C326 217 330 217 332 213L336 207" fill="#FFFDF0"/>
        <circle cx="238" cy="156" r="4" fill="#77BD3F"/>
        <circle cx="241" cy="169" r="3" fill="#77BD3F"/>
        #{level >= 7 ? dino_goggles_svg : ''}
        #{level >= 14 ? dino_headphones_svg : ''}
        #{level >= 4 ? dino_antenna_svg : ''}
        #{level >= 10 ? dino_crown_svg : ''}
        </g>
        #{level >= 8 ? '<path d="M429 193L434 206L447 211L434 216L429 229L424 216L411 211L424 206Z" fill="#FFD36C"/><path d="M134 172L138 181L147 185L138 189L134 198L130 189L121 185L130 181Z" fill="#FF765E"/>' : ''}
      </svg>
    SVG
  end

  def part_icon(index)
    part = index.to_i.clamp(1, DINO_PART_NAMES.length)
    artwork = [
      '<path d="M23 21H50L53 44L62 47C68 49 70 57 65 61H18C12 58 13 51 19 46Z" fill="#22574C"/><path d="M26 26H46L48 45H23Z" fill="#62CAB2"/><path d="M17 62H65" stroke="#173E35" stroke-width="6" stroke-linecap="round"/><path d="M31 32H42" stroke="#D8F4C4" stroke-width="4" stroke-linecap="round"/><path d="M45 48L38 55H49L42 61" stroke="#FFD36C" stroke-width="3" stroke-linejoin="round"/>',
      '<path d="M21 32C34 47 48 41 62 26L66 42C52 60 31 65 15 49Z" fill="#22574C"/><path d="M24 37C37 49 51 42 62 32" stroke="#62CAB2" stroke-width="7" stroke-linecap="round"/><path d="M17 32L24 25L33 38L27 45Z" fill="#FF765E"/><path d="M55 39L63 46" stroke="#FFD36C" stroke-width="4" stroke-linecap="round"/>',
      '<path d="M16 24L40 15L64 24L60 51L40 67L20 51Z" fill="#22574C"/><path d="M22 29L40 22L58 29L54 47L40 59L26 47Z" fill="#62CAB2"/><circle cx="40" cy="40" r="13" fill="#173E35"/><path d="M42 27L31 42H40L37 52L50 36H41Z" fill="#FFD36C"/><circle cx="25" cy="32" r="2" fill="#E6F6D6"/><circle cx="55" cy="32" r="2" fill="#E6F6D6"/>',
      '<path d="M39 56V28" stroke="#22574C" stroke-width="6" stroke-linecap="round"/><circle cx="39" cy="23" r="9" fill="#FF765E"/><circle cx="37" cy="20" r="3" fill="#FFC2AA"/><path d="M23 64L26 53H52L56 64Z" fill="#22574C"/><path d="M27 58H52" stroke="#62CAB2" stroke-width="4" stroke-linecap="round"/><path d="M23 19C19 23 19 28 23 32M56 16C62 22 62 30 56 36" stroke="#62CAB2" stroke-width="3" stroke-linecap="round"/>',
      '<path d="M13 32C20 17 38 15 46 29L37 50L15 51Z" fill="#22574C"/><path d="M18 32C24 23 34 23 39 30L33 42H18Z" fill="#62CAB2"/><path d="M43 33C51 23 62 26 68 37L65 57H46L40 43Z" fill="#22574C"/><path d="M47 36C54 31 59 33 62 38L61 48H49Z" fill="#FF765E"/><circle cx="26" cy="33" r="4" fill="#FFD36C"/>',
      '<path d="M20 62L15 25L32 32L39 12L49 30L65 20L61 61Z" fill="#22574C"/><path d="M24 53L21 35L35 42L40 24L46 42L59 31L55 54Z" fill="#62CAB2"/><path d="M21 63H61" stroke="#173E35" stroke-width="7" stroke-linecap="round"/><path d="M31 51L37 43L42 49L48 40" stroke="#FFD36C" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
      '<path d="M12 31L18 27H62L68 31V49L63 53H46L40 46L34 53H17L12 48Z" fill="#173E35"/><path d="M18 33H34V45L29 48H18ZM46 33H62V48H51L46 43Z" fill="#62CAB2"/><path d="M22 35L28 35L21 43M51 35L57 35L50 43" stroke="#D8F4E9" stroke-width="3" stroke-linecap="round"/><path d="M7 36H12M68 36H73" stroke="#FF765E" stroke-width="5" stroke-linecap="round"/>',
      '<path d="M22 55L21 68L29 62L33 72L38 55M44 55L45 68L53 62L57 71L60 55" fill="#FFD36C"/><path d="M29 55L30 64L34 58M51 55L53 63L56 57" fill="#FF765E"/><rect x="16" y="23" width="23" height="35" rx="10" fill="#22574C"/><rect x="43" y="23" width="23" height="35" rx="10" fill="#22574C"/><path d="M23 29V44M50 29V44" stroke="#62CAB2" stroke-width="7" stroke-linecap="round"/><path d="M34 30H49V51H34Z" fill="#FF765E"/><path d="M23 21L28 13L33 21M49 21L54 13L59 21" fill="#173E35"/>',
      '<path d="M25 20L54 20C50 40 59 52 67 62L48 59L35 67L22 59L10 62C19 48 24 36 25 20Z" fill="#B977D5"/><path d="M27 26C26 42 23 49 20 53L34 56L44 50L52 52C46 40 45 32 46 26Z" fill="#D9AEED"/><path d="M26 21Q39 13 53 21" stroke="#6F4E8C" stroke-width="6" stroke-linecap="round"/><circle cx="40" cy="20" r="5" fill="#FFD36C"/>',
      '<path d="M15 29L29 39L39 19L51 38L66 26L60 59H21Z" fill="#FFD36C" stroke="#AD7C34" stroke-width="3" stroke-linejoin="round"/><path d="M22 51H61V60H22Z" fill="#F5AC4D"/><path d="M40 36L46 43L40 49L34 43Z" fill="#FF765E"/><circle cx="15" cy="27" r="4" fill="#FFE9A9"/><circle cx="39" cy="18" r="4" fill="#FFE9A9"/><circle cx="67" cy="25" r="4" fill="#FFE9A9"/>',
      '<path d="M40 12L64 23V44C62 57 52 64 40 70C28 64 18 57 16 44V23Z" fill="#2D7170"/><path d="M40 20L57 29V43C55 52 48 57 40 62C32 57 25 52 23 43V29Z" fill="#92DDD3"/><path d="M40 28L31 43H39L35 54L50 37H41Z" fill="#F5FECE"/><path d="M27 32V42" stroke="#D8FFEF" stroke-width="3" stroke-linecap="round"/>',
      '<path d="M22 46L18 67L28 62L35 73L43 47M47 46L49 70L57 60L65 66L63 46" fill="#FF765E"/><path d="M25 48L26 62L32 55L35 64L38 48M51 48L53 60L59 54L59 48" fill="#FFD36C"/><path d="M21 17H41V43H48V51H16V42Z" fill="#22574C"/><path d="M46 19H62V41H68V49H45Z" fill="#22574C"/><path d="M26 23H35V38H23ZM51 24H57V38H49Z" fill="#62CAB2"/>',
      '<path d="M25 45L18 69L33 62L41 69L44 46M42 45L47 70L55 63L68 66L55 44" fill="#FF765E"/><circle cx="40" cy="34" r="25" fill="#AD7C34"/><circle cx="40" cy="32" r="22" fill="#FFD36C"/><circle cx="40" cy="32" r="17" stroke="#FFF0BC" stroke-width="2"/><path d="M40 19L44 27L53 29L47 36L48 45L40 41L32 45L33 36L27 29L36 27Z" fill="#B17B32"/>',
      '<path d="M18 43V31C18 3 62 3 62 31V43" stroke="#22574C" stroke-width="9"/><path d="M20 30C23 10 57 10 60 30" stroke="#B89AE4" stroke-width="4"/><rect x="12" y="31" width="17" height="29" rx="7" fill="#B89AE4"/><rect x="53" y="31" width="17" height="29" rx="7" fill="#B89AE4"/><path d="M20 39V50M61 39V50" stroke="#E8D9FF" stroke-width="4" stroke-linecap="round"/><path d="M61 58C58 64 50 66 44 65" stroke="#22574C" stroke-width="3"/><rect x="36" y="62" width="12" height="6" rx="3" fill="#FF765E"/>',
      '<ellipse cx="40" cy="42" rx="31" ry="18" stroke="#62CAB2" stroke-width="2" stroke-dasharray="4 4"/><path d="M11 28L23 21L35 28L23 36Z" fill="#22574C"/><path d="M14 28L23 23L32 28L23 32Z" fill="#62CAB2"/><circle cx="23" cy="29" r="3" fill="#FFD36C"/><path d="M47 52L59 44L71 52L59 61Z" fill="#22574C"/><path d="M50 52L59 47L68 52L59 57Z" fill="#B89AE4"/><circle cx="59" cy="52" r="3" fill="#FFD36C"/>',
      '<path d="M11 45H69V55C69 72 11 72 11 55Z" fill="#22574C"/><ellipse cx="40" cy="45" rx="29" ry="13" fill="#62CAB2"/><ellipse cx="40" cy="44" rx="20" ry="8" fill="#173E35"/><path d="M25 38L30 14H50L55 38" fill="#62CAB2" fill-opacity=".24"/><path d="M31 59H49" stroke="#FFD36C" stroke-width="3" stroke-linecap="round"/><path d="M39 21L32 31H38L35 40L48 27H40Z" fill="#A9DF50"/><path d="M17 46L24 50M58 48L64 45" stroke="#E5FFDD" stroke-width="3" stroke-linecap="round"/>'
    ][part - 1]
    %(<svg class="part-icon" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="#{DINO_PART_NAMES[part - 1]}">#{artwork}</svg>).html_safe
  end

  private

  # Each new dinosaur has its own body and face. Equipment uses the same earned
  # order, with attachment points adjusted to the four-legged stegosaurus.
  def dino_species_svg(species, level, compact)
    stego = species == "stego"
    head_rig = stego ? "translate(188 89) scale(.64)" : nil
    body_rig = stego ? "translate(-15 0)" : nil
    back_rig = stego ? "translate(-31 0)" : nil
    hand_rig = stego ? "translate(47 37) scale(.88)" : nil
    content = []
    content << dino_rig_svg(dino_cape_svg, back_rig) if level >= 9
    content << (stego ? '<path d="M160 384L149 419L165 410L178 431L184 389M335 386L326 421L341 409L354 430L363 386" fill="#FF765E"/><path d="M162 389L159 408L169 401L176 416L179 389M338 390L336 410L346 402L353 416L357 390" fill="#FFD36C"/>' : dino_bootflames_svg) if level >= 12
    content << send("dino_#{species}_back_svg")
    content << dino_tail_svg if level >= 2
    content << dino_rig_svg(dino_fins_svg, back_rig) if level >= 6
    content << dino_rig_svg(dino_jetpack_svg, back_rig) if level >= 8
    content << send("dino_#{species}_body_svg")
    content << dino_rig_svg(dino_chest_svg, body_rig) if level >= 3
    content << dino_rig_svg(dino_badge_svg, body_rig) if level >= 13
    content << dino_rig_svg(dino_shoulder_svg, body_rig) if level >= 5
    content << dino_rig_svg(dino_shield_svg, hand_rig) if level >= 11
    content << dino_species_boots_svg(species) if level >= 1
    content << send("dino_#{species}_head_svg")
    content << dino_rig_svg(dino_goggles_svg, head_rig) if level >= 7
    content << dino_rig_svg(dino_headphones_svg, head_rig) if level >= 14
    content << dino_rig_svg(dino_antenna_svg, head_rig) if level >= 4
    content << dino_rig_svg(dino_crown_svg, species == "tricera" ? "translate(-76 -8)" : head_rig) if level >= 10
    <<~SVG.html_safe
      <svg class="dino-scene dino-scene--#{compact ? 'compact' : 'hero'} dino-species--#{species}" data-dino-species="#{species}" viewBox="0 0 520 440" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Твој диносаурус, #{DINO_SPECIES.fetch(species)}, #{level} од #{DINO_PART_NAMES.length} делова опреме">
        <title>Твој #{DINO_SPECIES.fetch(species).downcase}</title>
        <circle cx="272" cy="215" r="179" fill="#E7F2E2"/><circle cx="403" cy="116" r="22" fill="#F6F4DC"/><circle cx="118" cy="96" r="8" fill="#CBE6C5"/><circle cx="431" cy="277" r="7" fill="#CBE6C5"/><ellipse cx="266" cy="389" rx="168" ry="17" fill="#173E35" fill-opacity=".09"/>
        #{compact ? '' : dino_orbit_svg}
        #{level >= 16 ? dino_pedestal_svg : ''}
        #{level >= 15 ? dino_guardians_svg : ''}
        <g class="dino-character" data-species-shape="#{species}">#{content.join}</g>
      </svg>
    SVG
  end

  def dino_rig_svg(svg, transform)
    transform ? %(<g transform="#{transform}">#{svg}</g>) : svg
  end

  def dino_species_boots_svg(species)
    front = '<path d="M220 362H264L269 372C284 375 287 386 277 393H214C204 389 204 379 212 373Z" fill="#22574C"/><path d="M223 366H260L264 378H216Z" fill="#62CAB2"/><path d="M214 393H277" stroke="#173E35" stroke-width="7" stroke-linecap="round"/><path d="M230 369H247" stroke="#D8F4C4" stroke-width="4" stroke-linecap="round"/>'
    back = '<path d="M281 358L323 355L332 364C349 365 353 378 345 386H283C278 377 277 368 281 358Z" fill="#22574C"/><path d="M285 362H322L328 372H286Z" fill="#62CAB2"/><path d="M286 386H345" stroke="#173E35" stroke-width="7" stroke-linecap="round"/>'
    species == "stego" ? dino_rig_svg(front, "translate(-72 0)") + dino_rig_svg(back, "translate(39 8)") : back + front
  end

  def dino_tricera_back_svg
    <<~SVG
      <path d="M212 292C165 318 120 318 88 284C79 276 71 279 74 292C82 340 128 361 201 345L244 320Z" fill="#84C846"/><path d="M85 293C111 324 151 336 184 327" stroke="#62AD3B" stroke-width="7" stroke-linecap="round"/>
      <path d="M211 220L194 215L187 242L211 254M198 258L177 261L183 286L209 286" fill="#62AD3B"/>
      <path d="M218 65L237 76L255 61L273 79L296 69L303 95L326 99L320 124L337 144L321 164L330 188L303 198L301 225L276 224L257 245L236 230L208 239L197 217L171 215L170 188L148 171L159 147L149 124L173 110L174 84L200 88Z" fill="#62AD3B"/>
      <path d="M213 89C242 75 282 89 297 121C318 167 302 209 267 221C220 237 180 215 170 174C161 137 180 103 213 89Z" fill="#A9DF50"/>
      <path d="M214 108C235 96 267 102 282 128C300 160 291 192 266 203C232 217 200 201 190 174C181 145 190 123 214 108Z" fill="#EAF0A4"/>
      <path d="M196 111L210 101M177 143L183 128M179 181L176 165M202 211L188 201" stroke="#C9EE86" stroke-width="7" stroke-linecap="round"/>
    SVG
  end

  def dino_tricera_body_svg
    <<~SVG
      <path d="M274 315L284 367L285 383H336C344 376 339 366 326 362L319 322Z" fill="#77BD3F"/>
      <path d="M219 217C190 235 180 276 187 309C194 343 227 362 277 354C318 350 339 323 334 286C330 252 310 225 284 213Z" fill="#A9DF50"/><path d="M200 247C187 283 197 327 235 348C202 343 186 325 184 303C180 283 187 261 200 247Z" fill="#84C846"/>
      <path d="M276 249C247 243 227 266 230 295C231 324 250 342 278 336C305 332 318 311 313 288C308 266 294 250 276 249Z" fill="#EAF0A4"/><path d="M245 280C263 286 288 286 305 280M244 300C264 307 287 306 307 297M255 319C269 324 287 321 297 315" stroke="#CBD883" stroke-width="4" stroke-linecap="round"/>
      <path d="M313 270C327 278 338 273 347 261C353 252 364 258 360 270C352 293 326 301 309 289" fill="#91D249"/><path d="M345 274L350 281M336 280L341 287" stroke="#5F9D38" stroke-width="3" stroke-linecap="round"/>
      <path d="M220 321C210 337 218 356 223 365L212 373C204 379 207 389 218 390H269C279 385 274 374 262 371L266 337Z" fill="#A9DF50"/><path d="M229 382V389M244 382V389M309 377V383M322 376V383" stroke="#6CAD3D" stroke-width="4" stroke-linecap="round"/>
    SVG
  end

  def dino_tricera_head_svg
    <<~SVG
      <path d="M234 126C243 98 268 85 300 91C330 95 343 118 345 141C373 143 405 155 417 177C431 202 409 227 381 237C346 249 305 240 282 229C245 226 224 204 224 176C224 156 228 139 234 126Z" fill="#A9DF50"/>
      <path d="M231 155C227 189 247 212 281 218L348 237C305 237 282 231 260 223C232 214 221 186 231 155Z" fill="#84C846"/>
      <path d="M254 111C266 102 283 98 298 104" stroke="#C9EE86" stroke-width="8" stroke-linecap="round"/>
      <path d="M328 106C332 86 338 62 350 52C344 76 348 96 342 117Z" fill="#F6E8BC" stroke="#C5BC89" stroke-width="2"/>
      <path d="M266 113C259 91 248 72 239 63C241 89 244 111 253 122Z" fill="#FFF4CF" stroke="#D4C695" stroke-width="2"/>
      <ellipse cx="326" cy="134" rx="18" ry="25" fill="#F9FCED"/><ellipse cx="328" cy="138" rx="9" ry="14" fill="#173E35"/><circle cx="331" cy="133" r="3.5" fill="#FFF"/>
      <ellipse cx="281" cy="141" rx="25" ry="33" fill="#F9FCED"/><ellipse cx="287" cy="146" rx="12" ry="18" fill="#173E35"/><circle cx="291" cy="139" r="5" fill="#FFF"/>
      <path d="M267 106C274 102 285 103 292 108M320 103L335 108" stroke="#427B35" stroke-width="4" stroke-linecap="round"/>
      <path d="M386 164C388 142 394 131 403 127C402 143 404 153 400 173Z" fill="#FFF4CF" stroke="#D4C695" stroke-width="2"/>
      <path d="M408 187C427 189 436 197 429 208L411 222L400 213L408 204L400 197Z" fill="#E6D39B"/><path d="M307 208C335 226 373 229 401 211" stroke="#173E35" stroke-width="5" stroke-linecap="round"/>
      <ellipse cx="367" cy="181" rx="4" ry="5" fill="#5E9836"/><ellipse cx="393" cy="187" rx="3" ry="4" fill="#5E9836"/><ellipse cx="262" cy="184" rx="13" ry="8" fill="#FF9973" fill-opacity=".6"/>
    SVG
  end

  def dino_stego_back_svg
    <<~SVG
      <path d="M197 295C150 306 119 300 88 274C73 262 67 270 75 286C100 331 141 356 202 337Z" fill="#84C846"/><path d="M88 287C112 316 147 328 177 319" stroke="#62AD3B" stroke-width="7" stroke-linecap="round"/>
      <path d="M89 288L65 271L72 297M105 309L78 299L92 322" fill="#F5E6C5" stroke="#B9BE8D" stroke-width="2"/>
      <path d="M126 261L115 226L137 201L158 230L153 260Z" fill="#62AD3B"/><path d="M154 231L143 185L176 150L204 191L195 228Z" fill="#62AD3B"/><path d="M199 219L191 159L228 111L260 163L248 221Z" fill="#62AD3B"/><path d="M247 222L258 168L292 140L315 186L293 242Z" fill="#62AD3B"/><path d="M296 243L322 208L349 205L350 244L328 263Z" fill="#62AD3B"/>
      <path d="M134 250L126 228L138 215L148 234L144 253M170 217L155 185L176 164L192 193L185 219M214 213L204 161L228 129L247 165L237 215M260 220L269 174L291 155L302 188L285 230M311 246L327 219L339 218L339 240L326 253" fill="#FFB889"/>
      <path d="M225 148L226 204M175 180L177 210M289 178L275 216" stroke="#FFD6A3" stroke-width="4" stroke-linecap="round"/>
    SVG
  end

  def dino_stego_body_svg
    <<~SVG
      <path d="M199 315L197 358L207 374C213 381 209 389 199 389H164C157 384 158 376 167 372L164 322M326 305L338 353L354 370C360 379 353 386 344 386H310L307 327Z" fill="#77BD3F"/>
      <path d="M177 221C205 204 259 204 295 218C327 232 349 244 365 232L393 240C388 269 365 301 340 317C313 342 286 350 234 347C193 348 159 333 150 305C140 279 145 242 177 221Z" fill="#A9DF50"/>
      <path d="M153 262C148 303 166 328 205 340C169 338 151 324 146 304C140 287 143 273 153 262Z" fill="#84C846"/>
      <path d="M204 263C232 249 280 251 307 275C325 292 312 321 283 332C251 344 213 334 197 312C184 296 188 274 204 263Z" fill="#EAF0A4"/><path d="M211 280C237 275 275 281 295 292M210 299C235 297 266 304 284 315" stroke="#CBD883" stroke-width="4" stroke-linecap="round"/>
      <path d="M178 316L194 332L191 366L199 375C207 381 202 393 191 394H150C140 389 144 379 157 375L155 335Z" fill="#A9DF50"/>
      <path d="M346 302L366 323L358 369L369 380C377 388 370 396 359 396H321C313 390 318 380 330 378L323 326Z" fill="#A9DF50"/><path d="M160 387V393M175 387V393M338 389V395M353 389V395" stroke="#6CAD3D" stroke-width="4" stroke-linecap="round"/>
      <path d="M311 278C324 288 339 286 350 276C357 270 364 276 360 286C350 304 327 309 310 298Z" fill="#91D249"/>
    SVG
  end

  def dino_stego_head_svg
    <<~SVG
      <path d="M334 153C342 131 365 126 385 137C398 144 406 158 408 174C428 177 449 191 449 209C449 228 427 241 399 242C372 243 351 232 340 218C329 204 326 171 334 153Z" fill="#A9DF50"/>
      <path d="M337 172C334 202 351 224 381 234C354 230 340 223 333 206C328 194 329 181 337 172Z" fill="#84C846"/>
      <path d="M348 145C359 137 371 138 378 142" stroke="#C9EE86" stroke-width="6" stroke-linecap="round"/>
      <ellipse cx="397" cy="174" rx="12" ry="17" fill="#F9FCED"/><ellipse cx="399" cy="177" rx="6" ry="10" fill="#173E35"/><circle cx="401" cy="174" r="2.5" fill="#FFF"/>
      <ellipse cx="368" cy="180" rx="17" ry="22" fill="#F9FCED"/><ellipse cx="373" cy="183" rx="8" ry="12" fill="#173E35"/><circle cx="376" cy="178" r="3.5" fill="#FFF"/>
      <path d="M357 154C363 149 373 150 379 154M390 154L400 158" stroke="#427B35" stroke-width="3" stroke-linecap="round"/>
      <ellipse cx="424" cy="199" rx="3" ry="4" fill="#5E9836"/><path d="M380 216C396 227 423 224 434 214" stroke="#173E35" stroke-width="4" stroke-linecap="round"/><path d="M401 224L405 230L409 224" fill="#FFFDF0"/><ellipse cx="353" cy="207" rx="8" ry="5" fill="#FF9973" fill-opacity=".7"/>
    SVG
  end

  def dino_robo_back_svg
    <<~SVG
      <path d="M211 290L162 318L121 307L86 276L75 286L106 329L162 350L220 329Z" fill="#77BD3F" stroke="#416C36" stroke-width="3" stroke-linejoin="round"/><path d="M88 289L115 318L159 333L191 316" stroke="#C9EE86" stroke-width="6" stroke-linecap="round"/><path d="M119 309L110 325M143 315L139 339M171 313L179 335" stroke="#416C36" stroke-width="4"/>
      <path d="M208 214L187 214L178 240L195 251L178 269L191 291L208 289Z" fill="#173E35"/><path d="M190 231H202M190 270H204" stroke="#62CAB2" stroke-width="5" stroke-linecap="round"/>
    SVG
  end

  def dino_robo_body_svg
    <<~SVG
      <path d="M281 314L277 342L289 370L284 384H340L337 371L320 350L320 324Z" fill="#77BD3F" stroke="#416C36" stroke-width="3"/><circle cx="300" cy="341" r="13" fill="#173E35"/><circle cx="300" cy="341" r="7" fill="#62CAB2"/>
      <path d="M228 220L304 220L334 250L329 309L306 343L230 343L203 318L197 260Z" fill="#A9DF50" stroke="#416C36" stroke-width="4" stroke-linejoin="round"/><path d="M209 262L229 231H247L222 267L225 324L210 312Z" fill="#C9EE86"/><path d="M311 233L328 253L323 307L303 333H285L308 300Z" fill="#84C846"/>
      <path d="M250 249H291L307 267L304 304L283 324H249L232 301V267Z" fill="#173E35"/><path d="M251 257H287L298 270L295 300L279 315H254L241 297V270Z" fill="#EAF0A4"/><circle cx="269" cy="282" r="17" fill="#84C846"/><path d="M271 267L258 285H269L266 299L281 278H270Z" fill="#C9EE86"/>
      <circle cx="225" cy="250" r="4" fill="#416C36"/><circle cx="312" cy="254" r="4" fill="#416C36"/><circle cx="224" cy="312" r="4" fill="#416C36"/>
      <path d="M312 269L331 280L349 263L361 270L348 293L328 299L305 286Z" fill="#91D249" stroke="#416C36" stroke-width="3" stroke-linejoin="round"/><circle cx="328" cy="283" r="10" fill="#173E35"/><circle cx="328" cy="283" r="5" fill="#62CAB2"/><path d="M349 265L355 255L365 261L363 276L354 281Z" fill="#A9DF50" stroke="#416C36" stroke-width="3"/>
      <path d="M227 322L262 327L265 350L254 372L273 380L272 393H211L209 380L224 370L216 347Z" fill="#A9DF50" stroke="#416C36" stroke-width="3"/><circle cx="241" cy="347" r="14" fill="#173E35"/><circle cx="241" cy="347" r="8" fill="#62CAB2"/><path d="M223 382H260" stroke="#C9EE86" stroke-width="4" stroke-linecap="round"/>
    SVG
  end

  def dino_robo_head_svg
    <<~SVG
      <path d="M223 112L245 83L304 75L337 96L351 137L392 140L416 158L420 195L400 222L345 235L274 227L225 204L214 169Z" fill="#A9DF50" stroke="#416C36" stroke-width="4" stroke-linejoin="round"/>
      <path d="M228 116L249 92L304 85L320 96L258 102L237 125L229 175L218 168Z" fill="#C9EE86"/><path d="M220 171L233 192L276 212L347 221L404 208L400 222L345 235L274 227L225 204Z" fill="#84C846"/>
      <path d="M245 113L290 104L315 112L335 106L348 124L345 161L324 174L302 165L278 180L247 169L238 143Z" fill="#173E35"/><path d="M255 119L281 114L299 122V153L282 166L253 157L248 139Z" fill="#62CAB2"/><path d="M319 120L331 115L341 126L338 151L324 162L313 153V131Z" fill="#62CAB2"/>
      <rect x="273" y="127" width="11" height="24" rx="5" fill="#F9FCED"/><rect x="326" y="126" width="8" height="20" rx="4" fill="#F9FCED"/><path d="M257 124L250 138M265 121L251 150" stroke="#C9EE86" stroke-width="3" stroke-linecap="round"/>
      <path d="M370 158H398V178H370Z" fill="#84C846"/><path d="M377 164V172M387 164V172" stroke="#416C36" stroke-width="3" stroke-linecap="round"/>
      <path d="M292 191L312 205L366 209L394 194" stroke="#173E35" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/><path d="M323 206V212M334 207V213M345 208V214" stroke="#EAF0A4" stroke-width="3" stroke-linecap="round"/>
      <circle cx="233" cy="159" r="13" fill="#173E35"/><circle cx="233" cy="159" r="8" fill="#62CAB2"/><path d="M228 159H238" stroke="#EAF0A4" stroke-width="3" stroke-linecap="round"/><circle cx="309" cy="93" r="3" fill="#416C36"/><circle cx="400" cy="187" r="3" fill="#416C36"/>
    SVG
  end

  def dino_orbit_svg
    <<~SVG
      <g transform="translate(107 196) rotate(-14)">
        <rect x="-26" y="-27" width="53" height="53" rx="17" fill="#F9FCED"/>
        <rect x="-26" y="-27" width="53" height="53" rx="17" stroke="#CDE5C4" stroke-width="2"/>
        <path d="M2-17L-10 3H0L-3 16L12-5H2Z" fill="#FF765E"/>
      </g>
      <g transform="translate(425 84) rotate(13)">
        <rect x="-23" y="-23" width="46" height="46" rx="15" fill="#FFD36C"/>
        <path d="M0-12L4-4L13-3L6 4L8 13L0 9L-8 13L-6 4L-13-3L-4-4Z" fill="#B58135"/>
      </g>
      <path d="M165 115V127M159 121H171" stroke="#62CAB2" stroke-width="4" stroke-linecap="round"/>
      <path d="M438 325V335M433 330H443" stroke="#FF9973" stroke-width="4" stroke-linecap="round"/>
      <circle cx="398" cy="344" r="4" fill="#FFD36C"/>
      <circle cx="169" cy="370" r="4" fill="#62CAB2"/>
    SVG
  end

  def dino_tail_svg
    '<path d="M88 300L101 292C114 310 131 319 150 323L143 349C115 345 95 331 88 300Z" fill="#22574C"/><path d="M101 306C109 318 123 325 136 328L133 338C116 333 105 325 101 306Z" fill="#62CAB2"/><path d="M111 307L119 297L127 310L120 319Z" fill="#FF765E"/><path d="M138 329L134 339" stroke="#FFD36C" stroke-width="4" stroke-linecap="round"/>'
  end

  def dino_chest_svg
    '<path d="M245 257L276 247L309 257L311 296L281 323L247 302Z" fill="#22574C"/><path d="M251 263L277 254L302 263L304 293L280 315L254 297Z" fill="#62CAB2"/><circle cx="279" cy="283" r="18" fill="#173E35"/><circle cx="279" cy="283" r="14" fill="#286557"/><path d="M282 269L269 286H279L275 298L290 279H280Z" fill="#FFD36C"/><circle cx="258" cy="267" r="3" fill="#D9EFB8"/><circle cx="298" cy="266" r="3" fill="#D9EFB8"/>'
  end

  def dino_antenna_svg
    '<path d="M277 77L269 43" stroke="#173E35" stroke-width="7" stroke-linecap="round"/><path d="M264 79L261 70C270 65 281 66 289 72L288 81Z" fill="#22574C"/><path d="M267 72L282 73" stroke="#62CAB2" stroke-width="4" stroke-linecap="round"/><circle cx="267" cy="36" r="12" fill="#FF765E"/><circle cx="264" cy="32" r="4" fill="#FFD0B5"/><path d="M246 26C242 32 243 41 249 47M285 21C292 26 296 37 291 44" stroke="#62CAB2" stroke-width="3" stroke-linecap="round"/>'
  end

  def dino_shoulder_svg
    '<path d="M304 258C310 251 323 253 331 263L326 280L309 284L301 270Z" fill="#22574C"/><path d="M309 260C315 257 322 260 326 265L322 273L311 276L306 268Z" fill="#FF765E"/><circle cx="316" cy="265" r="3" fill="#FFD36C"/><path d="M224 247C220 240 206 241 200 250L199 270L218 274L228 263Z" fill="#22574C"/><path d="M217 247C212 245 206 249 205 254V263L215 267L221 261Z" fill="#62CAB2"/>'
  end

  def dino_fins_svg
    '<path d="M218 220L191 187L185 224L163 230L186 256L171 282L200 292L225 266Z" fill="#22574C"/><path d="M210 222L195 204L193 230L178 234L196 250L184 277L200 279L216 259Z" fill="#62CAB2"/><path d="M197 231L207 241L197 254L205 265" stroke="#FFD36C" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'
  end

  def dino_goggles_svg
    '<path d="M220 133L246 128M344 127L355 132" stroke="#22574C" stroke-width="11" stroke-linecap="round"/><path d="M247 116C259 106 286 106 303 116L305 149C290 165 263 163 251 150Z" fill="#62CAB2" fill-opacity=".15" stroke="#173E35" stroke-width="7" stroke-linejoin="round"/><path d="M311 114C321 109 335 111 343 119V145C335 156 320 154 309 147Z" fill="#62CAB2" fill-opacity=".15" stroke="#173E35" stroke-width="6" stroke-linejoin="round"/><path d="M303 129H310" stroke="#173E35" stroke-width="7"/><path d="M261 119L254 131M271 117L256 142M320 119L316 127" stroke="#FFFFFF" stroke-opacity=".75" stroke-width="3" stroke-linecap="round"/><rect x="234" y="125" width="12" height="12" rx="4" fill="#FF765E"/>'
  end

  def dino_jetpack_svg
    '<path d="M160 309L155 349L168 337L174 355L183 312" fill="#FFD36C"/><path d="M164 311L164 336L174 324L178 337L179 308" fill="#FF765E"/><path d="M164 241L171 230L180 241" fill="#173E35"/><rect x="150" y="242" width="42" height="77" rx="18" fill="#22574C"/><path d="M160 258V291" stroke="#62CAB2" stroke-width="10" stroke-linecap="round"/><path d="M155 309H186" stroke="#173E35" stroke-width="10" stroke-linecap="round"/><path d="M177 248H201L208 266L202 297H182Z" fill="#FF765E"/><path d="M188 261V283" stroke="#FFC29F" stroke-width="5" stroke-linecap="round"/>'
  end

  def dino_cape_svg
    '<g class="dino-cape"><path d="M228 214L263 226C245 282 236 330 237 364L213 364L187 383L162 369L116 375C163 327 192 258 228 214Z" fill="#9665B7"/><path d="M231 225L249 231C230 279 216 320 209 352L187 369L168 357L142 364C179 316 207 256 231 225Z" fill="#C59CE2"/><path d="M226 230C206 282 191 331 170 352" stroke="#E4C6F6" stroke-width="5" stroke-linecap="round"/><path d="M226 218L251 231" stroke="#6F4E8C" stroke-width="8" stroke-linecap="round"/></g>'
  end

  def dino_crown_svg
    '<g class="dino-crown" transform="rotate(15 317 72)"><path d="M287 59L304 67L315 42L330 65L348 49L343 83H293Z" fill="#FFD36C" stroke="#B18039" stroke-width="3" stroke-linejoin="round"/><path d="M294 76H342V85H294Z" fill="#F5AC4D"/><path d="M316 62L322 69L317 75L311 69Z" fill="#FF765E"/><circle cx="286" cy="57" r="4" fill="#FFEAB0"/><circle cx="314" cy="40" r="4" fill="#FFEAB0"/><circle cx="349" cy="47" r="4" fill="#FFEAB0"/></g>'
  end

  def dino_shield_svg
    '<g class="dino-shield"><path d="M363 254L388 265V287C385 303 375 313 363 319C350 313 341 303 338 287V265Z" fill="#2D7170"/><path d="M363 262L381 270V286C378 297 371 305 363 310C354 305 347 297 345 286V270Z" fill="#92DDD3" fill-opacity=".94"/><path d="M365 270L352 287H362L358 301L375 279H364Z" fill="#F5FECE"/><path d="M350 273V284" stroke="#D8FFEF" stroke-width="3" stroke-linecap="round"/></g>'
  end

  def dino_bootflames_svg
    '<g class="dino-boot-flames"><path d="M222 378L214 418L229 409L240 434L251 411L268 421L269 379M289 376L287 418L301 405L313 428L321 409L337 416L333 374" fill="#FF765E"/><path d="M228 388L226 407L237 400L241 417L250 402L260 410L257 386M296 384L296 405L305 398L314 413L320 398L326 402L327 383" fill="#FFD36C"/><path d="M237 390L241 406L247 390M305 388L311 402L316 388" fill="#FFF4C5"/></g>'
  end

  def dino_badge_svg
    '<g class="dino-badge"><path d="M301 305L297 326L307 320L315 325L316 305" fill="#FF765E"/><circle cx="306" cy="301" r="15" fill="#B18039"/><circle cx="306" cy="299" r="13" fill="#FFD36C"/><path d="M306 289L309 296L316 297L311 302L312 309L306 306L300 309L301 302L296 297L303 296Z" fill="#B18039"/></g>'
  end

  def dino_headphones_svg
    '<g class="dino-headphones"><path d="M227 153L229 120C232 73 327 69 347 114L352 144" stroke="#22574C" stroke-width="10" stroke-linecap="round"/><path d="M239 105C255 81 306 79 329 100" stroke="#C59CE2" stroke-width="7" stroke-linecap="round"/><rect x="215" y="138" width="24" height="37" rx="10" fill="#9665B7"/><rect x="219" y="142" width="15" height="28" rx="7" fill="#C59CE2"/><path d="M224 148V161" stroke="#EBD8F8" stroke-width="4" stroke-linecap="round"/><path d="M342 137C350 131 360 140 360 150V163L348 167L342 157Z" fill="#9665B7"/><path d="M352 144V157" stroke="#C59CE2" stroke-width="5" stroke-linecap="round"/><path d="M226 174C226 187 240 194 255 194" stroke="#22574C" stroke-width="4"/><rect x="250" y="189" width="15" height="8" rx="4" fill="#FF765E"/></g>'
  end

  def dino_guardians_svg
    '<g class="dino-guardians"><ellipse cx="270" cy="228" rx="213" ry="94" transform="rotate(-17 270 228)" stroke="#62CAB2" stroke-width="2" stroke-dasharray="5 8" stroke-opacity=".7"/><g class="dino-drone-left"><ellipse cx="83" cy="250" rx="24" ry="5" fill="#62CAB2" fill-opacity=".2"/><path d="M55 229L83 214L110 229L83 246Z" fill="#22574C"/><path d="M62 229L83 218L103 229L83 239Z" fill="#62CAB2"/><path d="M74 224H92L97 232H70Z" fill="#173E35"/><circle cx="83" cy="228" r="4" fill="#FFD36C"/><path d="M53 222H65M103 222H114" stroke="#BFF3E0" stroke-width="3" stroke-linecap="round"/></g><g class="dino-drone-right"><ellipse cx="451" cy="151" rx="25" ry="5" fill="#B89AE4" fill-opacity=".2"/><path d="M423 128L451 113L478 128L451 146Z" fill="#22574C"/><path d="M431 128L451 117L471 128L451 139Z" fill="#B89AE4"/><path d="M443 123H458L463 132H438Z" fill="#173E35"/><circle cx="451" cy="128" r="4" fill="#FFD36C"/><path d="M421 120H434M469 120H481" stroke="#EAD8FF" stroke-width="3" stroke-linecap="round"/></g></g>'
  end

  def dino_pedestal_svg
    '<g class="dino-pedestal"><path d="M112 391H411V405C411 439 112 439 112 405Z" fill="#173E35"/><ellipse cx="262" cy="391" rx="150" ry="29" fill="#2D7170"/><ellipse cx="262" cy="389" rx="129" ry="21" stroke="#62CAB2" stroke-width="3"/><ellipse cx="262" cy="389" rx="108" ry="15" fill="#62CAB2" fill-opacity=".13"/><path d="M141 389L164 394M361 395L386 391M226 418H297" stroke="#FFD36C" stroke-width="4" stroke-linecap="round"/><path d="M180 385L206 337H318L343 385" fill="#62CAB2" fill-opacity=".09"/><path d="M176 405L195 407M324 408L343 406" stroke="#62CAB2" stroke-width="3" stroke-linecap="round"/></g>'
  end
end
