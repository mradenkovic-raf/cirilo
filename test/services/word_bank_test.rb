require "test_helper"

class WordBankTest < ActiveSupport::TestCase
  test "expanded full alphabet bank includes short illustrated everyday words" do
    assert_operator WordBank.words.length, :>=, 160
    %w[СОМ СТО СИТО ТОСТ САНТА МЕСО СЕМЕ СЕНО МОНЕТА ОРМАН ПАНДА РОБОТ].each do |word|
      entry = WordBank.find(word)
      assert entry, word
      assert_operator word.length, :<=, 6
    end
    WordBank.words.select { |entry| entry["image"] }.each do |entry|
      assert_includes SchoolWordBank.image_paths, entry.fetch("image")
      choices = WordBank.picture_choices(entry)
      assert_equal entry.fetch("image"), choices.find { |choice| choice.fetch("value") == entry.fetch("word") }.fetch("image")
    end
  end

  test "every Serbian letter rotates through at least three illustrated words starting with it" do
    Curriculum.letters.each do |letter|
      starting_words = WordBank.words.select { |entry| entry.fetch("word").start_with?(letter.fetch("upper")) }
      assert_operator starting_words.length, :>=, 3, "Not enough starting words for #{letter.fetch('upper')}"
      choices = starting_words.length.times.map { |variation| WordBank.for_letter(letter, variation: variation) }
      assert_equal starting_words.map { |entry| entry.fetch("word") }.sort, choices.map { |entry| entry.fetch("word") }.sort
      assert_equal choices.first, WordBank.for_letter(letter, variation: choices.length)
      choices.each do |entry|
        assert entry.fetch("word").start_with?(letter.fetch("upper"))
        assert entry.fetch("emoji").present?
      end
    end
  end

  test "rotation respects excluded words without abandoning the starting letter" do
    letter = Curriculum.find("a")
    first = WordBank.for_letter(letter)
    replacement = WordBank.for_letter(letter, excluding: [first.fetch("word")])
    assert_not_equal first.fetch("word"), replacement.fetch("word")
    assert replacement.fetch("word").start_with?(letter.fetch("upper"))
    assert_equal first, WordBank.for_letter(letter, excluding: WordBank.words.map { |entry| entry.fetch("word") })
  end

  test "word and sentence data use the Serbian alphabet and never include the missing answer" do
    alphabet = Curriculum.letters.map { |letter| letter.fetch("upper") }
    assert_equal WordBank.words.length, WordBank.words.map { |entry| entry.fetch("word") }.uniq.length
    WordBank.words.each do |entry|
      word = entry.fetch("word")
      assert_includes 3..8, word.length
      assert_empty word.chars - alphabet
      assert_equal 1, entry.fetch("sentence").count("▢")
      assert_not_includes entry.fetch("sentence").upcase.scan(/\p{L}+/), word
      assert_equal 3, entry.fetch("sentence_options").uniq.length
      assert_not_includes entry.fetch("sentence_options"), word
      entry.fetch("sentence_options").each do |option|
        assert_includes 3..8, option.length
        assert_empty option.chars - alphabet
      end
    end
  end

  test "reading picture choices cannot offer two pictures from the same meaning group" do
    WordBank.words.each do |entry|
      choices = WordBank.picture_choices(entry)
      assert_equal 4, choices.map { |choice| choice.fetch("value") }.uniq.length
      assert_equal 4, choices.map { |choice| choice.fetch("label") }.uniq.length
      assert_includes choices.map { |choice| choice.fetch("value") }, entry.fetch("word")
      groups = choices.filter_map { |choice| WordBank.find(choice.fetch("value"))["picture_group"] }
      assert_equal groups.uniq, groups
    end
  end

  test "known ambiguous pictures are grouped even when their emoji are different" do
    [%w[АУТО ЏИП], %w[НОС ЊУШКА ЊУХ], %w[БРОД ЧАМАЦ], %w[ЂАК ЉУДИ], %w[ЈАГОДА ЏЕМ],
      %w[ЉУТО ЂУМБИР], %w[АЛАТ ИГЛА НОЖ КЉУЧ ЧЕШАЉ УДИЦА]].each do |group|
      group.combination(2).each do |left, right|
        assert WordBank.visually_ambiguous?(WordBank.find(left), WordBank.find(right)), "#{left} / #{right}"
      end
    end
    assert_not WordBank.visually_ambiguous?(WordBank.find("ЛАВ"), WordBank.find("ТИГАР"))
  end

  test "repeated letters have separate usable tiles and two genuinely extra letters" do
    tiles = WordBank.tiles("МАЧКА")
    assert_equal 7, tiles.length
    assert_equal 2, tiles.count("А")
    assert_equal 1, tiles.count("М")
    assert_equal 1, tiles.count("Ч")
    assert_equal 1, tiles.count("К")
    assert_equal 2, tiles.reject { |tile| "МАЧКА".include?(tile) }.uniq.length
    assert_not_equal "МАЧКА", tiles.first(5).join
  end
end
