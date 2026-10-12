class AdventureMap
  MISSIONS_PER_WORLD = 4
  WORLDS = [
    { id: "forest", name: "Шума", friend: "Лиско", color: "#92C661", shade: "#638F46",
      goal: "Пронађи Лиска у шуми и одведи га кући.", rescued: "Лиско је поново код куће!",
      stops: ["Прати трагове", "Пређи поток", "Прођи кроз жбуње", "Пронађи Лиска"] },
    { id: "cave", name: "Пећина", friend: "Искра", color: "#B09ADD", shade: "#7C66A7",
      goal: "Осветли пећину и покажи Искри излаз.", rescued: "Искра је изашла из пећине!",
      stops: ["Пронађи улаз", "Упали кристал", "Отвори пролаз", "Изведи Искру"] },
    { id: "volcano", name: "Вулкан", friend: "Жарко", color: "#F3A06D", shade: "#BA674A",
      goal: "Направи пут преко вулкана. Жарко те чека!", rescued: "Жарко је на сигурном!",
      stops: ["Сакупи камење", "Направи мост", "Пређи преко лаве", "Помози Жарку"] },
    { id: "space", name: "Свемир", friend: "Звездан", color: "#83C7E5", shade: "#518FAF",
      goal: "Поправи ракету и врати Звездана на његову планету.", rescued: "Звездан је стигао на своју планету!",
      stops: ["Пронађи ракету", "Напуни гориво", "Полетимо!", "Врати Звездана кући"] }
  ].map { |world| world.merge(stops: world.fetch(:stops).freeze).freeze }.freeze
  TOTAL_MISSIONS = WORLDS.length * MISSIONS_PER_WORLD

  attr_reader :completed_missions

  def initialize(learner, completed_missions: learner.completed_missions)
    @completed_missions = [completed_missions.to_i, 0].max
  end

  def self.through(practice_session)
    completed = practice_session.learner.practice_sessions.where(status: "completed")
    completed = if practice_session.completed_at
      completed.where("completed_at < :time OR (completed_at = :time AND id <= :id)", time: practice_session.completed_at, id: practice_session.id)
    else
      completed.where("id <= ?", practice_session.id)
    end
    new(practice_session.learner, completed_missions: completed.count)
  end

  def completed_steps
    [completed_missions, TOTAL_MISSIONS].min
  end

  def completed?
    completed_steps == TOTAL_MISSIONS
  end

  def rescued_count
    completed_steps / MISSIONS_PER_WORLD
  end

  def progress_percent
    (completed_steps * 100.0 / TOTAL_MISSIONS).round
  end

  def worlds
    @worlds ||= WORLDS.each_with_index.map do |world, index|
      first = index * MISSIONS_PER_WORLD
      done = (completed_steps - first).clamp(0, MISSIONS_PER_WORLD)
      state = if done == MISSIONS_PER_WORLD then :completed
      elsif first <= completed_steps then :current
      else :locked end
      world.merge(number: index + 1, completed: done, state: state, unlock_after: first,
        steps: world.fetch(:stops).each_with_index.map do |name, offset|
          number = first + offset + 1
          { number: number, name: name, state: number <= completed_steps ? :completed : number == completed_steps + 1 ? :current : :locked }
        end)
    end
  end

  def current_world
    worlds.find { |world| world[:state] == :current }
  end

  def next_step
    current_world&.fetch(:steps)&.find { |step| step[:state] == :current }
  end

  def just_rescued_world
    return unless completed_missions.positive? && completed_missions <= TOTAL_MISSIONS && (completed_missions % MISSIONS_PER_WORLD).zero?
    worlds[rescued_count - 1]
  end
end
