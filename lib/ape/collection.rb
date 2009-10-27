#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

# Represents an AtomPub collection, which offers feed-reading and resource-CRUD
#  services
require 'rexml/xpath'

module Ape
  class Collection 

    # The argument has to be an absolute URI
    #
    def initialize(uri, authent = nil)
      @uri = uri      
      @authent = authent
    end

    # Post a new element to this collection; return either an Ape::Entry or
    #  an error-message
    #
    # ==== Options
    #   * :data - element to post as a string
    #   * :type - content type. By default 'application/atom+xml;type=entry'
    #   * :slug - slug header
    #
    def post(opts = {})
      return ':data argument not provided' unless opts[:data]
      
      type = opts[:type] || Names::AtomEntryMediaType
      @invoker = Poster.new(@uri, @authent)
      @invoker['Slug'] = opts[:slug] if opts[:slug]
      
      if @invoker.post(type, opts[:data]) 
        @invoker.entry 
      else
        @invoker.last_error    
      end
    end
    
    def crumbs
      return @invoker.crumbs
    end
  end
end
