#!/usr/bin/env ruby
#
# A hook to set last_modified_at for posts based on git commit date
# This helps with sorting and displaying when posts were last updated

Jekyll::Hooks.register :posts, :post_init do |post|
  if post.data['last_modified_at'].nil? && post.data['lastmod'].nil?
    # Try to get last modified date from git
    begin
      file_path = post.path
      if File.exist?(file_path)
        git_cmd = "git log -1 --format='%ci' -- '#{file_path}' 2>/dev/null"
        git_date = `#{git_cmd}`.strip
        if !git_date.empty?
          post.data['last_modified_at'] = Time.parse(git_date)
        end
      end
    rescue => e
      # If git command fails, just use the post date
      Jekyll.logger.debug "PostsLastmodHook", "Could not get git date for #{post.path}: #{e.message}"
    end
  end
end

