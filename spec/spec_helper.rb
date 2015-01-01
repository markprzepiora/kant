require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'sqlite3'
require 'with_model'
require 'kant'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

RSpec.configure do |config|
  config.extend WithModel
end
