# Netlify Deployment Fix

## Problem
Netlify was trying to start a Stackbit dev server because it detected `stackbit.config.ts`, causing build failures:
```
Error: Error starting Stackbit dev server
Error: Could not start local development server
```

## Solution Applied

### 1. Updated `netlify.toml`
- Added explicit framework declaration (Jekyll)
- Added environment variable to skip Next.js plugin
- Configured build to explicitly use Jekyll

### 2. Created `.netlifyignore`
- Added `stackbit.config.ts` to ignore list
- This prevents Netlify from processing the Stackbit config

### 3. Updated `_config.yml`
- Added `stackbit.config.ts` to exclude list
- This ensures Jekyll doesn't process it during build

## Additional Steps Required in Netlify UI

If the build still fails, you may need to disable Visual Editor in Netlify:

1. Go to your Netlify site dashboard
2. Navigate to **Site configuration** → **Plugins**
3. Find **Visual Editor** or **@netlify/plugin-visual-editor**
4. **Disable** or **Remove** the plugin
5. Save changes

Alternatively:
1. Go to **Site configuration** → **Build & deploy** → **Environment variables**
2. Add: `NETLIFY_PLUGIN_VISUAL_EDITOR_DISABLED` = `true`
3. Save and redeploy

## Why This Happens

Netlify's Visual Editor plugin auto-detects Stackbit configuration files and tries to start a dev server. Since this is a Jekyll static site (not a Next.js/Stackbit site), the dev server fails.

## Verification

After applying these fixes:
1. Commit and push the changes
2. Trigger a new Netlify build
3. The build should complete successfully without Stackbit errors
4. Your Jekyll site will deploy normally

## Files Changed

- ✅ `netlify.toml` - Added framework declaration and environment variables
- ✅ `.netlifyignore` - Created to ignore Stackbit config
- ✅ `_config.yml` - Added stackbit.config.ts to exclude list

