# Kant

## Overview

### What Kant does NOT do:

- Add a scope to every single ActiveRecord model in your application.
- Add any magic methods to your controllers that fetch your data for you, or
  make any assumptions about how you want to do this.
- Force you to redefine your authorization logic on every single request.

### What Kant does:

- Very little.
- Allows you to pick and choose how much of it you want to use.
- Defines a simple interface (two methods) that your `AccessControl` class
  should implement.
- Provides two simple access control classes (`NoAccess` and `AllAccess`) you
  might want to use for unauthenticated users and admins respectively.
- For typical use cases, Kant gives you a `PolicyAccess` class which allows you
  to split up your authorization logic into various `FooPolicy` classes, one
  for each of your models. This class uses a minimal amount of magic to work
  with `ActiveRecord` models out of the box, but you can extend it easily to
  use any other ORM.
- Provides a module you can include in your Rails controllers which gives you
  an interface very similar to the one you might be used to if you are
  currently using CanCanCan.

### Kant's philosophy

There are two broad classes of actions you probably need to authorize in your
application:

1. Single-record access: namely, can a user perform an action on a given
   record? (Yes or No).
2. Record index access of some sort: namely, give me a list of the records the
   user is allowed to access.

An `AccessControl` class (you might know this as an `Ability` class in CanCan)
is any plain-old Ruby class that is instantiated with a single argument (your
user object), and implements two methods: (1) `can?(action, object)`, which
returns true or false for any action and object (typically a symbol and a
record), and (2) `accessible(action, scope)` which takes an action and a scope
of some kind (typically an ActiveRecord scope) and returns a new scope of which
records the user is allowed to access.

Everything else in Kant is either a very simple API on top of this interface to
make your life easier when using it in a typical Rails app, or an
implementation of an access control class which might work well in a typical
Rails app. However, you can use as little or as much of Kant as you want, and
it certainly doesn't require Rails at all.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kant'
```

And then execute:

    $ bundle

## Usage

### Controller Mixin

Kant provides a `Kant::ControllerMixin` module that you can include in your
ApplicationController if you wish. It adds a couple of methods:

- A `current_access_control` method, which simply returns
  `AccessControl.new(current_user)`. You can override this if you need to, for
  example, choose which access control class to use based on the current user's
  role. See the source code for an example.
- It delegtes `can?(...)` and `accessible(...)` to `current_access_control`.
- It adds an `authorize!(...)` method, which delegates to `can?(...)`, being a
  no-op if `can?` returns true, but raising a `Kant::AccessDenied` exception if
  `can?` returns false.

Be sure to require what you need! Example:

```ruby
require 'kant/controller_mixin'

class ApplicationController < ActionController::Base
  include Kant::ControllerMixin

  # ...
end
```

### Basic All or Nothing Access Controls

If you are using ActiveRecord, Kant provides `Kant::AllAccess` and
`Kant::NoAccess` which you can use for your admins and unauthenticated users
respectively.

`AllAccess` returns true for every `can?` query, and returns `scope.all` for
every `accessible` query. In other words, everything is permitted.

`NoAccess` returns false for every `can?` query, and returns `scope.none` for
every `accessible` query, denying all access.

### Policy-based Access Controls

While you could implement your own access control class from scratch, you
probably just have a typical Rails app in which you just want to implement
per-model, and per-action authorization logic. For this, there's
`Kant::PolicyAccess`.

This is the only part of Kant that contains magic, and assumes you are using
ActiveRecord, but we'll explain the magic entirely with an example:

When a `PolicyAccess` is queried with `can?(:update, foo)`, where `foo` is an
instance of a class named `Foo`, it will look for a class/module named
`FooPolicy`, and a class method on it called `can_update?(record, user)`. It
simply delegates to this function.

For example,

```ruby
module FooPolicy
  def self.can_update?(foo, user)
    foo.owner_id == user.id
  end
