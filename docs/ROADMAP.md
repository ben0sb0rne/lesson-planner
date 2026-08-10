# Lesson Planner — Roadmap

Build order and scope per version. See [PLANNING.md](PLANNING.md) for the design rationale.

Each rung is meant to be *usable* on its own. Time estimates are evenings of focused work for
one person, and should be read as rough.

---

## Shipped — `sandbox/index.html`

One self-contained file, no build step, no toolchain. Double-click it.

The React + Vite rebuild that used to head this roadmap is **cancelled** (2026-07-25) — the
sandbox had already passed everything it described, so it would only have cost weeks to get back
to working software. Rationale in [PLANNING.md §7](PLANNING.md).

### The move system — the reason this exists
Insert · remove & close gap · clear · duplicate · swap · ripple-move, all as one undo entry each.
Drag with a binary drop target: insertion caret between days, whole-card highlight on a day.
Escape cancels mid-drag. Right-click and ⋯ menus on days and cells.
Multi-level undo/redo (⌘Z / ⌘⇧Z) — a 40-day ripple undoes in one press.

### The calendar
Fixed weekly meeting pattern per class. **No Class** as a per-class exception that ripples like a
private holiday. Global holidays that ripple every class at once, as a single undoable action.
Per-class start and end dates. Overflow tail for anything pushed past a class's last day —
visible, never deleted.

**Terms** — school-level default (semester, whole year, trimester, custom) with a per-class
override. Week numbers count from the current term: `Week 3 · S2`.

### Views
Day · Week · Month · All Classes, each in single-class and all-class form. Date ranges in the
header (`Aug 31 – Sep 4, 2026`). Today hides itself when pressing it wouldn't move anything.

### Editing
Rich text cells — bold, italic, bullets, numbers. Paste sanitised to those tags, so Word and
Google Docs can't inject styling. Per-class row sets, drag to reorder, rename in place.
Tab walks down a day then on to the next; ⌥← / ⌥→ move sideways to the same box.

### Getting things in and out
- **xlsx export** — pick a date range and which classes; one sheet each, days as columns, your
  rows down the side. Tag colours, frozen panes, wrapped text, bullets preserved. Hand-rolled
  ZIP + OOXML, no library.
- **JSON export / import** — the manual backup.
- **Folder storage** — choose a folder (put it in OneDrive), and it saves there automatically
  with a dated backup a day, keeping 30. Conflict detection by revision; it asks rather than
  merging. localStorage stays a mirror. See [PLANNING.md §8](PLANNING.md).

### Getting around
⌘K search across every class, by lesson title or cell text. Shift-click day headers to select a
run and tag them all at once. Right-click a day → *Copy this day to* another class, matching rows
by name and naming anything the target has no row for.

### Not built, on purpose
Ripple **preview** (undo covers it and it hasn't been missed) · row-range operations · pinned
lessons · year rollover · print CSS.

---

## Before it carries a real year

Small, and worth doing before September rather than during it.

- [ ] **Confirm folder storage works from `file://`.** Settings → *Choose a folder…*. If the
      browser blocks it, the fallback is to serve the folder over `localhost`, or lean on Export.
- [ ] **Open an exported .xlsx in Excel** and check it looks right to hand to someone.
- [ ] **Set the real school year, terms and holidays**, then the four classes and their days.
- [ ] Confirm the OneDrive round-trip: edit on the Mac, wait for sync, open on the PC.

---

## Next, once you've actually used it

Deliberately unscheduled — real use should decide the order, not this document.

- **Row-range operations** — shift or copy one row across a span of days, leaving the rest alone.
  The original "rows of days" ask, and nothing on the market does it.
- **Ripple preview** — downstream days dim and offset before you commit.
- **Print / sub plan** — a clean one-page day or week for a substitute. xlsx may already cover it.
- **Year rollover** — reuse a class's sequence against next year's calendar. Nearly free, because
  lessons carry no dates.
- **Unit labels** — name a span of lessons and see the boundaries in month view.

---

## Sharing with coworkers

Settled: **share the tool, not the plans.** Each teacher runs their own copy with their own data.
No server, no accounts, no merge story — which is exactly why it's one emailable file.

- [ ] A short "start here" note for someone who wasn't there when it was built
- [ ] Check the first-run flow makes sense with no sample data loaded

---

## Deferred / probably never

Kept here so the decisions aren't relitigated.

| Feature | Why not |
|---|---|
| Pinned / locked lessons | Ben's explicit call: "the quiz moved." Preview + undo covers the real need. Revisit only if use proves otherwise. |
| Non-consecutive multi-select (Mon + Wed + Fri) | Hard to define sensible ripple semantics; unclear real use. Wait for a concrete need. |
| Bump backward N days | Deletes content you didn't point at. Planbook's single worst data-loss bug. Remove days explicitly instead. |
| Real-time collaboration | Not a stated need even in the coworker scenario. |
| Gradebook, attendance, standards alignment, LMS integration | Out of scope. Adjacent products, not this one. |
| Mobile app | Not asked for. |

---

## Ben's feature additions

Space to add anything not captured above — no need to sort it, just get it down.

-
-
-
