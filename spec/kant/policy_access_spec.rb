require 'spec_helper'
require 'kant/policy_access'

describe Kant::PolicyAccess do
  setup_models

  describe "#can?" do
    let(:user) { User.create!(email: 'foo@bar.com') }
    subject(:policy_access) { Kant::PolicyAccess.new(user) }

    it "uses FooPolicy to authorize Foos" do
      todo = Todo.create
      bell = double("bell")
      expect(bell).to receive(:ring).with(todo, user).and_return(nil)

      todo_policy = Class.new do
        define_singleton_method(:can_tickle?) do |todo, user|
          bell.ring(todo, user)
          "foo"
        end
      end

      stub_const("TodoPolicy", todo_policy)

      expect(policy_access.can?(:tickle, todo)).to eq("foo")
      expect(policy_access.can?(:read, todo)).to eq(false)
    end

    it "returns false for an undefined action" do
      todo = Todo.create
      stub_const("TodoPolicy", Class.new)

      expect(policy_access.can?(:tickle, todo)).to eq(false)
    end

    it "returns false if FooPolicy does not exist" do
      todo = Todo.create
      expect(policy_access.can?(:tickle, todo)).to eq(false)
    end
  end
end
