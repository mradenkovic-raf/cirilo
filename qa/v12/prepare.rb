raise "Preview database only" unless ENV["DATABASE_PATH"] == "storage/v12-browser.sqlite3"
learner = Learner.current
case ARGV.fetch(0)
when "setup"
  raise "Fresh preview only" if learner.battles.exists?
  learner.update!(dino_color: "blue")
  16.times do |index|
    mission = learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
    learner.part_unlocks.create!(practice_session: mission, position: index + 1,
      part_key: Curriculum.part_at(index + 1).fetch("id"))
    if [0, 15].include?(index)
      battle = BattleArena.start!(learner, mission)
      battle.update!(next_enemy_move: "guard")
      puts({ battle: battle.id, armor: battle.gear_count }.to_json)
    end
  end
when "lose_next"
  battle = learner.battles.find(Integer(ARGV.fetch(1)))
  raise "Active battle only" unless battle.active?
  battle.update!(next_enemy_move: "guard")
end
