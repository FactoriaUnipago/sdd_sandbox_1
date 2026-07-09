---
name: Design System Base
description: theme selection, design tokens, UI component patterns
---

# Design System Base

CSS custom properties. STRUCTURE here; VALUES from active theme.

## ⚠️ REQUIRE: Active theme

1. Check `theme` in `.sdd-config.json`
2. Read `core/themes/THEME_[NAME].md`
3. Use colors, typography, style from theme

Themes: `fintech` · `healthcare` · `corporate` · `insurtech` · `govtech` · `institutional` · `custom`

NEVER use hardcoded colors without consulting the theme.

## CSS Framework

Check `css_framework` in `.sdd-config.json`:

| Value | Behavior |
|---|---|
| `"vanilla"` (default) | CSS custom properties + component classes in `.css` files |
| `"tailwind"` | Tailwind CSS 4 utility classes — theme tokens mapped to `tailwind.config.ts` |

- If `css_framework` is not set → default to `"vanilla"`
- If Tailwind → set `css_framework: "tailwind"` → map theme tokens to `tailwind.config.ts`
- **NEVER mix**: if Tailwind, all styling via utilities. If vanilla, all via `.css` classes. No hybrid.


## Tokens

> Full CSS: `references/design-tokens.css`

### Colors (token→theme-var)

**Surface**: `primary`→`theme-surface`, `secondary`→`theme-surface-alt`, `elevated`→`theme-elevated`, `overlay`: rgba(0,0,0,0.5)
**Accent**: `primary`→`theme-primary`, `secondary`→`theme-secondary`, `danger`→`theme-error`, `warning`→`theme-warning`, `success`→`theme-success`
**Text**: `primary`→`theme-text`, `secondary`→`theme-text-muted`, `on-accent`→`theme-text-inverse`

### Typography

Fonts: `--font-family-base`: var(--theme-font, 'Inter') · `--font-family-mono`: 'JetBrains Mono'

Sizes: `xs`:0.75rem · `sm`:0.875 · `base`:1 · `lg`:1.125 · `xl`:1.25 · `2xl`:1.5 · `3xl`:2 · `4xl`:2.5rem
Weights: `regular`:400 · `medium`:500 · `semibold`:600 · `bold`:700

### Spacing (4px grid)

`--space-1`:4 · `--space-2`:8 · `--space-3`:12 · `--space-4`:16 · `--space-6`:24 · `--space-8`:32 · `--space-12`:48 · `--space-16`:64px

### Border Radius
`--radius-sm`:4 · `--radius-md`:8 · `--radius-lg`:12 · `--radius-xl`:16 · `--radius-full`:9999px

### Shadows
`--shadow-sm`: 0 1px 2px rgba(0,0,0,0.05) · `--shadow-md`: 0 4px 6px rgba(0,0,0,0.07) · `--shadow-lg`: 0 10px 15px rgba(0,0,0,0.1) · `--shadow-xl`: 0 20px 25px rgba(0,0,0,0.15)

## Components

Composition over config, controlled state. API: `variant`, `size`, `disabled`, `className`.

| Category | Elements | Variants |
|----------|----------|----------|
| Buttons | primary, secondary, ghost, danger | sm, md, lg |
| Inputs | text, select, checkbox, radio, textarea, switch | — |
| Cards | default, elevated, interactive (hover) | — |
| Modals | dialog, drawer, toast/snackbar | — |
| Tables | sortable headers, pagination, row selection | — |
| Nav | sidebar, breadcrumb, tabs, top bar | — |

## Responsive · Icons · Animation · A11y

| Area | Rules |
|------|-------|
| Breakpoints | `sm:640` · `md:768` · `lg:1024` · `xl:1280` · `2xl:1536` (mobile-first) |
| Layout | Single col mobile → multi-col tablet+. Touch ≥44×44px |
| Icons | Lucide/Heroicons. 16/20/24/32px. `aria-label` buttons, `aria-hidden` decorative |
| Animation | `transform`+`opacity` only. Micro ≤300ms, page ≤500ms. `cubic-bezier(0.4,0,0.2,1)` |
| Motion | `prefers-reduced-motion` ALWAYS respected |
| A11y | Keyboard nav + visible focus. WCAG AA (see a11y-standards.md). SR state announcements |

## Layout Patterns

| Pattern | Structure | Usage |
|---------|-----------|-------|
| Dashboard | Sidebar 240px (collapsible→64px) + top bar 64px + main content (padding 24px, max-width 1280px). Mobile: sidebar→bottom nav | Admin panels, analytics |
| Form page | Centered card max-width 480px (single col) or 640px (two col). Padding 32px/24px mobile. Actions sticky-bottom on mobile | Create/edit flows |
| List/Table | Filters bar + data table + pagination footer. Table: sticky header, alternating rows optional | Data management |
| Landing | Hero (full-width, gradient bg) + feature sections (alternating layout) + CTA + footer | Marketing, onboarding |
| Auth | Split screen: left=branding/illustration, right=form card. Mobile: form only, branding hidden | Login, register, forgot pw |
| Detail | Header (breadcrumb + title + actions) + content sections + sidebar (metadata). Mobile: single column | View/edit single entity |

## Loading States

