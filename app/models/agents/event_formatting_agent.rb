module Agents
  class EventFormattingAgent < Agent
    cannot_be_scheduled!

    description <<-MD
      An Event Formatting Agent allows you to format incoming Events, adding new fields as needed.

      For example, here is a possible Event:

          {
            "high": {
              "celsius": "18",
              "fahreinheit": "64"
            },
            "conditions": "Rain showers",
            "data": "This is some data"
          }

      You may want to send this event to another Agent, for example a Twilio Agent, which expects a `message` key.
      You can use an Event Formatting Agent's `instructions` setting to do this in the following way:

          "instructions": {
            "message": "Today's conditions look like <$.conditions> with a high temperature of <$.high.celsius> degrees Celsius.",
            "subject": "$.data"
          }

      JSONPaths must be between < and > . Make sure that you don't use these symbols anywhere else.

      Events generated by this possible Event Formatting Agent will look like:

          {
            "message": "Today's conditions look like Rain showers with a high temperature of 18 degrees Celsius.",
            "subject": "This is some data"
          }

      If you want to retain original contents of events and only add new keys, then set `mode` to `merge`, otherwise set it to `clean`.

      By default, the output event will have `agent` and `created_at` fields added as well, reflecting the original Agent type and Event creation time.  You can skip these outputs by setting `skip_agent` and `skip_created_at` to `true`.

      To CGI escape output (for example when creating a link), prefix with `escape`, like so:

          {
            "message": "A peak was on Twitter in <$.group_by>.  Search: https://twitter.com/search?q=<escape $.group_by>"
          }
    MD

    event_description "User defined"

    def validate_options
      errors.add(:base, "instructions, mode, skip_agent, and skip_created_at all need to be present.") unless options['instructions'].present? and options['mode'].present? and options['skip_agent'].present? and options['skip_created_at'].present?
    end

    def default_options
      {
        'instructions' => {
          'message' =>  "You received a text <$.text> from <$.fields.from>",
          'some_other_field' => "Looks like the weather is going to be <$.fields.weather>"
        },
        'mode' => "clean",
        'skip_agent' => "false",
        'skip_created_at' => "false"
      }
    end

    def working?
      !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        formatted_event = options['mode'].to_s == "merge" ? event.payload : {}
        options['instructions'].each_pair {|key, value| formatted_event[key] = Utils.interpolate_jsonpaths(value, event.payload) }
        formatted_event['agent'] = Agent.find(event.agent_id).type.slice!(8..-1) unless options['skip_agent'].to_s == "true"
        formatted_event['created_at'] = event.created_at unless options['skip_created_at'].to_s == "true"
        create_event :payload => formatted_event
      end
    end
  end
end