# Token Pipeline

Single source of truth → platform-specific outputs. Define once, transform per platform.

## Architecture

```
tokens/                          ← Source (JSON, W3C DTCG format)
├── primitive.tokens.json
├── semantic.tokens.json
└── themes/
    ├── light.tokens.json
    └── dark.tokens.json
         │
         ▼
   Style Dictionary              ← Transform engine
         │
         ├──→  web/variables.css       (CSS custom properties)
         ├──→  web/tailwind.config.js  (Tailwind theme extension)
         ├──→  rn/tokens.ts            (TypeScript const object)
         └──→  figma/tokens.json       (Figma Variables import)
```

## Style Dictionary Setup

```bash
npm install -D style-dictionary
```

### Config: `style-dictionary.config.js`

```javascript
module.exports = {
  source: ['tokens/**/*.tokens.json'],
  platforms: {
    web: {
      transformGroup: 'css',
      buildPath: 'src/shared/ui/generated/',
      files: [{
        destination: 'variables.css',
        format: 'css/variables',
        options: { outputReferences: true }, // keeps alias chain readable
      }],
    },
    rn: {
      transformGroup: 'js',
      buildPath: 'src/shared/ui/generated/',
      files: [{
        destination: 'tokens.ts',
        format: 'javascript/es6',
      }],
    },
  },
};
```

### Build

```bash
npx style-dictionary build
```

Run this after any token file change. Add to build script:

```json
{
  "scripts": {
    "tokens:build": "style-dictionary build",
    "dev": "npm run tokens:build && next dev",
    "build": "npm run tokens:build && next build"
  }
}
```

## Workflow

1. **Edit**: Change value in `semantic.tokens.json`
2. **Build**: `npm run tokens:build`
3. **Result**: CSS variables and TS tokens update automatically
4. **Components**: Already reference variables/tokens — no code changes needed

This means a color change is a one-file edit that propagates everywhere.

## Dark Theme Pipeline

Dark theme is just another token file that overrides semantic values:

```javascript
// Style Dictionary resolves theme overrides
// Input:  semantic.tokens.json + themes/dark.tokens.json
// Output: dark mode CSS variables or TS token overrides
```

For web, generate a separate `[data-theme="dark"]` block.
For RN, generate a dark override object that merges at runtime.

## Figma Sync (Optional)

If using Figma for design, keep tokens in sync:

**Option A: Tokens Studio (Figma plugin)**
- Point plugin at your `tokens/` directory in git
- Push/pull tokens between Figma and code
- Works with Style Dictionary format

**Option B: Manual export**
- Export Figma Variables as JSON
- Transform to DTCG format
- Run Style Dictionary build

Option A is recommended if you iterate frequently in Figma. Option B is fine for code-first workflows where Figma is documentation rather than source of truth.

## Tailwind Config Generation

If using Tailwind, add a pipeline output that generates Tailwind theme config from your tokens. This keeps Tailwind utilities in sync with your design tokens automatically.

For Tailwind v4 (CSS-based), the CSS custom properties output already works — just reference them in `@theme`. No extra pipeline step needed.

For Tailwind v3 (JS config), add a custom Style Dictionary format:

```javascript
// In style-dictionary.config.js, add:
platforms: {
  // ...existing platforms...
  tailwind: {
    transformGroup: 'js',
    buildPath: 'src/shared/ui/generated/',
    files: [{
      destination: 'tailwind-tokens.js',
      format: 'tailwind/theme',
    }],
  },
}
```

Then import in `tailwind.config.js`:

```javascript
const tokens = require('./src/shared/ui/generated/tailwind-tokens');
module.exports = { theme: { extend: tokens } };
```

This way, a token change flows through the pipeline to update both CSS variables and Tailwind config in one build step.

## When to Set This Up

This pipeline pays off when:
- You have 2+ platform targets (web + RN)
- You change token values more than once a month
- You want dark mode to "just work" from one source

For a single-platform project that rarely changes tokens, directly writing CSS variables or TS tokens is simpler. Don't add infrastructure you don't need yet.
