# React + TypeScript + Vite

This template provides a minimal setup to get React working in Vite with HMR and some Oxlint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Oxc](https://oxc.rs)
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/)

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the Oxlint configuration

If you are developing a production application, we recommend enabling type-aware lint rules by installing `oxlint-tsgolint` and editing `.oxlintrc.json`:

```json
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "plugins": ["react", "typescript", "oxc"],
  "options": {
    "typeAware": true
  },
  "rules": {
    "react/rules-of-hooks": "error",
    "react/only-export-components": ["warn", { "allowConstantExport": true }]
  }
}
```

See the [Oxlint rules documentation](https://oxc.rs/docs/guide/usage/linter/rules) for the full list of rules and categories.

## Captionary donate portal

This app is a **static** Vite SPA. It does not call a payment API. Put public Ko-fi / Buy Me a Coffee / Paynow-hosted URLs and crypto addresses in `src/config/public.ts`. Empty values keep those rails disabled.

### SPA fallback (hosting)

Client routes (`/donate`, `/about`, `/payment-confirmation`, `/support` → `/donate`) need the host to serve `index.html` for unknown paths. Do not add SSR.

- **Netlify / Cloudflare Pages:** `public/_redirects` already contains `/* /index.html 200`.
- **GitHub Pages:** use a `404.html` copy of `index.html`, or a `hash` router (not used here).
- **nginx:** `try_files $uri $uri/ /index.html;`
- **Apache:** fallback to `index.html` for non-file paths.

See [Vite static deploy](https://vite.dev/guide/static-deploy.html) and [React Router static hosting](https://reactrouter.com/start/library/routing).

