module Ape
  require 'erubis'
  class Reporter < Erubis::Context
    require File.dirname(__FILE__) + '/util.rb'
    include Ape::Util
    
    attr_accessor :header, :footer, :debug, :dialogs, :diarefs, :dianum, :server, :options

    def steps
      @steps ||= []
    end
    
    def self.instance(key, opts = {})
      reporter = resolve_plugin(key, 'reporters', 'reporter')
      raise StandardError, "Unknown reporter: #{key}, outputs supported: #{supported_outputs}" unless reporter
      reporter.debug = opts.delete(:debug) || false
      reporter.server = opts.delete(:server) || false
      reporter.options = opts
      reporter.dialogs = {}
      reporter.diarefs = {}
      reporter.dianum = 1
      reporter
    end
    
    def self.supported_outputs
      Dir[File.join(File.dirname(__FILE__), 'reporters/*.rb'),
          File.join(::Ape.home, 'reporters/*.rb')].map { |file|        
        file.gsub(/(.+\/reporters\/)(.+)(_reporter.rb)/, '\2').gsub(/_/, '')
      }.sort.join(", ").downcase
    end
=begin
  This method saves the messages that the validators send
  === Parameters
    * args[0] must be allways a reference to the validator.
    * args[1] should be the severity of the message, but it could be an array if several steps are recorded at once.
    * args[2] is the message to show.
    * args[3] is the message group key if it exits
=end
    def add(*args)
      if (args.length == 2 && args[1].kind_of?(Array))
        steps << args[1]
      elsif (args.length == 3)
        steps << {:severity => args[1], :message => args[2]}
      else
        steps << {:severity => :debug, :message => args[3]}
        show_crumbs(args[3]) if debug
        steps << {:severity => args[1], :message => args[2], :key => args[3]}        
      end
      puts "#{steps[-1][:severity].to_s.upcase}: #{steps[-1][:message]}" if debug && !steps[-1].kind_of?(Array)
    end
    
    def security_warning(validator)
      unless (@sec_warning_writed)
        warning(validator, "Sending authentication information over an open channel is not a good security practice.", name)
        @sec_warning_writed = true
      end
    end
    
    def warning(validator, message, crumb_key=nil)
      unless crumb_key
        add(validator, :warning, message)
      else
        add(validator, :warning, message, crumb_key)
      end
    end

    def error(validator, message, crumb_key=nil)
      unless crumb_key
        add(validator, :error, message)
      else
        add(validator, :error, message, crumb_key)
      end
    end

    def success(validator, message, crumb_key=nil)
      unless crumb_key
        add(validator, :success, message)
      else
        add(validator, :success, message, crumb_key)
      end
    end

    def info(validator, message)
      add(validator, :info, message)
    end
    
    def start_list(validator, message)
      add(validator, [ message + ":" ])
    end

    def list_item(message)
      steps[-1] << {:severity => :debug, :message => message}
    end
    
    def line(output=STDOUT)     
      printf(output, "%2d. ", @lnum ||= 1)
      @lnum += 1
    end
    
    def save_dialog(name, actor)
      dialogs[name] = actor.crumbs
    end
    
    def show_crumbs(key)     
      dialogs[key].each do |d|
        puts "Dialog: #{d}"
      end      
    end
    
    def show_message(crumb, tf)
      message = crumb[1 .. -1]
      message.gsub!(/^\s*"/, '')
      message.gsub!(/"\s*$/, '')
      message.gsub!(/\\"/, '"')
      message = Escaper.escape message
      message.gsub!(/(\\r\\n|\\n|\\r)/, "\n<br/>")      
      message.gsub!(/\\t/, '&#xa0;&#xa0;&#xa0;&#xa0;')
      "<div class=\"#{tf.to_s}\">#{message}</div>"      
    end
    
    def successes
      select(:success)
    end
    
    def infos
      select(:info)
    end
    
    def warnings
      select(:warning)
    end
    
    def errors
      select(:error)
    end
    
protected

    def select(option)
      steps.select { |step|
        unless step.kind_of?(Array)
          step.values.include?(option)
        else
          !step[1..-1].select {|dialog| dialog.values.include?(option)}.empty?
        end
      }
    end
    
    def evaluate_template(name)
      template = Erubis::FastEruby.new(IO.read(
        File.expand_path(File.join(File.dirname(__FILE__), name))))
      template.evaluate(self)
    end
    
  end
  Dir[File.dirname(__FILE__) + '/reporters/*.rb'].each { |l| require l }
end
