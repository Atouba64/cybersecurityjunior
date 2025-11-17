#!/usr/bin/env ruby
#
# Check for changed posts and set last_modified_at

Jekyll::Hooks.register :posts, :post_init do |post|
  # Always try to get the last modified date from git
  # If file has been modified, use git log
  # Otherwise, use the post date
  begin
    # Check if git is available
    unless system('which git > /dev/null 2>&1')
      post.data['last_modified_at'] = post.data['date']
      post.data['lastmod'] = post.data['date']
      next
    end
    
    # Try to get git log, but don't fail if it doesn't work
    git_cmd = "git log -1 --pretty=\"%ad\" --date=iso \"#{ post.path }\" 2>/dev/null"
    lastmod_date = `#{git_cmd}`.strip
    
    if lastmod_date && !lastmod_date.empty? && !lastmod_date.include?('fatal:')
      # Parse and format the date properly
      post.data['last_modified_at'] = lastmod_date
    else
      # Fallback to post date if git log fails
      post.data['last_modified_at'] = post.data['date']
    end
    
    # Also set lastmod for compatibility
    post.data['lastmod'] = post.data['last_modified_at']
  rescue => e
    # If anything fails, use the post date
    post.data['last_modified_at'] = post.data['date']
    post.data['lastmod'] = post.data['date']
  end
end