| Type | Implementation | When |
|------|---------------|------|
| Skeleton | Pulse animation on gray rectangles matching content layout | Page/section first load |
| Spinner | 20px inline or 40px page-center, accent color, 800ms rotation | Button submit, small areas |
| Progress bar | 4px height, accent color, top of page or card | File uploads, multi-step |
| Overlay | Surface-overlay + centered spinner | Modal actions |

## Empty States

| Type | Content |
|------|--------|
| No data | Illustration (64px icon muted) + "No [items] yet" + CTA button |
| Search no results | Search icon + "No results for '[query]'" + suggestions |
| Error loading | Alert icon + "Could not load [resource]" + retry button |
| First time | Welcome illustration + "Get started by [action]" + primary CTA |

## Feedback Patterns

| Type | Behavior |
|------|----------|
| Toast/Snackbar | Top-right, auto-dismiss 5s (success) or persistent (error). Max 3 stacked |
| Confirmation dialog | Modal, destructive=red CTA, cancel=ghost. "Are you sure?" + consequence |
| Inline success | Green check icon + message below field/action, fade after 3s |
| Form error banner | Top of form, red bg muted, icon + error list. Persists until resolved |
| Field error | Red border + 12px error text below field. Icon AlertCircle optional |

## Mobile-First (Capacitor / Native)

### Safe Areas

| Token | CSS | Purpose |
|-------|-----|--------|
| `--safe-top` | `env(safe-area-inset-top, 0px)` | Status bar / Dynamic Island |
| `--safe-bottom` | `env(safe-area-inset-bottom, 0px)` | Home indicator / gesture bar |
| `--safe-left` | `env(safe-area-inset-left, 0px)` | Landscape notch |
| `--safe-right` | `env(safe-area-inset-right, 0px)` | Landscape notch |

Required meta tag: `<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">`

### Touch Targets

| Rule | Value |
|------|-------|
| Minimum size | 44×44 CSS px (WCAG 2.2 AAA: 48×48) |
| Minimum spacing | 8px between targets |
| Thumb zone | Primary actions in bottom 40% of screen |
| Avoid | Critical targets in top corners (unreachable) |

### Gesture Navigation

| Rule | Detail |
|------|--------|
| Bottom nav clearance | Pad bottom nav with `--safe-bottom` + 34px (Android gesture bar) |
| Edge swipes | Avoid swipe-from-edge interactions (conflicts with OS back gesture) |
| Fallback | Always provide visible button fallbacks for gesture-only actions |

### Native App Patterns

| Pattern | Structure |
|---------|----------|
| Bottom navigation | Tab bar fixed at bottom + `padding-bottom: var(--safe-bottom)` |
| Pull-to-refresh | Native pull gesture on scrollable lists. Spinner at top |
| Sticky header | `position: sticky; top: 0; padding-top: var(--safe-top)` |
| FAB | `bottom: calc(var(--safe-bottom) + 72px)` (clears bottom nav) |
| Modal sheet | Bottom sheet with rounded top corners, respects safe areas |

### WebView Performance (Capacitor)

| Rule | Detail |
|------|--------|
| GPU animations | Use only `transform` + `opacity` (compositor-only properties) |
| `backdrop-filter` | Avoid on low-end Android WebViews — causes jank |
| Shadows | Simplify on mobile: `--shadow-sm` max for cards, no stacked shadows |
| Images | Always use `loading="lazy"`, `decoding="async"`, sized containers |
| Scrolling | Use `overflow-y: auto` not `scroll`. Avoid nested scroll containers |

### Breakpoints (Extended)

| Name | Width | Target |
|------|-------|--------|
| `xs` | 360px | Small phones (Galaxy S series, older iPhones) |
| `sm` | 640px | Large phones / small tablets |
| `md` | 768px | Tablets portrait |
| `lg` | 1024px | Tablets landscape / small laptops |
| `xl` | 1280px | Desktops |
| `2xl` | 1536px | Large desktops |

## Rules

1. **Use CSS classes, not inline styles** — components MUST use design system classes (`.card`, `.btn-primary`, `.input`, etc.). NEVER replicate layout/spacing/colors inline.
   ```tsx
   // ❌ WRONG
   <div style={{ minHeight: '100vh', display: 'flex', background: '#1E40AF' }}>
   
   // ✅ CORRECT
   <div className="page-centered">
   ```

2. **CSS variables belong in stylesheets** — `var(--theme-primary)` goes in `.css` files, not in JSX `style={}` attributes.
   ```css
   /* ❌ WRONG — in JSX */
   style={{ color: 'var(--theme-primary)' }}
   
   /* ✅ CORRECT — in .css */
   .title { color: var(--theme-primary); }
   ```

3. **Inline styles ONLY for runtime-dynamic values** — values computed from state/props/data at runtime (e.g., `width: ${progress}%`, `transform: translateX(${offset}px)`). If the value is static, it belongs in CSS.

4. **Theme tokens are mandatory** — NEVER hardcode colors, spacing, shadows, or fonts. Always use design system tokens (`var(--theme-*)`, `var(--space-*)`, `var(--shadow-*)`).

5. **Component CSS files** — each component has its own `.css` file using design system tokens. No utility-class soup unless using Tailwind (only if user requested).

6. **Base styles in index.css** — reset, theme variables, global typography, shared component classes (`.card`, `.btn`, `.input`, etc.) all live in the entry CSS file.
