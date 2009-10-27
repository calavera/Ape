module Ape
  require 'rexml/document'
  class ValidationError < StandardError ; end
  
  class Validator
    require File.dirname(__FILE__) + '/validator_dsl.rb'
    include Ape::ValidatorDsl
    include Ape::Util
    
    attr_accessor :reporter, :authent
    
    def self.custom_validators(reporter, authent)
      validators = []
      Dir[::Ape.home + '/validators/*.rb'].each do |v|
        require v
        class_name = v.gsub(/(.+\/validators\/)(.+)(.rb)/, '\2').gsub(/(^|_)(.)/) { $2.upcase }
        validator = eval("#{class_name}.new", binding, __FILE__, __LINE__)
        if validator.enabled?
          validator.reporter = reporter
          validator.authent = authent
          validators << validator
        end
      end
      validators
    end
    
    def self.instance(key, reporter, authent = nil)
      validator = resolve_plugin(key, 'validators', 'validator')
      raise ValidationError, "Unknown validator #{key}" unless validator
      validator.reporter = reporter
      validator.authent = authent
      validator
    end
    
=begin
    Each validator implements its own bussiness logic. This method is executed by the main script
  in order to assure that some aspect of atomPub implementation is correct
=end
    def validate(opts = {})
      raise ValidationError, "superclass doesn't implement this method"
    end
    
protected
    # Fetch a feed and look up an entry by ID in it
    def find_entry(feed_uri, name, id, report=false)
      entries = Feed.read(feed_uri, name, reporter, report)
      entries.each do |from_feed|
        return from_feed if id == from_feed.child_content('id')
      end

      return "Couldn't find id #{id} in feed #{feed_uri}"
    end
    
    def delete_entry(entry, name = nil)
      link = entry.link('edit', self)
      unless link
        reporter.error(self, "Can't delete entry without edit link")
        return false
      end
      deleter = Deleter.new(link, @authent)
      worked = deleter.delete
      
      reporter.save_dialog(name, deleter) if name
      if worked
        reporter.success(self, "Entry deletion reported success.", name)
      else
        reporter.error(self, "Couldn't delete the entry: " + deleter.last_error, name)
      end
      return worked
    end
    
    def method_missing(name, *args)
      if (name == :enabled?)
        new_method = self.class.send(:define_method, 'enabled?') do
          return true
        end
      elsif (name == :deterministic?)
        new_method = self.class.send(:define_method, 'deterministic?') do
          return false
        end
      elsif (name == :manifest)
        new_method = self.class.send(:define_method, 'manifest') do
          return []
        end
      else
        super
      end
      new_method.call(args) if new_method
    end
    
  end
  Dir[File.dirname(__FILE__) + '/validators/*.rb'].each { |l| require l }
end
