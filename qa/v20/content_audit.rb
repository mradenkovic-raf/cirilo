# Run with RAILS_ENV=test and a separate TEST_DATABASE_PATH. All generated
# learners and missions are rolled back; this never targets a player's database.
abort "Use the test environment" unless Rails.env.test?
require_relative "../../test/services/exercise_helpers"
include ExerciseHelpers
rows = SchoolCurriculum.letters.each_with_index.map do |letter, index|
  ids = SchoolCurriculum.letters.first(index + 1).map { |item| item.fetch("id") }
  entries = SchoolWordBank.eligible(ids)
  { through: letter.fetch("upper"), letters: ids.length, words: entries.length,
    new_words: entries.count { |entry| entry.fetch("word").include?(letter.fetch("upper")) },
    pictures: entries.count { |entry| entry.fetch("picture", true) },
    sentences: SchoolStoryBank.eligible(ids).length }
end
week = nil
Learner.transaction do
  learner = Learner.create!
  missions = 42.times.map do
    session = PracticePlanner.start!(learner)
    complete_practice_session(session)
    session.exercises
  end
  words = missions.flatten.flat_map { |task| [task["word"], *task.fetch("pair_words", []).map { |entry| entry["label"] }] }.compact
  signatures = missions.map { |tasks| tasks.map { |task| task.slice("kind", "word", "story_sentence", "case") } }
  sentences = missions.flatten.filter_map { |task| task["story_sentence"] }.uniq
  week = { missions: missions.length, unique_missions: signatures.uniq.length, tasks: missions.flatten.length,
    unique_target_words: words.uniq.length, target_words: words.uniq.sort, unique_sentences: sentences.length,
    reading_tasks: missions.flatten.count { |task| PracticePlanner::READING_KINDS.include?(task.fetch("kind")) },
    writing_tasks: missions.flatten.count { |task| %w[trace write_word fill_letters].include?(task.fetch("kind")) },
    xp: learner.reload.xp, rewards: learner.part_unlocks.count }
  raise "Duplicate whole missions" unless week[:unique_missions] == 42
  raise "Wrong rewards" unless week[:xp] == 42 * 145 && week[:rewards] == 42
  raise ActiveRecord::Rollback
end
puts JSON.pretty_generate({ total_words: SchoolWordBank.words.length,
  length_counts: SchoolWordBank.words.map { |entry| entry.fetch("word").length }.tally.sort.to_h,
  stages: rows, default_week: week })
