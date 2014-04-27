module LiquidMigrator
  def self.convert_all_agent_options(agent)
    agent.options = self.convert_hash(agent.options, {:merge_path_attributes => true, :leading_dollarsign_is_jsonpath => true})
    agent.save!
  end

  def self.convert_hash(hash, options={})
    options = {:merge_path_attributes => false, :leading_dollarsign_is_jsonpath => false}.merge options
    keys_to_remove = []
    hash.tap do |hash|
      hash.each_pair do |key, value|
        case value.class.to_s
        when 'String', 'FalseClass', 'TrueClass'
          path_key = "#{key}_path"
          if options[:merge_path_attributes] && !hash[path_key].nil?
            # replace the value if the path is present
            value = hash[path_key] if hash[path_key].present?
            # in any case delete the path attibute
            keys_to_remove << path_key
          end
          hash[key] = LiquidMigrator.convert_string value, options[:leading_dollarsign_is_jsonpath]
        when 'Hash'
          # might want to make it recursive?
        when 'Array'
          # do we need it?
        end
      end
        # remove the unneeded *_path attributes
    end.select { |k, v| !keys_to_remove.include? k }
  end

  def self.convert_string(string, leading_dollarsign_is_jsonpath=false)
    if string == true || string == false
      # there might be empty *_path attributes for boolean defaults
      string
    elsif string[0] == '$' && leading_dollarsign_is_jsonpath
      # in most cases a *_path attribute
      convert_json_path string
    else
      # migrate the old interpolation syntax to the new liquid based
      string.gsub(/<([^>]+)>/).each do
        match = $1
        if match =~ /\Aescape /
          # convert the old escape syntax to a liquid filter
          self.convert_json_path(match.gsub(/\Aescape /, '').strip, ' | uri_escape')
        else
          self.convert_json_path(match.strip)
        end
      end
    end
  end

  def self.convert_json_path(string, filter = "")
    "{{#{string[2..-1].gsub(/\.\*\Z/, '')}#{filter}}}"
  end
end

