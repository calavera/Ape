module Ape
  class SortingValidator < Validator
    disabled
    requires_presence_of :entry_collection
    
    def validate(opts = {})
      coll = opts[:entry_collection]
      reporter.info(self, "TESTING: Collection re-ordering after PUT.")
      
      # We'll post three mini entries to the collection
      poster = Poster.new(coll.href, @authent)
      ['One', 'Two', 'Three'].each do |num|
        sleep 2
        text = Samples.mini_entry.gsub('Mini-1', "Mini #{num}")
        name = "Posting Mini #{num}"
        worked = poster.post(Names::AtomEntryMediaType, text)
        reporter.save_dialog(name, poster)
        if !worked
          reporter.error(self, "Can't POST Mini #{name}: #{poster.last_error}", name)
          return
        end
      end

      # now let's grab the collection & check the order
      wanted = ['Mini One', 'Mini Two', 'Mini Three']
      two = nil
      entries = Feed.read(coll.href, 'Entries with multi-post', reporter)
      entries.each do |from_feed|
        want = wanted.pop
        unless from_feed.child_content('title').index(want)
          reporter.error(self, "Entries feed out of order after multi-post.")
          return
        end
        two = from_feed if want == 'Mini Two'
        break if wanted.empty?
      end
      reporter.success(self, "Entries correctly ordered after multi-post.")
      
      # let's update one of them; have to fetch it first to get the ETag
      link = two.link('edit', self)
      unless link
        reporter.error(self, "Can't check entry without edit link, entry id: #{two.get_child('id/text()')}")
        return
      end
      two_resp = check_resource(link, 'fetch two', Names::AtomMediaType, false)
      
      correctly_ordered = false
      if two_resp
        etag = two_resp.header 'etag'
          
        putter = Putter.new(link, @authent)
        putter.set_header('If-Match', etag)
      
        name = 'Updating mini-entry with PUT'
        sleep 2
        updated = two_resp.body.gsub('Mini Two', 'Mini-4')
        unless putter.put(Names::AtomEntryMediaType, updated)
          reporter.save_dialog(name, putter)
          reporter.error(self, "Can't update mini-entry at #{link}", name)
          return
        end
        # now the order should have changed
        wanted = ['Mini One', 'Mini Three', 'Mini-4']
        correctly_ordered = true
      else
        reporter.error(self, "Mini Two entry not received. Can't assure the correct order after update.")
        wanted = ['Mini One', 'Mini Two', 'Mini Three']
      end
      
      entries = Feed.read(coll.href, 'Entries post-update', reporter)
      entries.each do |from_feed|
        want = wanted.pop
        unless from_feed.child_content('title').index(want)
          reporter.error(self, "Entries feed out of order after update of multi-post.")
          return
        end
        
        # next to godliness
        delete_entry(from_feed)
        
        break if wanted.empty?
      end
      reporter.success(self, "Entries correctly ordered after update of multi-post.")  if correctly_ordered
      
    end
  end
end