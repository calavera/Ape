#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

# Represents an <app:collection> element as found in an AtomPub Service Doc

module Ape
  class CollElement
    
    @@mime_re = %r{^(.*)/(.*)$}
    
    attr_reader :title, :accept, :href, :xml
    
    def CollElement::find_colls(source, doc_uri = nil)
      els = REXML::XPath.match(source, '//app:collection', Names::XmlNamespaces)
      els.map { |el| CollElement.new(el, doc_uri) }
    end
    
    def initialize(el, doc_uri = nil)
      @xml = el
      @accept = []
      @title = REXML::XPath.first(el, './atom:title', Names::XmlNamespaces)

      # sigh, RNC validation *should* take care of this
      raise(SyntaxError, "Collection is missing required 'atom:title'") unless @title
      @title = @title.texts.join

      if doc_uri
        uris = AtomURI.new(doc_uri)
        @href = uris.absolutize(el.attributes['href'], el)
      else
        @href = el.attributes['href']
      end

      # now we have to go looking for the accept
      @accept = REXML::XPath.match(@xml, './app:accept/(text)', Names::XmlNamespaces)
      @accept = [ Names::AtomEntryMediaType ] if @accept.empty?
    end

    # check if the collection accepts a given mime type; watch out for wildcards    
    def accept?(mime_type)
      if mime_type =~ @@mime_re
        p1, p2 = $1, $2
      else
        return false # WTF?
      end
      @accept.each do |pat|
        pat = pat.to_s # working around REXML ticket 164
        if pat =~ @@mime_re
          if ($1 == p1 || $1 == "*") && ($2 == p2 || $2 == "*")
            return true
          elsif ((pat == Names::AtomMediaType && mime_type == Names::AtomFeedMediaType) ||
                (pat == Names::AtomFeedMediaType && mime_type == Names::AtomMediaType))
            return true  
          end
        end
      end
      return false
    end
    
    # the name is supposed to suggest multiple instances of "categories"
    def catses
      REXML::XPath.match(@xml, './app:categories', Names::XmlNamespaces)
    end
    

  end 
end