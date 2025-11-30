# CybersecurityJunior

[![Deploy Jekyll site to Pages](https://github.com/Atouba64/cybersecurityjunior/actions/workflows/pages-deploy.yml/badge.svg?branch=main)](https://github.com/Atouba64/cybersecurityjunior/actions/workflows/pages-deploy.yml)
[![Netlify Status](https://api.netlify.com/api/v1/badges/30672e97-95b7-462d-be4b-9afbd391645d/deploy-status)](https://app.netlify.com/projects/cybersecurityjunior/deploys)

A Jekyll static website for cybersecurity content and blog posts using the Chirpy theme.

## Overview

This is a static website containing cybersecurity resources, blog posts, and educational content.

## Development

This is a Jekyll static site using the Chirpy theme. Build the site locally before serving.

### Local Development

```bash
# Install dependencies
bundle install

# Build the site
bundle exec jekyll build

# Serve locally with live reload
bundle exec jekyll serve --livereload
# Or use npm scripts:
npm run dev
```

Then open http://localhost:4000 in your browser.

## Deployment

The site is automatically deployed to:
- **GitHub Pages** - Automatic deployment via GitHub Actions on push to `main` branch
- **Netlify** - Configured for automatic deployment

## Project Structure

- `_posts/` - Blog posts (Markdown files)
- `_tabs/` - Navigation tabs
- `_config.yml` - Jekyll configuration
- `assets/img/` - Images (logo, avatar, etc.)
- `_site/` - Generated static site (created by Jekyll build)

## License

All content is property of the author.
