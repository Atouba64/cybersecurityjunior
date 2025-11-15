#!/usr/bin/env ruby
#
# Sort posts by last_modified_at for Jekyll site.posts collection
# This ensures all posts are sorted by last modified date

Jekyll::Hooks.register :site, :post_read do |site|
  # Sort posts by last_modified_at, fallback to date
  site.posts.docs.sort! do |a, b|
    # Get last_modified_at or fallback to date
    a_date_str = a.data['last_modified_at'] || a.data['lastmod'] || a.data['date']
    b_date_str = b.data['last_modified_at'] || b.data['lastmod'] || b.data['date']
    
    # Parse dates
    begin
      a_time = a_date_str.is_a?(Time) ? a_date_str : Time.parse(a_date_str.to_s)
    rescue
      a_time = Time.at(0)
    end
    
    begin
      b_time = b_date_str.is_a?(Time) ? b_date_str : Time.parse(b_date_str.to_s)
    rescue
      b_time = Time.at(0)
    end
    
    # Sort descending (newest first)
    b_time <=> a_time
  end
end

