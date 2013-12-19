require 'spec_helper'

describe Agents::WebhookAgent do
  let(:agent) do
    _agent = Agents::WebhookAgent.new(:name => 'webhook',
                             :options => {:secret => :foobar})
    _agent.user = users(:bob)
    _agent.save!
    _agent
  end

  after { agent.destroy }

  describe 'receive_webhook' do
    it 'should create event if secret matches' do
      out = nil
      lambda {
        out = agent.receive_webhook({:secret => :foobar, :payload => {:some => :info}})
      }.should change { Event.count }.by(1)
      out.should eq(['Event Created', 201])
    end

    it 'should not create event if secrets dont match' do
      out = nil
      lambda {
        out = agent.receive_webhook({:secret => :bazbat, :payload => {:some => :info}})
      }.should change { Event.count }.by(0)
      out.should eq(['Not Authorized', 401])
    end
  end
end
