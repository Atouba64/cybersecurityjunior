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

**Problem**: Different Jekyll versions or plugin versions between local and production. The Jekyll version running locally might be different from the one used by your hosting provider (e.g., GitHub Pages uses specific versions and supported plugins).

**Solution**: 
- **Use a Gemfile** to specify exact gems and versions (already configured ✅)
- **Always use `bundle exec`**:
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

**If issues persist**:
```bash
# Delete lock file and reinstall
rm Gemfile.lock
bundle install
bundle exec jekyll serve
```

### 4. CSS/Asset Loading Issues

**Problem**: CSS or other assets not loading correctly.

**Check**:
1. Asset paths in `_config.yml` (currently correct)
2. Browser console for 404 errors
3. Network tab in browser DevTools to see failed requests

**Solution**: 
- Ensure `baseurl` is correct in `_config.yml`
- **Always use Jekyll's built-in filters** for linking assets and pages:
  - `{{ '/styles.css' | relative_url }}` - For relative URLs
  - `{{ site.baseurl }}{% link styles.css %}` - Alternative method
  - `{{ '/path' | absolute_url }}` - For absolute URLs (use sparingly)
- These filters ensure the correct path is generated regardless of environment (local vs production)
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

### 6. Build/Serve Environment Differences

**Problem**: The default Jekyll environment when running `jekyll serve` is `development`, while a live deployment is typically `production`. This can cause differences in how the site renders (e.g., HTML compression is disabled in development).

**Solution**: Test your local build in the production environment:
```bash
# Test with production environment (matches live deployment)
JEKYLL_ENV=production bundle exec jekyll serve

# Or use the npm script (includes live reload):
npm run dev:prod

# On Windows (PowerShell):
$env:JEKYLL_ENV="production"; bundle exec jekyll serve
```

This helps catch environment-specific issues before deployment, such as:
- HTML compression settings
- Asset optimization differences
- Analytics or tracking script behavior

## Debugging Steps

### Using Browser Developer Tools

When troubleshooting differences between local and live sites:

1. **Inspect the Live Site**: 
   - Open your live site in a browser
   - Right-click and select "Inspect" to open developer tools

2. **Check the Console Tab**:
   - Often reveals errors related to loading CSS, JavaScript, or other assets
   - Shows the exact incorrect URL Jekyll is trying to use
   - Look for 404 errors or failed resource loads

3. **Check the Network Tab**:
   - Shows 404 Not Found errors for missing files
   - Helps pinpoint path issues
   - Compare request URLs with actual file locations

4. **Verify File Paths**:
   - Compare the paths in the developer tools with the actual location of files in your generated `_site` folder
   - Ensure paths match expected structure

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

If changes aren't showing or you're experiencing persistent issues:

```bash
# Stop the server (Ctrl+C)
# Clean the build directory and lock file
rm -rf _site
rm Gemfile.lock  # Optional: forces gem reinstall

# Reinstall dependencies (if Gemfile.lock was deleted)
bundle install

# Rebuild and serve
bundle exec jekyll serve --livereload
```

**Note**: Deleting `_site` and `Gemfile.lock`, then running `bundle install` and rebuilding can resolve many caching and version-related issues.

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

- [ ] **Hard refresh browser** (Cmd+Shift+R / Ctrl+Shift+R)
- [ ] **Try incognito/private browsing mode** (eliminates cache issues)
- [ ] **Check browser console** for errors (F12 → Console tab)
- [ ] **Check browser network tab** for 404 errors (F12 → Network tab)
- [ ] **Verify `baseurl` in `_config.yml`** is correct (`""` for root domain)
- [ ] **Use `bundle exec jekyll serve`** (not just `jekyll serve`)
- [ ] **Test with production environment**: `JEKYLL_ENV=production bundle exec jekyll serve`
- [ ] **Clear `_site` directory** and rebuild
- [ ] **Use `--livereload` flag** for automatic refresh: `bundle exec jekyll serve --livereload`
- [ ] **Verify asset paths use Jekyll filters** (`relative_url`, `absolute_url`)
- [ ] **Verify Jekyll version matches production** (check Gemfile.lock)

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

