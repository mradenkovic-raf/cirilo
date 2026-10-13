ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: 1)

  private

  def test_learner
    # Existing regression scenarios exercise the original full-alphabet game.
    # School-mode tests create learners explicitly and verify the new default.
    @test_learner ||= Learner.create!(learning_mode: "full")
  end
end

class ActionDispatch::IntegrationTest
  private

  def test_learner
    return @test_learner if @test_learner

    # Bootstrap explicitly when arranging a test, never replace a response that
    # the test has already received and still needs to assert against.
    unless request
      get root_path
      assert_response :success
    end

    assert cookies[:cirilo_device].present?, "The browser must receive its own device cookie"
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    token = jar.encrypted[:cirilo_device]
    assert token.present?, "The device cookie must decrypt successfully"
    @test_learner = Learner.find_by!(device_token_digest: Learner.device_digest(token))
    @test_learner.update!(learning_mode: "full")
    @test_learner
  end
end
