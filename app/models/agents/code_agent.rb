require 'date'
require 'cgi'
module Agents
  class CodeAgent < Agent
    #cannot_receive_events!
    #cannot_be_scheduled!
    description <<-MD
      Here is an agent that gives you the ability to specify your own code. We have already provided you
      a javascript object that has read access to this agent's memory, events, options and the attributes of the agent.
      We also provide you with a method to create events on the server.
      You will be provided with an instance of the Agent object in javascript, with access to the above data.
      You can create events based on your own logic.
      Specifically, you have the following class, lets say, present is a string "js_code".

          function Agent(m, e, o, agent){
          this.memory = JSON.parse(m);
          this.events = JSON.parse(e);
          this.options = JSON.parse(o);
          this.agent = JSON.parse(agent);
          }
          Agent.prototype.run = function(){
            //Implement me
            // Example create a new event with the following code:
            //var new_event = JSON.stringify({key1: "val1", key2: "val2"});
            //create_event(pd);
          }
      You need to provide the code for the Agent::run function. You code will override any methods already present in the Agent if it has to, and you can use other methods as well with access to the agent properties. You need to at least provide the implementation of Agent.prototype.run so that it can be called periodically, or it can execute when an event happens.

      We will yield control to your implementation in the following way:

          context.eval(js_code); //this is the code that declares the class Agent, and provides a global create_event method.
          context.eval("a = new Agent(memory, events, options, agent)")
          context.eval(options['code'])
          context.eval("a.run();")

      You need to provide the run() implementation, as well as other methods it may need to interact with.

    MD
    def example_js
    <<-H
    function Agent(m, e, o, agent){
    this.memory = JSON.parse(m);
    this.events = JSON.parse(e);
    this.options = JSON.parse(o);
    this.agent = JSON.parse(agent);
    }
    Agent.prototype.print_memory = function(){
      return JSON.stringify(this.memory);
    }
    Agent.prototype.memry = function(key,value){
      if (typeof(key) != "undefined" && typeof(value) != "undefined") {
        this.memory = JSON.parse(access_memory(JSON.stringify(key), JSON.stringify(value)));
        return JSON.stringify(this.memory);
      } else {
        this.memory = JSON.parse(access_memory());
        return JSON.stringify(this.memory);
      }
    }
    Agent.prototype.run = function(){
    }
    H
    end

    def working?
      return false if recent_error_logs?
      if options['expected_update_period_in_days'].present?
        return false unless event_created_within?(options['expected_update_period_in_days'])
      end
      if options['expected_receive_period_in_days'].present?
        return false unless last_receive_at && last_receive_at > options['expected_receive_period_in_days'].to_i.days.ago
      end
      true
    end
    def setter_and_getter_memory(incoming_events = "")
      context = V8::Context.new
      context.eval(example_js)
      context["create_event"] = lambda {|x,y| puts x; puts y; create_event payload: JSON.parse(y)}
      context["access_memory"] = lambda {|a, x, y| x && y ? (memory[x] = y; memory.to_json) : memory.to_json }

      context.eval(options['code']) # should override the run function.
      a, m, e, o = [self.attributes.to_json, self.memory.to_json, incoming_events.to_json, self.options.to_json]
      string = "a = new Agent('#{m}','#{e}','#{o}','#{a}');"
      context.eval(string)
      context.eval("a.memry()")    
    end
    def execute_js(incoming_events)
      context = V8::Context.new
      context.eval(example_js)
      context["create_event"] = lambda {|x,y| puts x; puts y; create_event payload: JSON.parse(y)}

      context.eval(options['code']) # should override the run function.
      a, m, e, o = [self.attributes.to_json, self.memory.to_json, incoming_events.to_json, self.options.to_json]
      string = "a = new Agent('#{m}','#{e}','#{o}','#{a}');"
      context.eval(string)
      context.eval("a.run();")
    end
    def check
      execute_js("")
    end

    def receive(incoming_events)
      execute_js(incoming_events)
    end

    def default_options
      js_code = "Agent.prototype.run = function(){ var pd = JSON.stringify({memory: this.memory, events: this.events, options: this.options});create_event(pd); }"
      {
        "code" => js_code,
        'expected_receive_period_in_days' => "2"
      }
    end
  end
end
