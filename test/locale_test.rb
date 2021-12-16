# frozen_string_literal: true

require_relative "test_helper"

class LocaleTest < Minitest::Test
  def test_match
    assert Addressing::Locale.match("en-US", "EN_us")
    assert Addressing::Locale.match("de", "de")

    refute Addressing::Locale.match("de", "de-AT")
    refute Addressing::Locale.match("de", "fr")
  end

  def test_match_candidates
    assert Addressing::Locale.match_candidates("en-US", "EN_us")
    assert Addressing::Locale.match_candidates("de", "de")
    assert Addressing::Locale.match_candidates("de", "de-AT")

    refute Addressing::Locale.match_candidates("de", "fr")
    # zh-Hant falls back to "und" instead of "zh".
    refute Addressing::Locale.match_candidates("zh", "zh-Hant")
  end

  def test_resolve
    available_locales = ["bs-Cyrl", "bs", "en"]
    locale = Addressing::Locale.resolve(available_locales, "bs-Cyrl-BA")
    assert_equal "bs-Cyrl", locale

    locale = Addressing::Locale.resolve(available_locales, "bs-Latn-BA")
    assert_equal "bs", locale

    locale = Addressing::Locale.resolve(available_locales, "de", "en")
    assert_equal "en", locale
  end

  def test_resolve_without_result
    assert_raises(Addressing::UnknownLocaleError) do
      Addressing::Locale.resolve(["bs", "en"], "de")
    end
  end

  def test_canonicalize
    locale = Addressing::Locale.canonicalize("BS_cyrl-ba")
    assert_equal "bs-Cyrl-BA", locale

    locale = Addressing::Locale.canonicalize(nil)
    assert_nil locale
  end

  def test_candidates
    candidates = Addressing::Locale.candidates("en-US")
    assert_equal ["en-US", "en"], candidates

    candidates = Addressing::Locale.candidates("en-US", "en")
    assert_equal ["en-US", "en"], candidates

    candidates = Addressing::Locale.candidates("sr", "en-US")
    assert_equal ["sr", "en-US", "en"], candidates

    candidates = Addressing::Locale.candidates("en-AU")
    assert_equal ["en-AU", "en-001", "en"], candidates

    candidates = Addressing::Locale.candidates("sh")
    assert_equal ["sr-Latn"], candidates
  end

  def test_parent
    assert_equal "sr-Latn", Addressing::Locale.parent("sr-Latn-RS")

    # sr-Latn falls back to "und" instead of "sr".
    assert_nil Addressing::Locale.parent("sr-Latn")
    assert_nil Addressing::Locale.parent("sr")
  end

  def test_replace_alias
    locale = Addressing::Locale.replace_alias("zh-CN")
    assert_equal "zh-Hans-CN", locale

    locale = Addressing::Locale.replace_alias(nil)
    assert_nil locale
  end
end
