require 'rubygems'
require 'mongrel'
require 'ape/handler'
require 'ape/samples'

module Ape
  
  # Manages and initializes the Mongrel handler. See run for more details.
  class Server
    
    # Starts the Mongrel handler with options given in +options+ and
    # maps the <b>/</b>, <b>/ape</b> and <b>/atompub/go</b> URIs to handlers.
    #
    # ==== Options
    #  * :host - the IP address to bind to
    #  * :port - the port number to listen on
    #  * :directory - the ape home directory
    def self.run(options)      
      ::Ape.home = options[:home]
      
      mongrel = Mongrel::Configurator.new(:host => options[:host], :port => options[:port]) do
        log "=> Booting mongrel"
        begin
          log "=> The ape starting on http://#{options[:host]}:#{options[:port]}"
          listener do
            redirect '/', '/web/index.html'
            uri '/web', :handler => 
              Mongrel::DirHandler.new(
                File.expand_path(File.dirname(__FILE__) + '/../../web'), true)
            uri '/atompub/go', :handler => Handler.new
          end
        rescue Errno::EADDRINUSE
          log "ERROR: Address (#{options[:host]}:#{options[:port]}) is already in use"
          exit 1
        end
        trap("INT") { stop }
        trap("TERM") { stop }
        log "=> Ctrl-C to shutdown"
        run
      end
      mongrel.join
    end
  end
end
