---
name: workspace-page-ui-zoom
description: Applies ~80% page UI scale via CSS zoom on workspace surfaces (reports-v3, defect tracker, review shells). Use when adding a dense dashboard, matching reports-v3 density, or when the user asks for page-level zoom/scale without browser zoom.
---

# Workspace page UI zoom (~80%)

## Pattern

Shrink **all** text and layout under a wrapper using CSS **`zoom: 0.8`**, not `transform: scale()` on the whole page (avoids reflow math bugs for many cases; keeps clicks aligned in simple layouts).

Canonical rules live in **`apps/web/src/styles/globals.css`**:

```css
.reports-v3-ui-scale,
.defect-tracker-ui-scale {
  zoom: 0.8;
  position: relative;
  box-sizing: border-box;
  width: 100%;
  max-width: 100%;
  min-height: 125vh;
}
```

- **`position: relative`**: makes the zoomed container the offset parent for absolutely positioned descendants (non-portaled dropdowns). Without this, Floating UI calculates dropdown offsets relative to an ancestor **outside** the zoomed context, causing menus to shift left in Chromium.
- **`min-height: 125vh`**: compensated height so the page does not look vertically "short" after zoom (`0.8 × 125% ≈ 100%` of viewport feel).
- **`width` / `max-width`**: keep the zoomed box from overflowing horizontally.

## Adding a new surface

1. **Extend the selector** in `globals.css` with a new class (e.g. `.my-feature-ui-scale`) **or** reuse an existing class if the surface is the same product area.
2. Wrap the **body of the page** in `<div className="…-ui-scale w-full max-w-full">` (match existing call sites).

## Fixed / sticky chrome (reports-v3 lesson)

**Do not** put `zoom` on the **`position: fixed`** node itself for top tab bars if that breaks **sticky/stacking** in Chromium. Pattern from `reports-v3-dashboard.tsx`:

- Fixed **tab header** shell has **no** zoom; its **inner** flex row uses **`.reports-v3-tabbar-inner-ui-scale`** (`zoom: 0.8`, `position: relative`) so tabs match **`.reports-v3-ui-scale`** density.
- Spacer div reserves layout height for the fixed bar (**zoom-compensated** height).
- **Main content** sits **inside** `.reports-v3-ui-scale`.

If the page has no separate fixed header inside the feature, wrapping the **root** of the feature (e.g. defect tracker) is acceptable.

## Dropdowns, menus, and comboboxes (required with zoom)

Mantine **`Menu`** / **`Select`** (Combobox) defaults to **`withinPortal: true`** → overlays mount under **`document.body`** and Floating UI often uses **`position: fixed`**. An ancestor with non-`1` **`zoom`** breaks that pipeline in **Chromium**: dropdowns shift (e.g. far left of the trigger) and/or render at the wrong scale.

### Fix used in defect tracker

Shared helpers live in **`~/lib/defect-tracker/defect-dropdown-ui`**: **`DEFECT_TRACKER_ZOOMED_MENU_PROPS`**, **`DEFECT_TRACKER_ZOOMED_CLICK_HOVER_MENU_PROPS`** (menus that should dismiss when the pointer leaves), and **`DEFECT_TRACKER_ZOOMED_COMBOBOX_PROPS`**.

| Goal | Pattern |
|------|---------|
| **Zoomed container** | Must have **`position: relative`** so it becomes the offset parent for absolutely positioned dropdowns. Already set in the shared CSS class. |
| **Menus / filter dropdowns** | `withinPortal: false` + **`floatingStrategy: 'absolute'`** — spread **`DEFECT_TRACKER_ZOOMED_CLICK_HOVER_MENU_PROPS`** on page **`Menu`** roots (includes `trigger="click-hover"` so menus do not feel stuck open on pointer leave). Use **`DEFECT_TRACKER_ZOOMED_MENU_PROPS`** only on **`Menu.Sub`** where a full click-hover spread is unnecessary. |
| **Select under the same zoomed page** | `comboboxProps={DEFECT_TRACKER_ZOOMED_COMBOBOX_PROPS}`. |
| **Toolbar overflow** | Use **`overflow: visible`** on `.defect-toolbar-row` so non-portaled menus are not clipped. Do **not** mix `overflow-x: auto` with `overflow-y: visible` — CSS spec computes the visible axis as `auto` when the other axis is `auto`/`scroll`, creating a scroll container that clips dropdowns. |

**Do not** reuse zoomed **`comboboxProps`** for **`Select`** inside Mantine **`Drawer`** content that is portaled to **`body`** without the same `zoom` ancestor — use default Combobox / portal behavior there.

### What stays portaled on purpose

**`Drawer` / `Modal`** surfaces: use **default** overlays unless that surface also uses page-level `zoom` or transform-scale hacks; then match strategy to that layer only.

## Current call sites (grep anchors)

- `reports-v3-ui-scale`, `reports-v3-tabbar-inner-ui-scale`: `reports-v3-dashboard.tsx`; `reports-v3-ui-scale` also `review-shell.tsx` (reports v2 review-v6).
- `defect-tracker-ui-scale` + inline overlays: `projects/[projectId]/defects/page.tsx`, `defects/settings/page.tsx`, `create-defect-form.tsx`, `DefectDetailDrawerContent.tsx`.
- In-repo zoom/portal notes: `timesheet-period-picker.tsx`, `timesheet-v2-viewer.tsx`.

## Browser support

Comment in `globals.css`: Chromium, Safari, **Firefox 126+** (`zoom`).
