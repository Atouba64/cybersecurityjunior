# Jekyll with Chirpy Theme - Setup Guide

## Current Status

✅ Jekyll configuration files created
✅ Chirpy theme structure integrated
✅ Blog posts converted to Jekyll format
✅ Directory structure set up
⚠️ **Ruby version upgrade required** (System: 2.6.10, Required: 3.1+)

## Ruby Version Requirement

The Chirpy theme requires **Ruby 3.1 or higher**. Your current system has Ruby 2.6.10.

### Option 1: Install Ruby 3.1+ using Homebrew (Recommended)

```bash
# Install rbenv (Ruby version manager)
brew install rbenv ruby-build

# Add rbenv to your shell
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

# Install Ruby 3.2 (or latest stable)
rbenv install 3.2.0
rbenv global 3.2.0

# Verify installation
ruby --version  # Should show 3.2.0 or higher
```

### Option 2: Use Homebrew directly

```bash
brew install ruby@3.2
# Follow the instructions to update PATH
```

## After Ruby Upgrade

1. **Install Bundler** (if not already installed):
```bash
gem install bundler
```

2. **Install Jekyll dependencies**:
```bash
cd /Users/mabele/Documents/Projects/GitHub/cybersecurityjunior
bundle install
```

3. **Test Jekyll locally**:
```bash
bundle exec jekyll serve
# Open http://localhost:4000 in your browser
```

4. **Build the site**:
```bash
bundle exec jekyll build
```

## What's Been Done

### Files Created/Modified:

1. **`_config.yml`** - Jekyll configuration with Chirpy theme settings
2. **`Gemfile`** - Ruby dependencies (Chirpy theme)
3. **`_posts/`** - Converted blog posts:
   - `2025-10-27-setting-up-my-first-home-lab.md`
   - `2025-10-25-my-transition-from-it-to-cybersecurity.md`
   - `2025-11-01-building-an-automated-aws-compliance-tool.md`
   - `2025-11-14-how-i-passed-the-devsecops-interview.md`
4. **`_tabs/`** - Navigation tabs (about, archives, categories, tags)
5. **`_data/`** - Theme data files
6. **`_plugins/`** - Jekyll plugins
7. **`index.html`** - Homepage (now uses Jekyll layout)

### Files Preserved:

- All your existing HTML files are still in place
- `pages/` directory with your original blog posts
- `assets/` directory with your images and JS files
- Contact, About, FAQ, and other pages

## Next Steps

1. **Upgrade Ruby** (see above)
2. **Convert remaining blog posts**: There are 4 more HTML posts to convert:
   - `imposter-syndrome.html`
   - `networking-basics.html`
   - `security-plus-exam.html`
   - `wireshark-analysis.html`
3. **Customize theme**: Edit `_config.yml` to match your preferences
4. **Test locally**: Run `bundle exec jekyll serve` and preview
5. **Deploy**: Set up GitHub Pages deployment

## Converting Remaining Posts

To convert the remaining HTML blog posts to Jekyll format:

1. Extract the content from each HTML file
2. Convert HTML to Markdown
3. Add front matter with date, title, categories, tags
4. Save to `_posts/` with format: `YYYY-MM-DD-slugified-title.md`

## GitHub Pages Deployment

Once Ruby is upgraded and Jekyll is working:

1. Update `url` in `_config.yml` to your GitHub Pages URL
2. Set up GitHub Actions workflow (Chirpy theme includes this)
3. Push to your repository
4. GitHub will automatically build and deploy

## Need Help?

- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [Chirpy Theme Documentation](https://github.com/cotes2020/jekyll-theme-chirpy)
- [Ruby Version Managers](https://www.ruby-lang.org/en/documentation/installation/)

