#!/usr/bin/env ruby
#
# Sort posts by last_modified_at for display
# This ensures posts appear sorted by last modified date on the homepage

module Jekyll
  module Filters
    def sort_posts_by_lastmod(posts)
      posts.sort do |a, b|
        # Get last_modified_at or fallback to date
        a_date = a.data['last_modified_at'] || a.data['lastmod'] || a.data['date']
        b_date = b.data['last_modified_at'] || b.data['lastmod'] || b.data['date']
        
        # Parse dates
        a_time = a_date.is_a?(Time) ? a_date : Time.parse(a_date.to_s)
        b_time = b_date.is_a?(Time) ? b_date : Time.parse(b_date.to_s)
        
        # Sort descending (newest first)
        b_time <=> a_time
      end
    end
  end
end

