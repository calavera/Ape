#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   See the included LICENSE[link:/files/LICENSE.html] file for details.
$:.unshift File.dirname(__FILE__)
module Ape
  require 'rubygems'
  
  Dir[File.dirname(__FILE__) + '/ape/*.rb'].sort.each { |l| require l }
  
  @CONF = {}

  def Ape.conf
    @CONF
  end
  
  def Ape.home=(home)
    @CONF[:HOME] = home
  end

  def Ape.home
    @CONF[:HOME] || ENV["APE_HOME"] || File.join(home_directory,".ape")
  end

  def Ape.home_directory
    ENV["HOME"] || (ENV["HOMEPATH"] && "#{ENV["HOMEDRIVE"]}#{ENV["HOMEPATH"]}") || "/"
  end
  
  class Ape
    # Creates an Ape instance with options given in the +args+ Hash.
    #
    # ==== Options
    #   * :output - one of 'text' or 'html' or 'atom'. #report will output in this format. Defaults to 'html'.
    #   * :debug  - enables debug information at each step in the output
    def initialize(args = {})
      output = args[:output] || 'html'
      @reporter = Reporter.instance(output, args)
      load File.join(::Ape.home, 'aperc') if File.exist?(File.join(::Ape.home, 'aperc'))
    end

    # Checks the AtomPub server at +uri+ for sanity.
    #
    # ==== Options
    #   * uri - the URI of the AtomPub server. Required.
    #   * username - an optional username for authentication
    #   * password - if a username is provided, a password is required. See Ape::Authent for more information.
    #   * service_doc - an optional service document. It'll be used instead of getting it from the uri.
    #   * requested_e_coll - a preferred entry collection to check
    #   * requested_m_coll - a preferred media collection to check 
    def check(uri, username=nil, password=nil, service_doc = nil,
        requested_e_coll = nil, requested_m_coll = nil)
      
      @authent = Authent.new(username, password)
      @reporter.header = uri
      ::Ape.conf[:REQUESTED_ENTRY_COLLECTION] = requested_e_coll if requested_e_coll
      ::Ape.conf[:REQUESTED_MEDIA_COLLECTION] = requested_m_coll if requested_m_coll
      begin
        might_fail(uri, service_doc)
      rescue Exception
        @reporter.error(self, "Ouch! Ape fall down go boom; details: " +
          "#{$!}\n#{$!.class}\n#{$!.backtrace}")
      end
    end

    def might_fail(uri, service = nil)
      unless (service)
        service_validator = Validator.instance(:service_document, @reporter, @authent)
        service_validator.validate(:uri => uri)
        @service = service_validator.service_document
      else
        @service = service.instance_of?(String)?
          REXML::Document.new(service, { :raw => nil }) : service
      end
      @entry_collections = service_validator.entry_collections
      @media_collections = service_validator.media_collections
      
      unless true == ::Ape.conf[:ENTRY_VALIDATION_DISABLED]
        if @entry_collections
          [:entry_posts, :sorting, :sanitization].each do |option|
            check_validator(option)
          end
        else
          @reporter.warning(self, "No collection for 'application/atom+xml;type=entry', won't test entry posting.")
        end
      end

      unless true == ::Ape.conf[:MEDIA_VALIDATION_DISABLED]
        if @media_collections
          [:media_posts, :media_linkage].each do |option|
            check_validator(option)
          end
        else
          @reporter.warning(self, "No collection for 'image/jpeg', won't test media posting.")
        end
      end
      
      #custom validators
      Validator.custom_validators(@reporter, @authent).each do |validator|
        opts = check_manifest(validator)
        break if !validator.validate(opts) && validator.deterministic?
      end
    end

    def error_count
      @reporter.errors.size
    end
    def warning_count
      @reporter.warnings.size
    end
    
    def report(output=STDOUT)
      @reporter.report(output)
    end

    def check_manifest(validator)
      variables = {}
      manifest = validator.manifest
      variables[:service_doc] = @service if (manifest.include?(:service_doc))      
      
      if (manifest.include?(:entry_collection))
        variables[:entry_collection] = ::Ape.conf[:REQUESTED_ENTRY_COLLECTION].nil? ? @entry_collections.first :
          get_collection(@entry_collections, ::Ape.conf[:REQUESTED_ENTRY_COLLECTION])        
      end
      
      if (manifest.include?(:media_collection))
        variables[:media_collection] = ::Ape.conf[:REQUESTED_MEDIA_COLLECTION].nil? ? @media_collections.first :
          get_collection(@media_collections, ::Ape.conf[:REQUESTED_MEDIA_COLLECTION])        
      end
      
      manifest.each do |option|        
        if (option.instance_of?(Hash) && !variables.include?(option))
          all_collections = @entry_collections + @media_collections
          option.each do |key, value|
            unless (value.instance_of?(Hash))
              #request a collection by its title, i.e: :entry_collection => 'Posts'
              variables[key] = get_collection(all_collections, value)
            else
              #request the first collection that matches the options,
              # i.e:  :entry_collection => {:accept => 'image/png'}
              #       :entry_collection => {:title => 'Atachments', :accept => 'video/*'}
              hash = value
              variables[key] = all_collections.select do |collection|
                matches = nil
                hash.each do |k, v|
                  begin
                    matches = eval("collection.#{k.to_s}", binding, __FILE__, __LINE__).index(v)
                  rescue
                    raise ValidationError, "collection attribute not found: #{k.to_s}"
                  end
                end
                collection if matches
              end.first
            end
          end
        end
      end
      
      #ensure all variables are setted
      raise ValidationError, "#{manifest.join("\n")} haven't been setted" if variables.empty?
      variables.each do |k, v|
        raise ValidationError, "#{k} haven't been setted" unless v
      end
      
      variables
    end
    
private

    def check_validator(option)
      validator = Validator.instance(option, @reporter, @authent)
      opts = check_manifest(validator)
      validator.validate(opts)
    end
    
    def get_collection(collections, requested)
      if (requested.instance_of?(Integer))
        return collections[requested]
      elsif (requested.to_sym == :first)
        return collections.first
      elsif (requested.to_sym == :last)
        return collections.last
      end
      collections.select do |coll|
        coll if (coll.title == requested)
      end.first
    end
  end
end
