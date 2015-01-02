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
  for each of your model classes. This class uses a minimal amount of magic to
  work with `ActiveRecord` models out of the box, but you can extend it easily
  to use any other ORM.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kant'
```

And then execute:

    $ bundle

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/markprzepiora/kant/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
