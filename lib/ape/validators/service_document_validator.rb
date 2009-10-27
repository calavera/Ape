module Ape
  class ServiceDocumentValidator < Validator
    disabled
    deterministic
    attr_reader :service_document, :entry_collections, :media_collections
    
    def validate(opts = {})
      init_service_document(opts[:uri])
      init_service_collections(opts[:uri]) if @service_document
    end
    
    def init_service_document(uri)
      reporter.info(self, "TESTING: Service document and collections.")
      
      begin
        @service_document = Service.new(:uri => uri, :reporter => reporter )
      rescue Exception
        prob = $!.to_s.gsub(/\n/, '<br/>')
        reporter.error(self, "Service document not usable: #{prob}")
        return
      end

      # RNC-validate the service doc
      Validator.instance(:schema, @reporter).validate(:schema => Samples.service_RNC, 
        :title => 'Service doc', :doc => @service_document.service)
    end
    
    def init_service_collections(uri)
      # * Do we have collections we can post an entry and a picture to?
      #   the requested_* arguments are the requested collection titles; if
      #    provided, try to match them, otherwise just pick the first listed
      #
      collections = @service_document.collections
      if collections.length > 0

        reporter.start_list(self, "Found these collections")
        collections.each do |collection|
          reporter.list_item("'#{collection.title}' " +
              "accepts #{collection.accept.join(', ')}")
            
          if collection.accept?(Names::AtomEntryMediaType)
            @entry_collections ||= []
            @entry_collections << collection
          end
            
          if collection.accept?('image/jpeg')
            @media_collections ||= []
            @media_collections << collection
          end
        end
      end
    end
  end
end
