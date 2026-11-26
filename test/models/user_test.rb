require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "identifica os papéis admin e attendant" do
    assert users(:admin).admin?
    assert_not users(:admin).attendant?
    assert_equal "admin", users(:admin).role

    assert users(:attendant).attendant?
    assert_not users(:attendant).admin?
    assert_equal "attendant", users(:attendant).role
  end

  test "usuário sem papel não é admin nem attendant" do
    user = User.create!(
      name: "Sem Papel",
      email: "sem.papel.model@example.com",
      password: "123456",
      password_confirmation: "123456"
    )

    assert_not user.admin?
    assert_not user.attendant?
    assert_nil user.role
  end

  test "system_user é idempotente e não expõe senha previsível" do
    user = User.system_user

    assert user.persisted?
    assert_equal user, User.system_user
    assert_equal "system@motelflow.local", user.email
  end
end
