---
name: A11y Standards — WCAG 2.1 AA
description: WCAG accessibility rules for UI components
---

# A11y Standards — WCAG 2.1 AA

All user-facing features MUST meet WCAG 2.1 AA before merge. AAA aspirational for public pages.

## Semantic HTML

| Rule | Spec |
|------|------|
| Landmarks | `<header>`, `<nav>`, `<main>` (one), `<footer>`, `<article>`, `<section>` |
| Headings | Single `<h1>`, sequential levels, never skip |
| Interactive | `<button>` = actions, `<a>` = nav, never `<div onclick>` |
| Lists | `<ul>`/`<ol>`/`<li>`, not styled divs |
| Tables | `<thead>`, `<th scope>`, `<caption>` |

## ARIA

- **Rule #1**: Prefer native HTML over ARIA
- Valid: `aria-label`, `aria-describedby`, `aria-expanded`, `aria-live`, `role="alert"`
- **Never** `role="button"` on div or override native semantics

## Keyboard

| Req | Spec |
|-----|------|
| Focus | All interactive elements focusable; visible indicator (2px, 3:1) |
| Tab order | Logical; no positive `tabindex`; no traps |
| Keys | Esc closes overlays; Enter/Space activates; arrows in composites |
| Skip link | First focusable element |

## Color & Contrast

| Element | Ratio |
|---------|-------|
| Text < 18pt | **4.5:1** |
| Large text (≥18pt/14pt bold) | **3:1** |
| UI components & graphics | **3:1** |

Never color-only indicators. Errors = icon + text + color. Test color blindness simulation.

## Screen Readers, Images & Media

| Element | Rule |
|---------|------|
| Informative img | `alt` text (max ~125 chars) |
| Decorative img | `alt=""` + `role="presentation"` |
| Complex img | Text alt nearby or `aria-describedby` |
| Icon buttons | `aria-label` with action description |
| Dynamic content | `aria-live="polite"` / `"assertive"` for errors |
| Page | `<title>` reflects state; `<html lang="es">` |
| Video/Audio | Captions required; transcripts for audio |

## Forms

- Inputs → visible `<label>` via `for`/`id`; required = `aria-required` + visual
- Errors → `aria-describedby` + `role="alert"`/`aria-live`
- Groups → `<fieldset>` + `<legend>`; personal data → `autocomplete`

> DO/DON'T examples: `references/a11y-examples.md`

## Motion

- Respect `prefers-reduced-motion`; no auto-play > 5s without controls; no flash > 3/sec

## Testing

| Type | Details |
|------|---------|
| Automated | axe-core via `@axe-core/playwright` in CI; critical/serious block PR |
| Manual | Keyboard-only, screen readers (NVDA/VoiceOver/TalkBack), 200% zoom, high contrast |
| Tools | axe DevTools, Lighthouse, WAVE |

## Component Rules

| Component | Requirements |
|-----------|-------------|
| Modals | Focus trap, Esc closes, return focus to trigger |
| Dropdowns | Arrow keys, Esc closes, `aria-expanded` |
| Tabs | `role="tablist/tab/tabpanel"`, arrow keys |
| Tables | `scope="col/row"`, `<caption>` |
| Alerts/Toasts | `role="alert"`, auto-dismiss ≥ 5s |
| Loading | `aria-busy="true"`, announce completion |
