require 'spec_helper'
require 'kant/no_access'

describe Kant::NoAccess do
  let(:user) { double("user") }
  subject(:no_access) { Kant::NoAccess.new(user) }

  it "it can't do anything" do
    foo = double("foo")

    expect(no_access).not_to be_able_to(:bar, foo)
  end

  it "it has access to nothing" do
    scope = double("scope")
    none = double("none")
    expect(scope).to receive(:none).and_return(none)

    expect(no_access.accessible(:foo, scope)).to eq(none)
  end

  it "has a #user method" do
    expect(no_access.user).to eq(user)
  end
end
