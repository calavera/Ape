module Ape
  class SanitizationValidator < Validator
    disabled
    requires_presence_of :entry_collection
    
    def validate(opts = {})
      reporter.info(self, "TESTING: Content sanitization")
      coll = opts[:entry_collection]
      
      poster = Poster.new(coll.href, @authent)
      name = 'Posting unclean XHTML'
      worked = poster.post(Names::AtomEntryMediaType, Samples.unclean_xhtml_entry)
      if !worked
        reporter.save_dialog(name, poster)
        reporter.error(self, "Can't POST unclean XHTML: #{poster.last_error}", name)
        return
      end
      
      location = poster.header('Location')
      name = "Retrieval of unclean XHTML entry"
      entry = check_resource(location, name, Names::AtomMediaType)
      return unless entry

      begin
        entry = Entry.new(:text => entry.body, :uri => location)
      rescue REXML::ParseException
        prob = $!.to_s.gsub(/\n/, '<br/>')
        reporter.error(self, "New entry is not well-formed: #{prob}")
        return
      end

      no_problem = true
      patterns = {
        '//xhtml:script' => "Published entry retains xhtml:script element.",
        '//*[@background]' => "Published entry retains 'background' attribute.",
        '//*[@style]' => "Published entry retains 'style' attribute.",
        
      }
      patterns.each { |xp, message| 
        reporter.warning(self, message) unless entry.xpath_match(xp).empty?
      }
      
      entry.xpath_match('//xhtml:a').each do |a|
        if a.attributes['href'] =~ /^([a-zA-Z]+):/
          if $1 != 'http'
            no_problem = false
            reporter.warning(self, "Published entry retains dangerous hyperlink: '#{a.attributes['href']}'.")
          end
        end
      end    

      delete_entry(entry)
      
      reporter.success(self, "Published entry appears to be sanitized.") if no_problem
    end
  end
end