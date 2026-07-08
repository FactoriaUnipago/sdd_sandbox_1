# UI Design Prompt Template — Reference

Generate ONE section per page/screen in this format. Each prompt MUST be self-contained — include ALL visual details so the agent or Stitch/v0 can generate without reading other files.

## ⚠️ REQUIRE: Before generating UI prompts

1. Read the active theme from `core/themes/THEME_[NAME].md`
2. Read `design-system-base.md` for component patterns and tokens
3. Extract and embed ALL values directly in each prompt:
   - Exact hex colors (NOT "use primary color" — write "#0A1628")
   - Exact font family and weights (NOT "use heading font" — write "Inter, 700")
   - Exact spacing in px (NOT "use space-4" — write "16px")
   - Exact border-radius, shadows, transitions

NEVER write "see theme file" or "refer to design system" in a prompt. The prompt must work standalone.

---

## Example: Page /payments/new — Payment Form

### Metadata
- **Route**: `/payments/new`
- **Auth**: Required (role: user)
- **Layout**: Single column, centered
- **Responsive**: Mobile-first

### Visual Prompt (copy to Stitch/v0/Bolt)

```
A modern payment form on a dark fintech interface.

LAYOUT:
- Page background: #0A1628 (deep navy)
- Content centered, max-width 480px, padding 24px horizontal
- Vertical stack, gap 24px

CARD (main container):
- Background: rgba(17, 24, 39, 0.8) with backdrop-filter blur(16px)
- Border: 1px solid rgba(6, 182, 212, 0.15)
- Border-radius: 12px
- Shadow: 0 20px 25px rgba(0, 0, 0, 0.15)
- Padding: 32px

TYPOGRAPHY (Inter font family):
- Page title: "New Payment" — 24px, weight 700, color #F1F5F9
- Field labels: 14px, weight 500, color #94A3B8, margin-bottom 6px
- Input text: 16px, weight 400, color #F1F5F9
- Helper text: 12px, weight 400, color #64748B

FORM FIELDS (stacked, gap 16px):
1. Amount input
   - Large display: 32px, weight 600, color #F1F5F9
   - Currency selector inline-right: dropdown (USD / PAB)
   - Prefix "$" in #64748B

2. Card number
   - Format: XXXX XXXX XXXX XXXX (auto-format on type)
   - Card brand icon appears right side on first 4 digits
   - Icons: Visa (blue), Mastercard (orange/red), Amex (blue)
   - Placeholder: "1234 5678 9012 3456", color #475569

3. Row (2 columns, gap 12px):
   - Left 50%: Expiry — placeholder "MM/YY"
   - Right 50%: CVV — placeholder "123", type password

4. Description (optional)
   - Textarea, 3 rows
   - Placeholder: "Payment description (optional)"
   - Character counter bottom-right: "0/255", color #64748B

INPUT STYLING (all inputs):
- Background: rgba(17, 24, 39, 0.6)
- Border: 1px solid rgba(148, 163, 184, 0.2)
- Border-radius: 8px
- Padding: 12px 16px
- Transition: border-color 200ms ease, box-shadow 200ms ease
- Focus: border-color #06B6D4, box-shadow 0 0 0 3px rgba(6, 182, 212, 0.1)
- Error: border-color #EF4444, box-shadow 0 0 0 3px rgba(239, 68, 68, 0.1)

CTA BUTTON:
- Text: "Pay $XX.XX" (live amount)
- Full width, height 48px, border-radius 8px
- Background: linear-gradient(135deg, #06B6D4, #0891B2)
- Color: white, font 16px weight 600
- Hover: transform scale(1.02), shadow 0 8px 16px rgba(6, 182, 212, 0.3)
- Active: transform scale(0.98)
- Disabled: opacity 0.5, cursor not-allowed, no hover effects
- Loading: text replaced with 20px spinner (white), fields disabled

SECURITY BADGES (below card):
- Horizontal row, centered, gap 8px
- Lock icon (Lucide Lock, 14px) + "PCI DSS Compliant"
- Text: 12px, color #64748B

MICRO-ANIMATIONS:
- Input focus: 200ms border-color transition
- Button hover: 150ms transform + shadow
- Card brand icon: 200ms opacity fade-in
- Error shake: 300ms horizontal shake on validation fail
- Success: green checkmark scale-in animation

MOBILE (< 640px):
- Card: border-radius 0, full-width, no horizontal margin
- Padding: 24px instead of 32px
- Amount font: 28px instead of 32px
```

