module LiquidInterpolatable
  extend ActiveSupport::Concern

  def interpolate_options(options, payload = {})
    case options
      when String
        interpolate_string(options, payload)
      when ActiveSupport::HashWithIndifferentAccess, Hash
        options.inject(ActiveSupport::HashWithIndifferentAccess.new) { |memo, (key, value)| memo[key] = interpolate_options(value, payload); memo }
      when Array
        options.map { |value| interpolate_options(value, payload) }
      else
        options
    end
  end

  def interpolated(payload = {})
    key = [options, payload]
    @interpolated_cache ||= {}
    @interpolated_cache[key] ||= interpolate_options(options, payload)
    @interpolated_cache[key]
  end

  def interpolate_string(string, payload)
    Liquid::Template.parse(string).render!(payload, registers: {agent: self})
  end

  require 'uri'
  # Percent encoding for URI conforming to RFC 3986.
  # Ref: http://tools.ietf.org/html/rfc3986#page-12
  module Filters
    def uri_escape(string)
      CGI::escape string
    end
  end
  Liquid::Template.register_filter(LiquidInterpolatable::Filters)

  module Tags
    class Credential < Liquid::Tag
      def initialize(tag_name, name, tokens)
        super
        @credential_name = name.strip
      end

      def render(context)
        credential = context.registers[:agent].credential(@credential_name)
        raise "No user credential named '#{@credential_name}' defined" if credential.nil?
        credential
      end
    end
  end
  Liquid::Template.register_tag('credential', LiquidInterpolatable::Tags::Credential)
end
