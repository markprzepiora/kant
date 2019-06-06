require 'spec_helper'
require 'kant/policy_access'
require 'kant/access_denied'

describe Kant::PolicyAccess do
  setup_models

  it "has a #user method" do
    user = User.create!(email: 'foo@bar.com')
    policy_access = Kant::PolicyAccess.new(user)
    expect(policy_access.user).to eq(user)
  end

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

    it "uses FooPolicy to authorize Foo itself" do
      bell = double("bell")
      expect(bell).to receive(:ring).with(Todo, user).and_return(nil)

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

      expect(policy_access.can?(:tickle, Todo)).to eq("foo")
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
    let(:another_user) { User.create!(email: 'foo@baz.com') }
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

    # The motivation here is that, when performing authorization for "index"
    # actions, this often involves some context. For example, the user might be
    # listing all the todos under a particular project (GET /projects/1/todos).
    # In a lot of cases it might be possible to define an ActiveRecord or SQL
    # query that describes what records the user can access regardless of
    # context, but in some cases this might result in a very complicated query.
    # (Unfortunately, the example below really doesn't really do the motivation
    # justice.)
    #
    # Imagine instead that a user can normally only access their own User
    # record (the check being `user == me`). However, when the user is part of
    # a project they can also see other users in the company that the project
    # is a part of. (For example, so that they can send a DM to a user.)
    #
    # - Company
    #   - has many Projects
    #     - has many Users
    #
    # Imagine what the query would look like to return all the users I can
    # message...
    #
    #     def self.readable_for_messaging(users, me)
    #       my_companies = Company.joins(:projects).merge(me.projects)
    #       my_companies_projects = Project.joins(:company).merge(my_companies)
    #       my_companies_users = User.joins(:projects).merge(my_companies_projects)
    #       users.merge(my_companies_users)
    #     end
    #
    # Some notes here:
    #
    # 1. This honestly isn't such a gross example, in production this logic can
    #    get much, much worse.
    # 2. Even so, you can see it gets pretty complicated.
    # 3. In practice what we have to do after all this is query the resulting
    #    scope for users in a particular company... which means more gross queries.
    #
    # Instead, by having extra params in the *able function, we can specify a
    # context (typically this will probably match the shape of the endpoint, so
    # if your endpoint is /companies/1/users then your *able function will
    # probably take an extra `companies:` param).
    #
    #     def self.readable_for_messaging(users, me, company:)
    #       my_companies = Company.joins(:projects).merge(me.projects)
    #       if !my_companies.where(id: company.id).any?
    #         fail Kant::AccessDenied, "no access"
    #       end
    #
    #       users.joins(:projects).where(projects: { company_id: company.id })
    #     end
    it "passes along other params to the *able method" do
      # module TodoPolicy
      #   def self.readable_as_owner(todos, user, project:)
      #     if project.owner_id == user.id
      #       todos.where(project_id: project_id, completed: true)
      #     else
      #       fail Kant::AccessDenied, "user does not have access to this project"
      #     end
      #   end
      # end
      todo_policy = Class.new do
        define_singleton_method(:readable_as_owner) do |todos, user, project: nil|
          fail ArgumentError if !project

          if project.owner_id == user.id
            todos.where(project_id: project.id, completed: true)
          else
            fail Kant::AccessDenied, "user does not have access to this project"
          end
        end
      end

      stub_const("TodoPolicy", todo_policy)

      my_project = Project.create!(owner: user)
      another_project = Project.create!(owner: another_user)
      my_complete_todo = Todo.create!(project: my_project, completed: true)
      my_incomplete_todo = Todo.create!(project: my_project, completed: false)
      another_complete_todo = Todo.create!(project: another_project, completed: true)

      expect{
        policy_access.accessible(:read_as_owner, Todo)
      }.to raise_error(ArgumentError)

      expect(policy_access.accessible(:read_as_owner, Todo, project: my_project)).to eq([my_complete_todo])

      expect{
        policy_access.accessible(:read_as_owner, Todo, project: another_project)
      }.to raise_error(Kant::AccessDenied)
    end
  end

  describe "the policies_module option in initializer" do
    let(:user) { User.create!(email: 'foo@bar.com') }

    it "can be specified to namespace policies" do
      # module Policies::TodoPolicy
      #   def self.readable(todos, user)
      #     todos.where(completed: true)
      #   end
      # end
      todo_policy = Class.new do
        define_singleton_method(:readable) do |todos, user|
          todos.where(completed: true)
        end
      end

      stub_const("Policies", Module.new)
      stub_const("Policies::TodoPolicy", todo_policy)

      policy_access = Kant::PolicyAccess.new(user, policies_module: Policies)

      complete_todo = Todo.create!(completed: true)
      incomplete_todo = Todo.create!(completed: false)

      expect(policy_access.accessible(:read, Todo)).to eq([complete_todo])
    end
  end
end
