require 'spec_helper'

describe Kant do
  setup_models

  it "something something" do
    User.create!(email: 'foo@bar.com')
  end
end