### Components (from design-system-base)
| Component | Variant | Size |
|-----------|---------|------|
| Card | elevated, glassmorphism | — |
| Input | text, number, select, textarea | md |
| Button | primary | lg |
| Icon | Lucide: CreditCard, Lock, Check, AlertCircle | md (20px) |

### Spacing tokens used
| Token | Value | Where |
|-------|-------|-------|
| `--space-3` | 12px | Input padding vertical |
| `--space-4` | 16px | Field gap, input padding horizontal |
| `--space-6` | 24px | Section gap, mobile padding |
| `--space-8` | 32px | Card padding |

### States
| State | Visual change |
|-------|--------------|
| Empty | All fields empty, CTA shows "Pay $0.00", CTA disabled (opacity 0.5) |
| Filling | Fields validate on blur, CTA updates live amount |
| Validation error | Red border + error text below field, icon AlertCircle |
| Submitting | CTA shows spinner, all fields disabled, opacity 0.7 |
| Success | Redirect to /payments/:id, success toast top-right (green, auto-dismiss 5s) |
| Payment error | Error banner below card: red bg, white text, shake animation |

### Interactions
| Trigger | Action |
|---------|--------|
| Type in card number | Auto-format XXXX XXXX, detect brand on 4th digit |
| Type in amount | Format with 2 decimals, update CTA text live |
| Blur on field | Validate, show error if invalid |
| Click disabled CTA | Highlight first invalid field |
| Submit success | Show toast, redirect after 2s |
| Submit error | Show error banner, re-enable form |

### Accessibility
| Element | Requirement |
|---------|-------------|
| All inputs | `<label>` with `for` attribute, `aria-describedby` for error messages |
| Card brand icon | `aria-hidden="true"` (decorative) |
| CTA button | `aria-busy="true"` during submit, `aria-disabled="true"` when disabled |
| Error messages | `role="alert"` for screen reader announcement |
| Amount display | `aria-live="polite"` for live updates |
| Tab order | Amount → Currency → Card → Expiry → CVV → Description → Submit |
| Focus indicator | 3px cyan ring on all interactive elements |

---

## Example: Page /dashboard — Main Dashboard

### Metadata
- **Route**: `/dashboard`
- **Auth**: Required (role: user)
- **Layout**: Sidebar + main content
- **Responsive**: Desktop-first, sidebar collapses on mobile

### Visual Prompt (copy to Stitch/v0/Bolt)

```
A modern analytics dashboard on a dark fintech interface.

LAYOUT:
- Sidebar: width 240px, background #111827, border-right 1px solid rgba(148, 163, 184, 0.08)
- Collapsed sidebar: 64px (icon-only), tooltip on hover
- Top bar: height 64px, background rgba(17, 24, 39, 0.93), backdrop-filter blur(6px), border-bottom 1px solid rgba(148, 163, 184, 0.06), sticky top 0, z-index 20
- Main content: background #0A1628, padding 24px, overflow-y auto

SIDEBAR:
- Logo area: 64px height, padding 16px, border-bottom 1px solid rgba(148, 163, 184, 0.06)
- Nav items: padding 12px 16px, border-radius 8px, color #94A3B8, font 14px weight 500
- Active item: background rgba(6, 182, 212, 0.1), color #06B6D4, left-border 3px solid #06B6D4
- Hover: background rgba(148, 163, 184, 0.06)
- Sections: separated by 1px divider rgba(148, 163, 184, 0.06), section label 11px uppercase #475569 weight 600

TOP BAR:
- Left: breadcrumb (12px, color #64748B, separator "/")
- Center: search input (max-width 400px, background rgba(17, 24, 39, 0.6), border 1px solid rgba(148, 163, 184, 0.1), border-radius 8px, placeholder "Search..." color #475569)
- Right: notification bell (badge red dot 8px if unread) + avatar circle 32px

STATS CARDS ROW (4 cards, gap 16px):
- Card: background rgba(17, 24, 39, 0.93), border 1px solid rgba(148, 163, 184, 0.06), border-radius 12px, padding 20px
- Label: 12px weight 500 color #64748B uppercase letter-spacing 0.05em
- Value: 28px weight 700 color #F1F5F9, font Space Grotesk
- Change indicator: 12px, green #22C55E with ↑ or red #EF4444 with ↓, background rgba of color at 0.1, padding 2px 6px, border-radius 4px
- Sparkline: 40px height, accent color #06B6D4, bottom of card

DATA TABLE:
- Header: background rgba(17, 24, 39, 0.6), font 12px weight 600 color #64748B uppercase
- Rows: border-bottom 1px solid rgba(148, 163, 184, 0.04), padding 12px 16px
- Row hover: background rgba(6, 182, 212, 0.03)
- Cell text: 14px weight 400 color #F1F5F9
- Status badges: padding 4px 8px, border-radius 4px, font 12px weight 500
  - Active: bg rgba(34, 197, 94, 0.1) color #22C55E
  - Pending: bg rgba(234, 179, 8, 0.1) color #EAB308
  - Failed: bg rgba(239, 68, 68, 0.1) color #EF4444
- Pagination: bottom, 14px, previous/next buttons ghost style

MOBILE (< 768px):
- Sidebar hidden, hamburger menu top-left
- Stats cards: 2 per row, gap 12px
- Table: horizontal scroll, min-width 600px
- Top bar: search hidden, icon-only
```

