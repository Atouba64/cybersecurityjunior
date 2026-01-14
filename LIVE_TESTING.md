# Live Testing Guide

This guide explains how to test your website locally with live reload, ensuring changes match production.

## Quick Start

### Development Mode (Fast, with drafts)
```bash
npm start
# or
npm run dev
```

**Features:**
- ✅ Live reload - changes appear instantly in browser
- ✅ Faster builds
- ✅ Shows draft posts
- ⚠️ May differ slightly from production (optimizations disabled)

### Production Mode (Matches deployment)
```bash
npm run dev:prod
# or
npm run test:prod
```

**Features:**
- ✅ Live reload - changes appear instantly in browser
- ✅ Matches production build exactly
- ✅ Same optimizations as Netlify/GitHub Pages
- ✅ No draft posts shown

## Access Your Site

Once the server starts, open your browser to:
- **Local:** http://localhost:4000
- **Network:** http://[your-ip]:4000 (if using `serve:network`)

## How Live Reload Works

1. **Start the server:** `npm start`
2. **Edit any file** in your project (`.md`, `.html`, `.yml`, `.css`, `.js`, etc.)
3. **Save the file**
4. **Browser automatically refreshes** - no manual refresh needed!

## Ensuring Production Accuracy

### Option 1: Test Before Committing
```bash
# Test production build locally
npm run dev:prod

# Open http://localhost:4000 and verify everything looks correct
# Then commit your changes
```

### Option 2: Build Test
```bash
# Build exactly as production
npm run build:prod

# Check the _site folder matches your expectations
# Then commit
```

## Available Scripts

| Command | Purpose |
|---------|---------|
| `npm start` | Development server with live reload |
| `npm run dev` | Same as `npm start` |
| `npm run dev:prod` | Production mode with live reload |
| `npm run test:prod` | Production mode (alternative) |
| `npm run build` | Build site (development) |
| `npm run build:prod` | Build site (production) |
| `npm run serve` | Server without live reload |
| `npm run kill` | Stop all Jekyll servers |
| `npm run clean` | Remove `_site` folder |
| `npm run rebuild` | Clean + build |
| `npm run rebuild:prod` | Clean + production build |

## Troubleshooting

### Port 4000 Already in Use
```bash
npm run kill
npm start
```

### Changes Not Appearing
1. Check browser console for errors
2. Hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)
3. Restart server: `npm run kill && npm start`

### Want to Test Production Build
```bash
npm run dev:prod
```
This uses `JEKYLL_ENV=production` which matches:
- Netlify builds (`netlify.toml`)
- GitHub Pages builds (`.github/workflows/pages-deploy.yml`)

## Best Practices

1. **During Development:** Use `npm start` for faster iteration
2. **Before Committing:** Test with `npm run dev:prod` to ensure production accuracy
3. **Before Deploying:** Run `npm run build:prod` and check `_site/` folder

## Environment Variables

- **Development:** `JEKYLL_ENV=development` (default)
- **Production:** `JEKYLL_ENV=production` (matches Netlify/GitHub Pages)

Both Netlify and GitHub Actions use `JEKYLL_ENV=production`, so testing with `npm run dev:prod` ensures your local changes match what will be deployed.

