require "test_helper"

class VarietyBankTest < ActiveSupport::TestCase
  test "picture choices are four real distinct words and do not confuse car pictures" do
    WordBank.words.each do |entry|
      3.times do |variation|
        task = VarietyBank.picture_word(entry, variation: variation)
        assert_equal entry.fetch("word"), task.fetch("answer")
        assert_equal entry.fetch("emoji"), task.fetch("emoji")
        assert_equal 4, task.fetch("options").uniq.length
        assert_includes task.fetch("options"), task.fetch("answer")
        assert task.fetch("options").all? { |word| WordBank.find(word) }
        assert_not (task.fetch("options") & %w[АУТО ЏИП]).length == 2
        groups = task.fetch("options").filter_map { |word| WordBank.find(word)["picture_group"] }
        assert_equal groups.uniq, groups
      end
    end
  end

  test "picture choices favor similar spelling rather than unrelated easy answers" do
    task = VarietyBank.picture_word(WordBank.find("КОЗА"))
    assert_includes task.fetch("options"), "КОЊ"
    assert_includes task.fetch("options"), "КОЗА"
    assert task.fetch("options").any? { |word| word != "КОЗА" && word.start_with?("К") }
  end

  test "every letter supports repair with exactly one corrupted focus letter and four choices" do
    alphabet = Curriculum.letters.map { |letter| letter.fetch("upper") }
    Curriculum.letters.each do |letter|
      3.times do |variation|
        entry = WordBank.for_letter(letter, variation: variation)
        task = VarietyBank.repair_word(entry, letter: letter, variation: variation)
        broken = task.fetch("broken_word")
        correct = task.fetch("answer")
        differences = correct.chars.each_index.select { |index| correct[index] != broken[index] }
        assert_equal correct.length, broken.length
        assert_equal 1, differences.length
        assert_equal letter.fetch("upper"), correct[differences.first]
        assert_equal 4, task.fetch("repair_options").uniq.length
        assert_includes task.fetch("repair_options"), correct[differences.first]
        assert task.fetch("repair_options").all? { |char| alphabet.include?(char) }
        assert broken.chars.all? { |char| alphabet.include?(char) }
        assert_not_includes task.fetch("prompt"), correct
      end
    end
  end

  test "pairing stores a complete mapping without exposing answers in either list" do
    mappings = []
    WordBank.words.each_with_index do |entry, variation|
      task = VarietyBank.word_pairs(entry, variation: variation)
      words = task.fetch("pair_words")
      pictures = task.fetch("pair_pictures")
      answer = task.fetch("answer").split(",")
      mappings << answer
      assert_equal %w[W1 W2 W3], words.map { |item| item.fetch("id") }
      assert_equal %w[P1 P2 P3], pictures.map { |item| item.fetch("id") }.sort
      assert_equal 3, words.map { |item| item.fetch("label") }.uniq.length
      assert_equal 3, pictures.map { |item| item.fetch("emoji") }.uniq.length
      assert_equal %w[P1 P2 P3], answer.sort
      assert_not_equal answer, pictures.map { |item| item.fetch("id") }
      assert_includes words.map { |item| item.fetch("label") }, entry.fetch("word")
      assert_nil task["word"]
      assert_nil task["emoji"]
      words.each_with_index do |word, index|
        assert_equal %w[id label], word.keys.sort
        picture = pictures.find { |item| item.fetch("id") == answer.fetch(index) }
        assert_equal %w[emoji id], picture.keys.sort
        assert_equal WordBank.find(word.fetch("label")).fetch("emoji"), picture.fetch("emoji")
      end
      assert_not (words.map { |item| item.fetch("label") } & %w[АУТО ЏИП]).length == 2
      groups = words.filter_map { |word| WordBank.find(word.fetch("label"))["picture_group"] }
      assert_equal groups.uniq, groups
    end
    assert_operator mappings.uniq.length, :>, 1
  end
end