### Components (from design-system-base)
| Component | Variant | Size |
|-----------|---------|------|
| Nav | sidebar, breadcrumb | — |
| Card | default, elevated | — |
| Table | sortable headers, pagination | — |
| Button | ghost, primary | sm, md |
| Input | text (search) | md |
| Badge | status | sm |

### States
| State | Visual change |
|-------|--------------|
| Loading | Skeleton cards (4 pulse rectangles) + skeleton table rows (6 rows) |
| No data | Centered illustration + "No transactions yet" + CTA |
| Error | Error banner top of main content, red muted bg, retry button |
| Sidebar collapsed | 64px width, icons only, labels hidden, tooltip on hover |

---

## Example: Page /login — Authentication

### Metadata
- **Route**: `/login`
- **Auth**: Public
- **Layout**: Split screen
- **Responsive**: Mobile-first

### Visual Prompt (copy to Stitch/v0/Bolt)

```
A modern login page with split-screen layout, dark fintech theme.

LAYOUT:
- Left panel (50%): background linear-gradient(135deg, #0A1628, #111827), centered branding + illustration
- Right panel (50%): background #111827, centered form card
- Mobile: left panel hidden, form full-width with subtle gradient bg

LEFT PANEL:
- Logo: SVG or text, 24px weight 700, color #F1F5F9, top-left padding 32px
- Center: abstract financial illustration or animated gradient mesh
- Bottom: tagline 16px weight 400 color #94A3B8, max-width 320px, centered
- Decorative: subtle grid pattern overlay at 3% opacity

RIGHT PANEL:
- Form card: max-width 400px, centered vertically and horizontally
- No visible card border — content directly on panel background

FORM:
- Title: "Welcome back" — 28px weight 700 color #F1F5F9, Space Grotesk
- Subtitle: "Sign in to your account" — 14px weight 400 color #64748B, margin-bottom 32px

- Email input:
  - Label: "Email" 14px weight 500 color #94A3B8
  - Input: background rgba(17, 24, 39, 0.6), border 1px solid rgba(148, 163, 184, 0.2), border-radius 8px, padding 12px 16px
  - Icon left: Mail (Lucide, 18px, color #475569)

- Password input:
  - Label: "Password" with "Forgot?" link right-aligned, color #06B6D4, 13px
  - Input: same as email, type password
  - Icon left: Lock (Lucide, 18px, color #475569)
  - Toggle eye icon right: EyeOff/Eye (Lucide, 18px)

- Remember me: checkbox + label "Remember me" 14px color #94A3B8

- Submit button:
  - "Sign in" — full width, height 48px, border-radius 8px
  - Background: linear-gradient(135deg, #06B6D4, #0891B2)
  - Color white, 16px weight 600
  - Hover: brightness 1.1, shadow 0 8px 16px rgba(6, 182, 212, 0.2)

- Divider: "or continue with" — 13px color #475569, lines rgba(148, 163, 184, 0.1)

- Social buttons row (gap 12px):
  - Google, GitHub — height 44px, border 1px solid rgba(148, 163, 184, 0.2), border-radius 8px, bg transparent
  - Icon 20px + label 14px weight 500 color #F1F5F9
  - Hover: background rgba(148, 163, 184, 0.06)

- Footer: "Don't have an account? Sign up" — 14px, "Sign up" color #06B6D4

MOBILE (< 768px):
- Left panel: hidden
- Right panel: full width, background gradient #0A1628 → #111827
- Form: padding 24px, max-width none
- Social buttons: stacked vertically
```

