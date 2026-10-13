require "test_helper"

class SchoolWordBankTest < ActiveSupport::TestCase
  SCHOOL_ORDER = %w[А М И Т О Н С Е Р Ј У Ш Л Љ З В Г П К Д Б Њ Х Ж Ч Ћ Ф Ц Џ Ђ].freeze

  test "school bank contains many short normalized Serbian words" do
    words = SchoolWordBank.words
    assert_operator words.length, :>=, 350
    assert_equal words.length, words.map { |entry| entry.fetch("word") }.uniq.length

    words.each do |entry|
      word = entry.fetch("word")
      assert_equal word.unicode_normalize(:nfc).upcase, word
      assert_includes 2..6, word.length, word
      assert_empty word.chars - SCHOOL_ORDER, word
      assert entry.fetch("emoji").present?, word
      assert entry.fetch("category").present?, word
      assert_includes [true, false], entry.fetch("picture"), word
    end

    short_words = words.count { |entry| entry.fetch("word").length <= 5 }
    assert_operator short_words.fdiv(words.length), :>=, 0.90
  end

  test "each cumulative stage stays within known letters and adds useful vocabulary" do
    previous = []
    SCHOOL_ORDER.each_with_index do |letter, index|
      allowed = SCHOOL_ORDER.first(index + 1)
      pool = SchoolWordBank.eligible(ids_for(allowed))
      assert_empty previous - pool
      pool.each { |entry| assert_empty entry.fetch("word").chars - allowed, entry.fetch("word") }

      # А alone has no useful stand-alone word; the planner uses letter tasks.
      # From Н onward every step adds at least seven different short words.
      assert_operator (pool - previous).length, :>=, 7, letter if index >= 5
      previous = pool
    end
    assert_equal SchoolWordBank.words, previous
  end

  test "default through E offers broad short word and picture pools" do
    ids = ids_for(SCHOOL_ORDER.first(8))
    pool = SchoolWordBank.eligible(ids)
    pictures = SchoolWordBank.picture_entries(ids)

    assert_operator pool.length, :>=, 60
    assert_operator pictures.length, :>=, 18
    %w[МАМА ТАТА НОС САТ МОСТ МЕСО МЕТА СТЕНА ТЕНИС].each do |word|
      assert_includes pictures.map { |entry| entry.fetch("word") }, word
    end
    %w[АНА НИНА ИМА НОСИ МЕСИ СЕМЕ ТЕСТО].each do |word|
      assert_includes pool.map { |entry| entry.fetch("word") }, word
    end
    assert_not_includes pool.map { |entry| entry.fetch("word") }, "АУТО"
    assert_not_includes pool.map { |entry| entry.fetch("word") }, "МОРЕ"
  end

  test "custom selections and invalid ids never leak unknown letters" do
    assert_empty SchoolWordBank.eligible([])
    assert_empty SchoolWordBank.eligible(nil)
    assert_empty SchoolWordBank.eligible(["not-a-letter"])
    assert_empty SchoolWordBank.eligible(ids_for(%w[А]))
    assert_equal ["МАМА"], SchoolWordBank.eligible(ids_for(%w[М А])).map { |entry| entry.fetch("word") }

    ids = ids_for(%w[К О А])
    assert_equal %w[КОКА ОКО], SchoolWordBank.eligible(ids).map { |entry| entry.fetch("word") }.sort
    assert_equal SchoolWordBank.eligible(ids), SchoolWordBank.eligible(ids + ["unknown", ids.first])
  end

  test "names and actions never masquerade as picture answers" do
    SchoolWordBank.words.select { |entry| %w[name action pronoun concept position quality].include?(entry.fetch("category")) }.each do |entry|
      assert_equal false, entry.fetch("picture"), entry.fetch("word")
    end
    assert_equal SchoolWordBank.find("МАМА"), SchoolWordBank.find("мама")
    assert_nil SchoolWordBank.find("НЕПОСТОЈЕЋАРЕЧ")
  end

  test "early concrete words have specific safe local illustrations" do
    %w[ОСА СОМ СТЕНА СТО СЕНО СИТО ТЕСТО НИТ].each do |word|
      entry = SchoolWordBank.find(word)
      assert entry.fetch("picture"), word
      assert_match %r{\A/school_images/[a-z_]+\.svg\z}, entry.fetch("image")
      assert_includes SchoolWordBank.image_paths, entry.fetch("image")
      source = Rails.public_path.join(entry.fetch("image").delete_prefix("/")).read
      assert_match /<svg\b/, source
      refute_match /<script\b|<foreignObject\b|\bon\w+\s*=|href=/i, source
      assert_match %r{\A#{Regexp.escape(entry.fetch('image'))}\?v=[a-f0-9]{12}\z}, SchoolWordBank.image_url(entry)
    end
    assert_nil SchoolWordBank.image_url(SchoolWordBank.find("ТАТА"))
    assert_nil SchoolWordBank.image_url(nil)
    assert_nil SchoolWordBank.image_url({ "image" => "/etc/passwd" })
    assert_equal false, SchoolWordBank.find("НАНА").fetch("picture")
    assert_not SchoolWordBank.visually_ambiguous?(SchoolWordBank.find("СИТО"), SchoolWordBank.find("ТЕСТО"))
  end

  test "approximate species life stages and related objects remain text-only words" do
    %w[ТУНА ШАРАН СМУЂ СИПА СОКО ОРАХ ЈОГУРТ МАЉ ГРОМ ОКЛОП ПИРАТ ЈАРЕ ЛАНЕ ПАЊ].each do |word|
      assert_equal false, SchoolWordBank.find(word).fetch("picture"), word
    end
  end

  test "picture choices stay scoped and distinct even for related words" do
    [SCHOOL_ORDER.first(2), SCHOOL_ORDER.first(8), SCHOOL_ORDER].each do |letters|
      pool = SchoolWordBank.eligible(ids_for(letters))
      pool.select { |entry| entry.fetch("picture") }.each do |entry|
        choices = SchoolWordBank.distinct_pictures(entry, pool, count: 4)
        assert_includes choices, entry
        assert_operator choices.length, :<=, 4
        assert_empty choices - pool
        choices.combination(2).each do |left, right|
          assert_not SchoolWordBank.visually_ambiguous?(left, right), "#{left.fetch('word')} / #{right.fetch('word')}"
        end
      end
    end

    assert_empty SchoolWordBank.distinct_pictures(SchoolWordBank.find("АНА"), SchoolWordBank.words)
    assert_empty SchoolWordBank.distinct_pictures(SchoolWordBank.find("МАМА"), [])
    assert_empty SchoolWordBank.distinct_pictures(SchoolWordBank.find("МАМА"), SchoolWordBank.words, count: 0)
    assert_empty SchoolWordBank.distinct_pictures(nil, SchoolWordBank.words)
  end

  test "synonyms and species that share an illustration cannot be competing pictures" do
    [%w[СОМ ТУНА ШАРАН РИБА СМУЂ], %w[БАБА НАНА], %w[ДОМ КУЋА СЕЛО],
      %w[АУТО ЏИП], %w[ОСА ПЧЕЛА], %w[ЛАНЕ ЈЕЛЕН], %w[НОС ЊУШКА],
      %w[ГРОМ МУЊА], %w[ДРВО ХРАСТ ЈЕЛА ШУМА], %w[НИТ ВУНА], %w[СУПА ЛОНАЦ]].each do |group|
      group.combination(2).each do |left, right|
        assert SchoolWordBank.visually_ambiguous?(SchoolWordBank.find(left), SchoolWordBank.find(right)), "#{left} / #{right}"
      end
    end
  end

  private

  def ids_for(letters)
    letters.map { |letter| Curriculum.letters.find { |entry| entry.fetch("upper") == letter }.fetch("id") }
  end
end
