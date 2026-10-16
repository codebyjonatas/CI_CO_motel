require "test_helper"

# System tests (Capybara) for the end-to-end flows.
#
# The covered flows are driven by real forms (button_to) and plain links, so
# they do not require JavaScript. The fast RackTest driver is used instead of a
# real browser, which lets the suite run anywhere (local and CI) without
# Chrome/ChromeDriver.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test

  private

  def sign_in_as(user, password: "123456")
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Senha", with: password
    click_button "Entrar"
  end
end