### States
| State | Visual change |
|-------|--------------|
| Empty | All fields empty, submit enabled |
| Typing | Focus ring on active input |
| Validation error | Red border + "Invalid email" below field |
| Submitting | Button shows spinner, fields disabled |
| Auth error | Red banner above form: "Invalid credentials", shake animation 300ms |
| Success | Redirect to /dashboard |

### Accessibility
| Element | Requirement |
|---------|-------------|
| Form | `role="form"`, `aria-label="Sign in"` |
| Password toggle | `aria-label="Show password"` / `"Hide password"` |
| Error messages | `role="alert"`, `aria-live="assertive"` |
| Social buttons | `aria-label="Sign in with Google"` |
| Tab order | Email → Password → Remember → Sign in → Google → GitHub → Sign up |

---

## Example: Page /tasks — Data Table

### Metadata
- **Route**: `/tasks`
- **Auth**: Required
- **Layout**: Dashboard (sidebar + main)
- **Responsive**: Desktop-first

### Visual Prompt (copy to Stitch/v0/Bolt)

```
A data management page with filters, sortable table, and bulk actions.

PAGE HEADER:
- Breadcrumb: "Dashboard / Tasks" — 12px color #64748B
- Title row: "Tasks" 24px weight 700 color #F1F5F9 + right: "Create Task" primary button (height 40px, bg gradient #06B6D4→#0891B2, border-radius 8px, icon Plus 16px)

FILTERS BAR:
- Background: rgba(17, 24, 39, 0.93), border 1px solid rgba(148, 163, 184, 0.06), border-radius 12px, padding 16px, margin-bottom 16px
- Row: gap 12px, flex-wrap
- Search: width 240px, icon Search left, placeholder "Search tasks..."
- Status dropdown: "All statuses" — bg transparent, border rgba(148, 163, 184, 0.2), width 160px
- Date range: icon Calendar, "Last 30 days" — same style
- Clear filters: ghost button "Clear" — 13px color #64748B, visible only when filters active

BULK ACTIONS BAR (visible when rows selected):
- Background: rgba(6, 182, 212, 0.08), border-radius 8px, padding 8px 16px
- Left: "3 selected" — 14px weight 500 color #06B6D4
- Right: "Delete" danger ghost + "Export" ghost + "Assign" ghost

TABLE:
- Container: border 1px solid rgba(148, 163, 184, 0.06), border-radius 12px, overflow hidden
- Header: background rgba(17, 24, 39, 0.6), font 12px weight 600 color #64748B uppercase letter-spacing 0.05em, padding 12px 16px
- Sortable columns: cursor pointer, hover color #94A3B8, active: icon ChevronUp/Down 12px
- Checkbox column: width 48px, centered
- Rows: padding 14px 16px, border-bottom 1px solid rgba(148, 163, 184, 0.04)
- Row hover: background rgba(6, 182, 212, 0.02)
- Row selected: background rgba(6, 182, 212, 0.06)

COLUMNS:
- [ ] checkbox | Title (14px, weight 500, color #F1F5F9, max-width 300px truncate) | Status badge | Assignee (avatar 24px + name 13px) | Due date (13px color #94A3B8) | Priority (dot 8px + label) | Actions (⋯ menu)

PAGINATION:
- Bottom bar: padding 12px 16px, border-top 1px solid rgba(148, 163, 184, 0.04)
- Left: "Showing 1-10 of 54" — 13px color #64748B
- Right: page buttons (32px square, border-radius 6px, current=bg accent muted)

ROW ACTIONS MENU (on ⋯ click):
- Dropdown: bg #1E293B, border rgba(148, 163, 184, 0.1), border-radius 8px, shadow-lg, padding 4px
- Items: 14px, padding 8px 12px, border-radius 4px, hover bg rgba(148, 163, 184, 0.06)
- Destructive: color #EF4444

MOBILE (< 768px):
- Table → card list layout
- Each card: border-radius 8px, padding 16px, margin-bottom 8px
- Title + status badge top, metadata below, actions bottom-right
```

