# Troubleshooting Guide

## Local vs Live Site Differences

If your local Jekyll server looks different from the live site, here are the most common causes and solutions:

### 1. Browser Cache Issues

**Problem**: Your browser is serving cached CSS, JavaScript, or other assets from the live site. This is one of the most common causes of differences between local and live sites.

**Solutions**:
- **Hard Refresh**: 
  - Mac: `Cmd + Shift + R` or `Cmd + Option + R`
  - Windows/Linux: `Ctrl + Shift + R` or `Ctrl + F5`
- **Clear Browser Cache**: Go to your browser settings and clear cached files
- **Use Incognito/Private Mode**: Open the site in a private browsing window to view without cached files
- **Use Live Reload**: Run `bundle exec jekyll serve --livereload` (or `-l`) to automatically reload the page when files change, bypassing some cache issues during development
- **Alternative**: Use `npm run dev` which includes `--livereload`

### 2. BaseURL Configuration

**Problem**: Incorrect `baseurl` setting can cause assets to load from wrong paths.

**Current Configuration**:
- `baseurl: ""` (empty - correct for root domain)
- `url: "https://cybersecurityjunior.com"`

**For Local Development**:
- The `baseurl` should remain empty (`""`) for local development
- Jekyll automatically handles local vs production URLs

**If you need to test with a subdirectory**:
```yaml
baseurl: "/subdirectory"  # Only if deploying to a subdirectory
```

### 3. Environment Inconsistencies

**Problem**: Different Jekyll versions or plugin versions between local and production.

**Solution**: Always use `bundle exec`:
```bash
# ✅ Correct - uses versions from Gemfile.lock
bundle exec jekyll serve

# ❌ Incorrect - may use system Jekyll version
jekyll serve
```

**Verify versions match**:
```bash
bundle exec jekyll --version
# Compare with your hosting provider's Jekyll version
```

### 4. CSS/Asset Loading Issues

**Problem**: CSS or other assets not loading correctly.

**Check**:
1. Asset paths in `_config.yml` (currently correct)
2. Browser console for 404 errors
3. Network tab in browser DevTools to see failed requests

**Solution**: 
- Ensure `baseurl` is correct
- Check that asset paths use `{{ site.baseurl }}/assets/...` in templates
- Clear browser cache and hard refresh

### 5. PWA Cache Issues

**Problem**: Service Worker caching old versions of the site.

**Current PWA Settings**:
```yaml
pwa:
  enabled: true
  cache:
    enabled: true
```

**Solution**:
- Disable PWA cache during development (if needed)
- Clear service worker cache in browser DevTools → Application → Service Workers
- Unregister service worker if testing locally

## Development Best Practices

### Use Live Reload for Development

```bash
npm run dev
```

This automatically:
- Reloads the browser when files change
- Bypasses some browser caching
- Shows changes immediately

### Force Rebuild

If changes aren't showing:

```bash
# Stop the server (Ctrl+C)
# Clean the build directory
rm -rf _site

# Rebuild and serve
bundle exec jekyll serve --livereload
```

### Check for Build Errors

```bash
# Build without serving to see all errors
bundle exec jekyll build --verbose
```

### Network Access

To access your local server from other devices on your network:

```bash
bundle exec jekyll serve --livereload --host 0.0.0.0
```

Then access via: `http://YOUR_IP_ADDRESS:4000`

## Quick Checklist

When local site looks different from live:

- [ ] Hard refresh browser (Cmd+Shift+R / Ctrl+Shift+R)
- [ ] Try incognito/private browsing mode
- [ ] Check browser console for errors
- [ ] Verify `baseurl` in `_config.yml` is correct
- [ ] Use `bundle exec jekyll serve` (not just `jekyll serve`)
- [ ] Clear `_site` directory and rebuild
- [ ] Check that you're using `npm run dev` for live reload
- [ ] Verify Jekyll version matches production

## Common Error Messages

### "Could not locate Gemfile"
**Solution**: Make sure you're in the `cybersecurityjunior` directory:
```bash
cd /path/to/cybersecurityjunior
bundle exec jekyll serve
```

### "Liquid Exception: undefined method"
**Solution**: Usually a version mismatch. Run:
```bash
bundle update
bundle exec jekyll serve
```

### "404 for assets"
**Solution**: Check `baseurl` configuration and ensure asset paths are correct.