end
```

If either `FooPolicy` does not exist, or if `can_update?` is undefined, `can?`
will simply return false.

When a `PolicyAccess` is queried with `accessible(:read, Foo)` where `Foo` is
an ActiveRecord model class (or a scope of that model), Kant will again look
for `FooPolicy`, this time with an instance method called
`readable(scope, user)`, which will be called with `readable(Foo, user)`.

If either the class or method doesn't exist, `Foo.none` will be returned.

For example,

```ruby
module FooPolicy
  def self.readable(foos, user)
    foos.where(owner_id: user.id)
  end
end
```

There is one added bonus to keep in mind. If your policy class implements
`readable` but not `can_read?`, and if `PolicyAccess` is queried with
`can?(:read, foo)`, then it will return,

```ruby
FooPolicy.readable(Foo, user).where(id: foo.id).any?
```

Therefore, you can typically implement just a scope policy for an action and
let the single-object policy be generated automatically. You may want to
implement (in this example) `can_read?(...)` anyway, since you can avoid an
extra SQL query by simply comparing `foo.owner_id == user.id`. However, in
real-world apps, authorizing an action often requires executing a query of some
sort anyway, so it's your choice.

Since scope and object policies are just methods, you can alias them. No magic
required. For example,

```ruby
module FooPolicy
  def self.can_read?(foo, user)
    foo.owner_id == user.id
  end

  alias_method :can_update?, :can_read?
  alias_method :can_destroy?, :can_read?
end
```

## Okay Practices

### Controller Params

This isn't enforced by Kant at all, but you could define your allowed
controller params inside your policy classes. For example:

```ruby
module FooPolicy
  # ...

  def self.create_params(params)
    params.require(:foo).permit(:name)
  end
end

class FoosController < ApplicationController
  def create_params
    FooPolicy.create_params(params)
  end
end
```

### Create and Update Policies

For defining your `can_create?` and `can_update?` policies, it's probably a
good idea to perform the following order of actions in your controllers:

```ruby
foo.assign_attributes(update_params)
authorize! :update, foo
foo.save!
```

This way, in your `can_update?` policy you can check foo's `#changes`, etc.,
methods to see what was changed in case a user might only be allowed to modify
some fields but not others, or only make certain kinds of changes.

### DRYing Up Your Controllers

You might be worried about missing out on CanCan's magical controller methods
that fetch and authorize your records for you.

But why not instead just define a method like this in `ApplicationController`?

```ruby
def find_and_authorize(model_class, id, action)
  record = model_class.find(id)
  authorize! action, record
  record
end
```

Now you can just,

```ruby
foo = find_and_authorize(Foo, params[:id], :read)
```

You could define something analogous for updating and creating records,

```ruby
def authorize_and_create(model_class, params)
  record = model_class.new(params)
  authorize! :create, record
  [record.save, record]
end
```

And in your actions use,

```ruby
success, foo = authorize_and_create(Foo, create_params)

if success
  # ...
else
  # ...
end
```

## Example

```ruby
# config/application.rb
# ...
  config.autoload_paths += %W(#{config.root}/authorization)
# ...

# app/controllers/application_controller.rb
require 'kant/controller_mixin'

class ApplicationController < ActionController::Base
  include Kant::ControllerMixin
end

# app/authorization/access_control.rb
require 'kant/policy_access'

class AccessControl < Kant::PolicyAccess
  def policies_module
    ::Policies
  end
end

# app/authorization/policies/foo_policy.rb
module Policies
  module FooPolicy
    def readable(foos, user)
      foos.where(user_id: user.id)
    end
  end
end

# app/controllers/foos_controller.rb
class FoosController < ApplicationController
  def index
    foos = accessible(:read, Foo)
    render json: foos
  end

  def show
    foo = Foo.find(params[:id])
    authorize! :read, foo
    render json: foo
  end
end
```


## Contributing

1. Fork it ( https://github.com/markprzepiora/kant/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
