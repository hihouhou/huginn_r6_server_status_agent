require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::R6ServerStatusAgent do
  before(:each) do
    @valid_options = Agents::R6ServerStatusAgent.new.default_options
    @checker = Agents::R6ServerStatusAgent.new(:name => "R6ServerStatusAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
