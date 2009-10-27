#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"
require 'rexml/xpath'

module Ape
  class Service
    require File.dirname(__FILE__) + '/util.rb'
    include Ape::Util::InstanceMethods
    
    attr_accessor :service, :reporter
    
    def initialize(opts = {})                 #uri = nil, authent = nil)
      @authent = opts[:authent]
      @reporter = opts[:reporter]
      if opts[:uri]
        @uri = opts[:uri]
        resource = check_resource(@uri, 'Service document', Names::AppMediaType, @reporter)
        raise StandardError, "Service document not found at: #{@uri}" unless resource
    
        @service = REXML::Document.new(resource.body, { :raw => nil })
      end
    end

    def collections(uri = @uri)
      nodes = REXML::XPath.match(@service, '//app:collection', Names::XmlNamespaces)
      nodes.collect { |n| CollElement.new(n, uri) }
    end
  end
end