### States
| State | Visual change |
|-------|--------------|
| Loading | Skeleton: filter bar + 6 skeleton rows |
| Empty (no filters) | Centered: clipboard icon + "No tasks yet" + "Create Task" CTA |
| Empty (filtered) | "No tasks match your filters" + "Clear filters" link |
| Bulk selected | Blue highlight bar appears above table |
| Deleting | Confirmation modal: "Delete 3 tasks? This cannot be undone." |

---

## Example: Page /settings — Settings

### Metadata
- **Route**: `/settings`
- **Auth**: Required
- **Layout**: Dashboard (sidebar + main), settings tabs
- **Responsive**: Desktop-first

### Visual Prompt (copy to Stitch/v0/Bolt)

```
A settings page with tabbed navigation and form sections.

PAGE:
- Title: "Settings" — 24px weight 700 color #F1F5F9
- Subtitle: "Manage your account preferences" — 14px color #64748B

TABS:
- Horizontal tabs: border-bottom 1px solid rgba(148, 163, 184, 0.08)
- Tab items: padding 12px 16px, 14px weight 500, color #64748B
- Active tab: color #06B6D4, border-bottom 2px solid #06B6D4
- Hover: color #94A3B8
- Tabs: Profile | Notifications | Security | Billing

PROFILE SECTION:
- Avatar: 80px circle, border 2px solid rgba(148, 163, 184, 0.1), "Change" overlay on hover (bg rgba(0,0,0,0.5) + camera icon)
- Form: 2-column grid (gap 16px) on desktop, single column mobile
  - Full name (text input)
  - Email (text input, disabled bg, lock icon — "Contact support to change")
  - Phone (text input, country code dropdown left)
  - Timezone (select dropdown)
  - Bio (textarea, 3 rows, character counter "0/280")

NOTIFICATIONS SECTION:
- Card per category: background rgba(17, 24, 39, 0.93), border rgba(148, 163, 184, 0.06), border-radius 12px, padding 20px
- Each row: label left (14px weight 500 #F1F5F9 + description 13px #64748B below) + toggle switch right
- Toggle switch: width 44px, height 24px, border-radius 12px
  - Off: bg rgba(148, 163, 184, 0.2), circle white left
  - On: bg #06B6D4, circle white right
  - Transition: 200ms ease
- Categories: Email, Push, SMS — each with 3-4 toggles

SECURITY SECTION:
- Password change: current + new + confirm fields, "Update" button
- Two-factor: toggle + setup flow
- Sessions: table of active sessions (device, location, last active), "Revoke" danger ghost per row

SAVE BAR (sticky bottom when changes detected):
- Background: rgba(17, 24, 39, 0.95), border-top 1px solid rgba(148, 163, 184, 0.08), padding 12px 24px
- Left: "You have unsaved changes" — 14px color #EAB308, icon AlertTriangle
- Right: "Discard" ghost + "Save changes" primary button
- Animation: slide-up 200ms on appear

MOBILE (< 768px):
- Tabs: horizontal scroll, no wrap
- Form: single column
- Save bar: full width, buttons stacked if needed
```

### States
| State | Visual change |
|-------|--------------|
| Clean | Save bar hidden, no highlights |
| Modified | Save bar appears, changed fields have subtle left-border accent |
| Saving | Save button shows spinner, "Saving..." |
| Saved | Toast: "Settings saved" (green, top-right, auto-dismiss 3s) |
| Error | Toast: "Failed to save" (red, persistent) + retry |
| Toggle animating | 200ms slide + color transition |

---

## Rules for generating UI prompts

1. ALWAYS embed exact hex colors from the active theme (NEVER "use primary")
2. ALWAYS specify font family, size in px/rem, and weight as numbers
3. ALWAYS specify spacing in px (and note the token name in parentheses)
4. ALWAYS specify border-radius, shadows, transitions with exact CSS values
5. ALWAYS include mobile breakpoint adjustments
6. ALWAYS list ALL states with visual description
7. ALWAYS list interactions as trigger → action pairs
8. ALWAYS include accessibility table
9. ALWAYS list components with variant and size from design-system-base
10. The Visual Prompt section must be SELF-CONTAINED — pasteable to Stitch/v0 without any other file
11. Skip UI prompts section entirely for backend-only projects (no frontend stack)
12. For dashboard/admin pages: include data table layout, filters, pagination
13. For forms: include validation rules per field, error messages, success flow
14. ALWAYS respect `prefers-reduced-motion` — note which animations to disable
