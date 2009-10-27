module Ape
  class EntryPostsValidator < Validator
    disabled
    requires_presence_of :entry_collection
    
    def validate(opts = {})
      entry_collection = opts[:entry_collection]
      reporter.info(self, "Will use collection '#{entry_collection.title}' for entry creation.")
      
      collection_uri = entry_collection.href
      entries = Feed.read(collection_uri, 'Entry collection', reporter)
      
      # * List the current entries, remember which IDs we've seen
      reporter.info(self, "TESTING: Entry-posting basics.")
      ids = []
      unless entries.empty?
        reporter.start_list(self, "Now in the Entries feed")
        entries.each do |entry|
          reporter.list_item(entry.summarize)
          ids << entry.child_content('id')
        end        
      end 
      
      # Setting up to post a new entry
      poster = Poster.new(collection_uri, @authent)
      if poster.last_error
        reporter.error(self, "Unacceptable URI for '#{entry_collection.title}' collection: " +
            poster.last_error)
        return
      end

      my_entry = Entry.new(:text => Samples.basic_entry)

      # ask it to use this in the URI
      slug_num = rand(100000)
      slug = "ape-#{slug_num}"
      slug_re = %r{ape.?#{slug_num}}
      poster.set_header('Slug', slug)

      # add some categories to the entry, and remember which
      @cats = Categories.add_cats(my_entry, entry_collection, @authent, reporter)

      # * OK, post it
      worked = poster.post(Names::AtomEntryMediaType, my_entry.to_s)
      name = 'Posting new entry'
      reporter.save_dialog(name, poster)
      if !worked
        reporter.error(self, "Can't POST new entry: #{poster.last_error}", name)
        return
      end

      location = poster.header('Location')
      unless location
        reporter.error(self, "No Location header upon POST creation", name)
        return
      end
      reporter.success(self, "Posting of new entry to the Entries collection " +
          "reported success, Location: #{location}", name)

      reporter.info(self, "Examining the new entry as returned in the POST response")
      check_new_entry(my_entry, poster.entry, "Returned entry") if poster.entry

      # * See if the Location uri can be retrieved, and check its consistency
      name = "Retrieval of newly created entry"
      new_entry = check_resource(location, name, Names::AtomMediaType)
      return unless new_entry

      # Grab its etag
      etag = new_entry.header 'etag'

      reporter.info(self, "Examining the new entry as retrieved using Location header in POST response:")

      begin
        new_entry = Entry.new(:text => new_entry.body, :uri => location)
      rescue REXML::ParseException
        prob = $!.to_s.gsub(/\n/, '<br/>')
        reporter.error(self, "New entry is not well-formed: #{prob}")
        return
      end

      # * See if the slug was used
      slug_used = false
      new_entry.alt_links.each do |a|
        href = a.attributes['href']
        if href && href.index(slug_re)
          slug_used = true
        end
      end
      if slug_used
        reporter.success(self, "Client-provided slug '#{slug}' was used in server-generated URI.")
      else
        reporter.warning(self, "Client-provided slug '#{slug}' not used in server-generated URI.")
      end

      check_new_entry(my_entry, new_entry, "Retrieved entry")

      entry_id = new_entry.child_content('id')

      # * fetch the feed again and check that version
      from_feed = find_entry(collection_uri, "entry collection", entry_id)
      if from_feed.class == String
        Feed.read(collection_uri, "Can't find entry in collection", reporter)
        reporter.error(self, "New entry didn't show up in the collections feed.")
        return
      end

      reporter.info(self, "Examining the new entry as it appears in the collection feed:")

      # * Check the entry from the feed
      check_new_entry(my_entry, from_feed, "Entry from collection feed")
     
      edit_uri = new_entry.link('edit', self)
      if !edit_uri
        reporter.error(self, "Entry from Location header has no edit link.")
        return
      end

      # * Update the entry, see if the update took
      name = 'In-place update with put'
      putter = Putter.new(edit_uri, @authent)

      # Conditional PUT if an etag
      putter.set_header('If-Match', etag) if etag

      new_title = "Let’s all do the Ape!"
      new_text = Samples.retitled_entry(new_title, entry_id)
      response = putter.put(Names::AtomEntryMediaType, new_text)
      reporter.save_dialog(name, putter)

      if response
        reporter.success(self, "Update of new entry reported success.", name)
        from_feed = find_entry(collection_uri, "entry collection", entry_id)
        if from_feed.class == String
          check_resource(collection_uri, "Check collection after lost update")
          reporter.error(self, "Updated entry ID #{entry_id} not found in entries collection.")
          return
        end
        if from_feed.child_content('title') == new_title
          reporter.success(self, "Title of new entry successfully updated.")
        else
          reporter.warning(self, "After PUT update of title, Expected " +
            "'#{new_title}', but saw '#{from_feed.child_content('title')}'")
        end
      else
        reporter.warning(self,"Can't update new entry with PUT: #{putter.last_error}", name)
      end

      # the edit-uri might have changed
      return unless delete_entry(from_feed, 'New Entry deletion')

      # See if it's gone from the feed
      still_there = find_entry(collection_uri, "entry collection", entry_id)
      if still_there.class != String
        reporter.error(self, "Entry is still in collection post-deletion.")
      else
        reporter.success(self, "Entry not found in feed after deletion.")
      end
      
    end
    
    def check_new_entry(as_posted, new_entry, desc)

      if compare_entries(as_posted, new_entry, "entry as posted", desc)
        reporter.success(self, "#{desc} is consistent with posted entry.")
      end

      # * See if the categories we sent made it in
      cat_probs = false
      @cats.each do |cat|
        if !new_entry.has_cat(cat)
          cat_probs = true
          reporter.warning(self, "Provided category not in #{desc}: #{cat}")
        end
      end
      reporter.success(self, "Provided categories included in #{desc}.") unless cat_probs

      # * See if the dc:subject survived
      dc_subject = new_entry.child_content(Samples.foreign_child, Samples.foreign_namespace)
      if dc_subject
        if dc_subject == Samples.foreign_child_content
          reporter.success(self, "Server preserved foreign markup in #{desc}.")
        else
          reporter.warning(self, "Server altered content of foreign markup in #{desc}.")
        end
      else
        reporter.warning(self, "Server discarded foreign markup in #{desc}.")
      end
    end

    def compare_entries(e1, e2, e1Name, e2Name)
      problems = 0
      [ 'title', 'summary', 'content' ].each do |field|
        problems += 1 if compare1(e1, e2, e1Name, e2Name, field)
      end
      return problems == 0
    end

    def compare1(e1, e2, e1Name, e2Name, field)
      c1 = e1.child_content(field)
      c2 = e2.child_content(field)
      if c1 != c2
        problem = true
        if c1 == nil
          reporter.warning(self, "'#{field}' absent in #{e1Name}.")
        elsif c2 == nil
          reporter.warning(self, "'#{field}' absent in #{e2Name}.")
        else
          t1 = e1.child_type(field)
          t2 = e2.child_type(field)
          if t1 != t2
            reporter.warning(self, "'#{field}' has type='#{t1}' " +
              "in #{e1Name}, type='#{t2}' in #{e2Name}.")
          else
            c1 = Escaper.escape(c1)
            c2 = Escaper.escape(c2)
            reporter.warning(self, "'#{field}' in #{e1Name} [#{c1}] " +
              "differs from that in #{e2Name} [#{c2}].")
          end
        end
      end
      return problem
    end
    
  end
end