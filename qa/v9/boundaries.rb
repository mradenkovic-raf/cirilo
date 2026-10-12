raise "Use DATABASE_PATH=storage/v9-browser.sqlite3" unless ENV["DATABASE_PATH"] == "storage/v9-browser.sqlite3"
learner = Learner.current
session = learner.active_session || PracticePlanner.start!(learner)
letter = Curriculum.find("i")
entry = WordBank.find("ЛИСИЦА")
tasks = %w[repair_word word_pairs].map do |kind|
  common = { "id" => SecureRandom.uuid, "version" => PracticePlanner::VERSION,
    "kind" => kind, "letter_id" => letter.fetch("id"), "case" => "upper",
    "display_case" => "upper", "review_only" => false }
  content = kind == "repair_word" ? VarietyBank.repair_word(entry, letter: letter) : VarietyBank.word_pairs(entry)
  common.merge(content)
end
session.update!(exercises: tasks, cursor: ARGV.first == "pairs" ? 1 : 0)
puts({ fixture_only: true, path: "/practice_sessions/#{session.id}", kind: session.current_exercise["kind"] }.to_json)
