#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

module Ape
  class AuthenticationError < StandardError ; end
  
  class Authent
    require File.dirname(__FILE__) + '/util.rb'
    include Ape::Util
    
    def initialize(username, password, scheme=nil)
      @username = username
      @password = password      
    end
    
    def add_to(req, authentication = nil)
      return unless @username && @password
      if (authentication)
        if authentication.strip.downcase.include? 'basic'
          req.basic_auth @username, @password
        else
          @auth_plugin ||= load_plugin(authentication)
          @auth_plugin.add_credentials(req, authentication, @username, @password)
        end
      else
        req.basic_auth @username, @password
      end
    end
    
    def load_plugin(authentication)
      plugin = Authent.resolve_plugin(authentication, 'auth', 'credentials', true)
      plugin || (raise AuthenticationError, "Unknown authentication method: #{authentication}")
    end
  end
  Dir[File.dirname(__FILE__) + '/auth/*.rb'].each { |l| require l }
end
