require "test_helper"

class DeviceIdentityTest < ActionDispatch::IntegrationTest
  test "each new browser starts empty and cannot claim the archived learner" do
    archived = Learner.create!(xp: 720, completed_missions: 9)
    archived.update_column(:device_token_digest, nil)
    archived.letter_progresses.create!(letter_id: "a", correct_count: 7, review_level: 3)

    first, first_learner = new_browser
    second, second_learner = new_browser

    assert_not_equal first_learner.id, second_learner.id
    assert_not_equal first.cookies[:cirilo_device], second.cookies[:cirilo_device]
    [first_learner, second_learner].each do |learner|
      assert_equal [0, 0, 0], learner.values_at(:xp, :xp_spent, :completed_missions)
      assert_empty learner.letter_progresses
      assert_empty learner.practice_sessions
      assert_empty learner.shop_purchases
      assert_equal({}, learner.egg_state)
      assert_match(/\A[0-9a-f]{64}\z/, learner.device_token_digest)
    end
    assert_equal [720, 9, nil], archived.reload.values_at(:xp, :completed_missions, :device_token_digest)
    assert_equal 7, archived.letter_progresses.sole.correct_count
  end

  test "persistent device cookie alone restores progress after the Rails session is gone" do
    browser, learner = new_browser
    learner.update!(xp: 180, completed_missions: 2)
    browser.post practice_sessions_path
    assert_equal 303, browser.response.status
    mission = learner.practice_sessions.sole
    identity_cookie = browser.cookies[:cirilo_device]

    restarted = ActionDispatch::Integration::Session.new(Rails.application)
    restarted.cookies[:cirilo_device] = identity_cookie
    assert_no_difference "Learner.count" do
      restarted.get root_path
      assert_equal 200, restarted.response.status
      restarted.get practice_session_path(mission)
      assert_equal 200, restarted.response.status
      restarted.post practice_sessions_path
      assert_equal 303, restarted.response.status
    end
    assert_equal practice_session_url(mission), restarted.response.location
    assert_equal [180, 2], learner.reload.values_at(:xp, :completed_missions)
    assert_equal 1, learner.practice_sessions.count
  end

  test "cookie lasts beyond a year and has browser privacy flags" do
    browser, = new_browser
    header = device_cookie_header(browser)
    assert_includes browser.response.headers.fetch("Cache-Control"), "no-store"
    assert_match(/;\s*path=\//i, header)
    assert_match(/;\s*httponly/i, header)
    assert_match(/;\s*samesite=lax/i, header)
    expires = header.match(/expires=([^;]+)/i)&.captures&.first
    assert expires.present?, "The identity cookie must outlive the browser session"
    assert_operator Time.httpdate(expires), :>, 1.year.from_now
    assert_no_match(/;\s*secure(?:;|\z)/i, header)

    encrypted_browser = ActionDispatch::Integration::Session.new(Rails.application)
    encrypted_browser.https!
    encrypted_browser.get root_path
    assert_equal 200, encrypted_browser.response.status
    assert_match(/;\s*secure(?:;|\z)/i, device_cookie_header(encrypted_browser))
  end

  test "HEAD can initialize a device and ordinary reads reuse it" do
    browser = ActionDispatch::Integration::Session.new(Rails.application)
    assert_difference "Learner.count", 1 do
      browser.head root_path
      assert_equal 200, browser.response.status
    end
    assert browser.cookies[:cirilo_device].present?
    assert_no_difference "Learner.count" do
      [root_path, workshop_path, alphabet_path, progress_path, shop_path, adventure_path].each do |path|
        browser.get path
        assert_equal 200, browser.response.status
      end
    end
  end

  test "missing device cookie rejects a stale mutation then a fresh visit starts empty" do
    browser, learner = new_browser
    learner.update!(xp: 300)
    browser.cookies.delete("cirilo_device")

    assert_no_difference ["Learner.count", "PracticeSession.count", "ShopPurchase.count"] do
      browser.post practice_sessions_path
      assert_equal 422, browser.response.status
      browser.post shop_purchases_path, params: { item_id: "color_ice", shop_generation: 1 }, as: :json
      assert_equal 422, browser.response.status
      assert_equal false, browser.response.parsed_body["success"]
      assert browser.response.parsed_body["error"].present?
    end
    assert_nil browser.cookies[:cirilo_device]
    assert_equal 300, learner.reload.xp

    before = Learner.pluck(:id)
    browser.get root_path
    assert_equal 200, browser.response.status
    replacement = Learner.where.not(id: before).sole
    assert_equal 0, replacement.xp
    assert_not_equal learner.id, replacement.id
    assert_equal 300, learner.reload.xp
  end

  test "anonymous mutations never provision a learner or alter archived progress" do
    archived = Learner.create!(xp: 400)
    archived.update_column(:device_token_digest, nil)
    browser = ActionDispatch::Integration::Session.new(Rails.application)
    requests = [
      [:post, practice_sessions_path, {}],
      [:post, shop_purchases_path, { item_id: "color_ice", shop_generation: 1 }],
      [:patch, equip_shop_path, { item_id: "color_blue", shop_generation: 1 }],
      [:patch, customize_workshop_path, { dino_color: "blue", shop_generation: 1 }],
      [:post, egg_workshop_path, { species: "rex", shop_generation: 1 }],
      [:post, reset_dino_workshop_path, { confirm_reset: "1", dinosaur_generation: 1 }],
      [:post, reset_shop_progress_path, { confirm_reset: "1", reset_word: "RESET", shop_generation: 1 }],
      [:post, reset_all_progress_path, { confirm_reset: "1", reset_word: "RESET", shop_generation: 1, dinosaur_generation: 1 }]
    ]
    assert_no_difference ["Learner.count", "PracticeSession.count", "ShopPurchase.count"] do
      requests.each do |method, path, params|
        browser.public_send(method, path, params: params)
        assert_equal 422, browser.response.status, "#{method.upcase} #{path}"
        assert_nil browser.cookies[:cirilo_device]
      end
    end
    assert_equal [400, 1, 1], archived.reload.values_at(:xp, :shop_generation, :dinosaur_generation)
  end

  test "a fabricated cookie or tampered encrypted cookie cannot reuse another device" do
    owner, learner = new_browser
    learner.update!(xp: 260)
    tampered = owner.cookies[:cirilo_device].dup
    tampered[0] = tampered[0] == "A" ? "B" : "A"

    ["untrusted", "A" * 43, learner.id.to_s, learner.device_token_digest, tampered].each do |cookie|
      browser = ActionDispatch::Integration::Session.new(Rails.application)
      browser.cookies[:cirilo_device] = cookie
      assert_no_difference ["Learner.count", "PracticeSession.count"] do
        browser.post practice_sessions_path, as: :json
        assert_equal 422, browser.response.status
      end
      before = Learner.pluck(:id)
      browser.get root_path
      assert_equal 200, browser.response.status
      assert_equal 0, Learner.where.not(id: before).sole.xp
    end
    assert_equal 260, learner.reload.xp
    assert_empty learner.practice_sessions
  end

  test "a valid encrypted token that no longer resolves cannot select another learner" do
    browser, learner = new_browser
    learner.update!(xp: 390)
    learner.update_column(:device_token_digest, Learner.device_digest(SecureRandom.urlsafe_base64(32)))

    assert_no_difference ["Learner.count", "PracticeSession.count"] do
      browser.post practice_sessions_path, as: :json
      assert_equal 422, browser.response.status
    end
    before = Learner.pluck(:id)
    browser.get root_path
    assert_equal 200, browser.response.status
    assert_equal 0, Learner.where.not(id: before).sole.xp
    assert_equal 390, learner.reload.xp
  end

  test "a form from a deleted browser identity cannot reset the replacement identity" do
    with_forgery_protection do
      browser, original = new_browser
      original.update!(xp: 270)
      original_token = csrf_token(browser)
      browser.cookies.delete("cirilo_device")

      before = Learner.pluck(:id)
      browser.get progress_path
      assert_equal 200, browser.response.status
      replacement = Learner.where.not(id: before).sole
      replacement_token = csrf_token(browser)
      replacement.update!(xp: 500)
      ShopService.new(replacement).purchase!(item_id: "color_ice", generation: 1)
      replacement_before = replacement.reload.attributes
      reset_params = { confirm_reset: "1", reset_word: "RESET", shop_generation: "1" }

      browser.post reset_shop_progress_path, params: reset_params.merge(authenticity_token: original_token)
      assert_equal 422, browser.response.status
      assert_equal replacement_before, replacement.reload.attributes
      assert_equal ["color_ice"], replacement.shop_purchases.pluck(:item_key)
      assert_equal 270, original.reload.xp

      browser.post reset_shop_progress_path, params: reset_params.merge(authenticity_token: replacement_token)
      assert_equal 303, browser.response.status
      assert_equal [0, 0, 2], replacement.reload.values_at(:xp, :xp_spent, :shop_generation)
      assert_empty replacement.shop_purchases
      assert_equal 270, original.reload.xp
    end
  end

  test "knowing the device cookie does not bypass normal CSRF protection" do
    with_forgery_protection do
      browser, learner = new_browser
      token = csrf_token(browser)
      assert_no_difference ["Learner.count", "PracticeSession.count"] do
        browser.post practice_sessions_path
        assert_equal 422, browser.response.status
      end
      browser.post practice_sessions_path, params: { authenticity_token: token }
      assert_equal 303, browser.response.status
      assert_equal 1, learner.practice_sessions.count
    end
  end

  private

  def with_forgery_protection
    previous = ApplicationController.allow_forgery_protection
    ApplicationController.allow_forgery_protection = true
    yield
  ensure
    ApplicationController.allow_forgery_protection = previous
  end

  def csrf_token(browser)
    token = Nokogiri::HTML(browser.response.body).at_css('meta[name="csrf-token"]')&.[]("content")
    assert token.present?, "The page must issue a real CSRF token"
    token
  end

  def new_browser
    browser = ActionDispatch::Integration::Session.new(Rails.application)
    before = Learner.pluck(:id)
    browser.get root_path
    assert_equal 200, browser.response.status
    assert browser.cookies[:cirilo_device].present?
    [browser, Learner.where.not(id: before).sole]
  end

  def device_cookie_header(browser)
    Array(browser.response.headers["set-cookie"]).flat_map { |value| value.split("\n") }
      .find { |value| value.start_with?("cirilo_device=") }.tap do |header|
      assert header.present?, "The response must set the device identity cookie"
    end
  end
end
