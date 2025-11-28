# CybersecurityJunior

A Jekyll site using the Chirpy theme for cybersecurity content and blog posts.

## Version Management

This project uses **Bundler** to manage Ruby gem versions and ensure consistency between local development and production environments.

### Why Use Bundle Exec?

- **Version Consistency**: Ensures you're using the exact same Jekyll and plugin versions specified in `Gemfile.lock`
- **Hosting Compatibility**: Matches the versions used by GitHub Pages or other hosting providers
- **Team Collaboration**: All developers use the same gem versions

### Setup

1. **Install Bundler** (if not already installed):
   ```bash
   gem install bundler
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Run the development server**:
   ```bash
   # Using npm (recommended)
   npm run dev          # With live reload (auto-refresh on changes)
   npm run server       # Standard server
   npm run serve        # Alias for server
   
   # Or directly with bundle
   bundle exec jekyll serve --livereload  # With live reload
   bundle exec jekyll serve                # Standard server
   ```

4. **Build the site**:
   ```bash
   npm run build
   # or
   bundle exec jekyll build
   ```

### Important Notes

- **Always use `bundle exec`** when running Jekyll commands directly
- The `package.json` scripts already include `bundle exec` for convenience
- Gem versions are specified in `Gemfile` and locked in `Gemfile.lock`
- Never commit `Gemfile.lock` changes unless you've intentionally updated gem versions

### Updating Gems

To update gems while maintaining version constraints:

```bash
bundle update
```

To update a specific gem:

```bash
bundle update jekyll
```

## Development

The site uses:
- **Jekyll 4.4+** (specified in Gemfile)
- **Chirpy theme 7.4+**
- **Node.js 18+** (for Stackbit integration)

## Available NPM Scripts

- `npm run dev` - Start server with live reload (recommended for development)
- `npm run serve` / `npm run server` - Start standard Jekyll server
- `npm run build` - Build the site to `_site` directory
- `npm run clean` - Remove `_site` directory
- `npm run rebuild` - Clean and rebuild the site
- `npm run serve:network` - Start server accessible from other devices on your network

## Troubleshooting

If you experience differences between your local server and the live site, see **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for:
- Browser cache issues
- BaseURL configuration
- Environment inconsistencies
- CSS/asset loading problems
- Common error messages and solutions

## Deployment

The site can be deployed to:
- GitHub Pages
- Netlify
- Any static site host that supports Jekyll

Make sure your hosting provider uses compatible Jekyll versions or configure it to use the versions specified in your `Gemfile.lock`.
