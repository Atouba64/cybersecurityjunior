# CybersecurityJunior

[![Netlify Status](https://api.netlify.com/api/v1/badges/30672e97-95b7-462d-be4b-9afbd391645d/deploy-status)](https://app.netlify.com/projects/cybersecurityjunior/deploys)

A static website for cybersecurity content and blog posts.

## Overview

This is a static website containing cybersecurity resources, blog posts, and educational content.

## Development

This is a static site - no build process required. Simply open the HTML files directly or serve them with any static file server.

### Local Development

You can use any simple HTTP server to preview the site locally:

```bash
# Using Python
python -m http.server 8000

# Using Node.js (http-server)
npx http-server

# Using PHP
php -S localhost:8000
```

Then open http://localhost:8000 in your browser.

## Deployment

The site can be deployed to:
- **Netlify** - Configured for automatic deployment
- **GitHub Pages** - Push HTML files directly
- Any static hosting service

## Project Structure

- `index.html` - Homepage
- `pages/` - Additional pages
- `assets/` - CSS, images, and JavaScript files
- `legal/` - Legal pages (privacy policy, terms, etc.)

## License

All content is property of the author.
