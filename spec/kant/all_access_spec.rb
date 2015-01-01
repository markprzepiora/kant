require 'spec_helper'
require 'kant/all_access'

describe Kant::AllAccess do
  let(:user) { double("user") }
  subject(:all_access) { Kant::AllAccess.new(user) }

  it "it can do anything" do
    foo = double("foo")

    expect(all_access).to be_able_to(:bar, foo)
  end

  it "it has access to everything" do
    scope = double("scope")
    expect(scope).to receive(:all).and_return(scope)

    expect(all_access.accessible(:foo, scope)).to eq(scope)
  end
end
