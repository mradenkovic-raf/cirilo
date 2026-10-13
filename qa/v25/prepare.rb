abort "Preview database only" unless ENV["DATABASE_PATH"] == "storage/v25-browser.sqlite3"
session = PracticeSession.sole
learner = session.learner
planner = SchoolPracticePlanner.new(learner, letter_ids: learner.school_letter_ids, variation: 0)
kind, word = ARGV
task = if kind == "story"
  variation = SchoolStoryBank.eligible(learner.school_letter_ids).index { |item| item["story_sentence"] == word }
  raise "Unknown preview sentence" unless variation
  planner.exercises.find { |item| item["kind"] == "story_action" }.merge(
    SchoolStoryBank.exercise(letter_ids: learner.school_letter_ids, variation: variation))
else
  raise "Unsupported preview" unless %w[read_word picture_word build_word].include?(kind)
  entry = SchoolWordBank.find(word) || raise("Unknown preview word")
  raise "Word outside selected letters" unless SchoolWordBank.eligible(learner.school_letter_ids).include?(entry)
  letter = Curriculum.letters.find { |item| item.fetch("upper") == word[0] }
  planner.send(:build, entry, letter, kind, "upper", 0)
end
learner.letter_progresses.find_or_create_by!(letter_id: task.fetch("letter_id"))
session.update!(exercises: [task] + session.exercises.drop(1), cursor: 0)
puts task.slice("kind", "word", "story_sentence", "choices", "options").to_json
