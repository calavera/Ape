module Ape
  class MediaPostsValidator < Validator
    disabled
    requires_presence_of :media_collection
    
    def validate(opts = {})
      reporter.info(self, "TESTING: Posting to media collection.")
      media_collection = opts[:media_collection]
      reporter.info(self, "Will use collection '#{media_collection.title}' for media creation.")
      
      # * Post a picture to the media collection
      #
      poster = Poster.new(media_collection.href, @authent)
      if poster.last_error
        reporter.error(self, "Unacceptable URI for '#{media_coll.title}' collection: " +
            poster.last_error)
        return
      end

      name = 'Post image to media collection'

      # ask it to use this in the URI
      slug_num = rand(100000)
      slug = "apix-#{slug_num}"
      slug_re = %r{apix.?#{slug_num}}
      poster.set_header('Slug', slug)

      worked = poster.post('image/jpeg', Samples.picture)
      reporter.save_dialog(name, poster)
      if !worked
        reporter.error(self, "Can't POST picture to media collection: #{poster.last_error}",
          name)
        return
      end

      reporter.success(self, "Post of image file reported success, media link location: " +
          "#{poster.header('Location')}", name)
      
      # * Retrieve the media link entry
      mle_uri = poster.header('Location')
          
      media_link_entry = check_resource(mle_uri, 'Retrieval of media link entry', Names::AtomMediaType)
      return unless media_link_entry

      if media_link_entry.last_error
        reporter.error(self, "Can't proceed with media-post testing.")
        return
      end

      # * See if the <content src= is there and usable
      begin
        media_link_entry = Entry.new(:text => media_link_entry.body, :uri => mle_uri)
      rescue REXML::ParseException
        prob = $!.to_s.gsub(/\n/, '<br/>')
        reporter.error(self, "Media link entry is not well-formed: #{prob}")
        return
      end
      content_src = media_link_entry.content_src
      if (!content_src) || (content_src == "")
        reporter.error(self, "Media link entry has no content@src pointer to media resource.")
        return
      end

      # see if slug was used in media URI
      if content_src =~ slug_re
        reporter.success(self, "Client-provided slug '#{slug}' was used in Media Resource URI.")
      else
        reporter.warning(self, "Client-provided slug '#{slug}' not used in Media Resource URI.")
      end
      
      media_link_id = media_link_entry.child_content('id')

      name = 'Retrieval of media resource'
      picture = check_resource(content_src, name, 'image/jpeg')
      return unless picture

      if picture.body == Samples.picture
        reporter.success(self, "Media resource was apparently stored and retrieved properly.")
      else
        reporter.warning(self, "Media resource differs from posted picture")
      end

      # * Delete the media link entry
      return unless delete_entry(media_link_entry, 'Deletion of media link entry')

      # * media link entry still in feed?
      still_there = find_entry(media_collection.href, "media collection", media_link_id)
      if still_there.class != String
        reporter.error(self, "Media link entry is still in collection post-deletion.")
      else
        reporter.success(self, "Media link entry no longer in feed.")
      end
      
      # is the resource there any more?
      name = 'Check Media Resource deletion'
      if check_resource(content_src, name, 'image/jpeg', false)
        reporter.error(self, "Media resource still there after media link entry deletion.")
      else
        reporter.success(self, "Media resource no longer fetchable.")
      end
    end
  end
end