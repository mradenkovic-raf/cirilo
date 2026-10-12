raise "Preview database only" unless ENV["DATABASE_PATH"] == "storage/v14-browser.sqlite3"
learner = Learner.current
if ARGV.first == "sample"
  kind, word = ARGV.fetch(1), ARGV.fetch(2)
  raise "Unsupported preview" unless %w[read_word picture_word repair_word word_pairs sentence build_word].include?(kind)
  entry = WordBank.find(word) || raise("Unknown word")
  letter = Curriculum.letters.find { |item| item.fetch("upper") == word[0] }
  task = PracticePlanner.send(:exercise, letter, entry, kind, "upper")
  task.merge!(VarietyBank.public_send(kind, entry)) if %w[picture_word word_pairs].include?(kind)
  task.merge!(VarietyBank.repair_word(entry, letter: letter)) if kind == "repair_word"
  mission = learner.practice_sessions.sole
  mission.update!(cursor: mission.exercises.length, exercises: mission.exercises + [task])
  puts task.slice("kind", "word", "options", "pair_words").to_json
  exit
end
if ARGV.first == "position"
  mission = learner.practice_sessions.sole
  cursor = Integer(ARGV.fetch(1))
  raise "Invalid fixture position" unless (0...mission.exercises.length).cover?(cursor)
  mission.update!(cursor: cursor)
  puts mission.current_exercise.slice("kind", "word", "target", "case").to_json
  exit
end
raise "Use a fresh preview database" if learner.attempts.exists? || learner.practice_sessions.count > 1
exercises = []
[["А", "trace", "upper"], ["Г", "trace", "upper"], ["Ж", "trace", "upper"], ["Ј", "trace", "lower"],
 [WordBank.words.max_by { |entry| entry.fetch("word").length }.fetch("word"), "write_word", "upper"],
 ["ЂЕВРЕК", "fill_letters", "lower"]].each do |word, kind, form|
  letter = Curriculum.letters.find { |item| item.fetch("upper") == word[0] }
  entry = WordBank.find(word) || WordBank.for_letter(letter)
  exercise = PracticePlanner.send(:exercise, letter, entry, kind, form)
  exercises << exercise
  learner.letter_progresses.find_or_create_by!(letter_id: letter.fetch("id"))
end
mission = learner.practice_sessions.first || learner.practice_sessions.new
mission.update!(exercises: exercises, focus_letters: exercises.map { |item| item.fetch("letter_id") }.uniq)
puts({ path: "/practice_sessions/#{mission.id}", tasks: exercises.map { |item| item.slice("kind", "word", "target", "case") } }.to_json)
