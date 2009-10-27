module Ape
  class MediaLinkageValidator < Validator
    disabled
    requires_presence_of :media_collection
    
    def validate(opts = {})
      reporter.info(self, "TESTING: Media collection re-ordering after PUT.")
      coll = opts[:media_collection]
      
      # We'll post three mini entries to the collection
      data = Samples.picture
      poster = Poster.new(coll.href, @authent)
      ['One', 'Two', 'Three'].each do |num|
        slug = "Picture #{num}"
        poster.set_header('Slug', slug)
        name = "Posting pic #{num}"
        worked = poster.post('image/jpeg', data)
        reporter.save_dialog(name, poster)
        if !worked
          reporter.error(self, "Can't POST Picture #{num}: #{poster.last_error}", name)
          return
        end
        sleep 2
      end
      
      # grab the collection to gather the MLE ids
      entries = Feed.read(coll.href, 'Pictures from multi-post', reporter)
      if entries.size < 3 
        reporter.error(self, "Pictures apparently not in collection")
        return
      end
        
      ids = entries.map { |e| e.child_content('id') }
      
      # let's update one of them; have to fetch it first to get the ETag
      two_media = entries[1].link('edit-media')
      if !two_media
        reporter.error(self, "Second entry from feed doesn't have an 'edit-media' link.")
        return
      end
      two_resp = check_resource(two_media, 'Fetch image to get ETag', 'image/jpeg')
      unless two_resp
        reporter.error(self, "Can't fetch image to get ETag")
        return
      end
      etag = two_resp.header 'etag'
          
      putter = Putter.new(two_media, @authent)
      putter.set_header('If-Match', etag)
      
      name = 'Updating one of three pix with PUT'
      if putter.put('image/jpeg', data)
        reporter.success(self, "Update one of newly posted pictures went OK.")
      else  
        reporter.save_dialog(name, putter)
        reporter.error(self, "Can't update picture at #{two_media}", name)
        return
      end
      
      # now the order should have changed
      wanted = [ ids[2], ids[0], ids[1] ]
      entries = Feed.read(coll.href, 'MLEs post-update', reporter)
      entries.each do |from_feed|
        want = wanted.pop
        unless from_feed.child_content('id').eql?(want)
          reporter.error(self, "Updating bits failed to re-order link entries in media collection.")
          return
        end
        
        # next to godliness
        delete_entry(from_feed)
        
        break if wanted.empty?
      end
      reporter.success(self, "Entries correctly ordered after update of multi-post.")
    end
  end
end
