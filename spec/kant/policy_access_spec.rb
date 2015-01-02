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

      # module TodoPolicy
      #   def self.can_tickle?(todo, user)
      #     bell.ring(todo, user)
      #     "foo"
      #   end
      # end
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

    it "uses an *able scope method if no can_*? method exists" do
      # module TodoPolicy
      #   def self.readable(todos, user)
      #     todos.where(completed: true)
      #   end
      # end
      todo_policy = Class.new do
        define_singleton_method(:readable) do |todos, user|
          todos.where(completed: true)
        end
      end

      stub_const("TodoPolicy", todo_policy)

      complete_todo = Todo.create!(completed: true)
      incomplete_todo = Todo.create!(completed: false)

      expect(policy_access).to be_able_to(:read, complete_todo)
      expect(policy_access).not_to be_able_to(:read, incomplete_todo)

      expect(policy_access).not_to be_able_to(:tickle, complete_todo)
      expect(policy_access).not_to be_able_to(:tickle, incomplete_todo)
    end
  end

  describe "#accessible" do
    let(:user) { User.create!(email: 'foo@bar.com') }
    subject(:policy_access) { Kant::PolicyAccess.new(user) }

    it "delegates to a Policy module" do
      # module TodoPolicy
      #   def self.readable(todos, user)
      #     todos.where(completed: true)
      #   end
      # end
      todo_policy = Class.new do
        define_singleton_method(:readable) do |todos, user|
          todos.where(completed: true)
        end
      end

      stub_const("TodoPolicy", todo_policy)

      complete_todo = Todo.create!(completed: true)
      incomplete_todo = Todo.create!(completed: false)

      expect(policy_access.accessible(:read, Todo)).to eq([complete_todo])
      expect(policy_access.accessible(:read, Todo.where(completed: false))).to eq([])
    end

    it "returns an empty scope when no scope method is defined" do
      stub_const("TodoPolicy", Class.new)

      complete_todo = Todo.create!(completed: true)
      incomplete_todo = Todo.create!(completed: false)

      expect(policy_access.accessible(:read, Todo)).to eq(Todo.none)
    end
  end
end
