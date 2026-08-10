# Lesson Planner — Planning Document

**Status:** built and working — `index.html`, hosted from this repo. See [ROADMAP.md](ROADMAP.md) for what shipped.
**Last updated:** 2026-08-10

---

## 1. The problem being solved

Replacing an Excel-based lesson planner. In the spreadsheet, each tab is a week, columns are
days, rows are lesson components (Homework Due, Opener, Differentiation, Procedure, …).

Three specific failures:

1. **Inserting a day is manual and cascades.** Deciding "we need one more practice day before
   Friday's quiz" means hand-shifting every cell after it — and because each tab is a week, the
   shift crosses tab boundaries.
2. **Four separate curriculums means four separate sheets.** No unified view.
3. **No month view.** No way to see the shape of a semester.

The first one is the reason this app exists. Everything else is table stakes.

---

## 2. The core insight: sequence first, dates second

A lesson does **not** have a date. A lesson has a **position in an ordered list**.

Each course owns an ordered array of lessons. Separately, each course has schedule rules
(which weekdays it meets, at what times). The calendar owns holidays. Meeting dates are
*generated*:

```
meetingDates(course) = weekdays matching schedule rules
                     − holidays
                     − one-off cancellations
                     + one-off added sessions
```

Then lesson #0 lands on meeting date #0, lesson #1 on meeting date #1, and so on. The grid you
see on screen is a **projection**, not the stored truth.

**Why this is the whole ballgame:** inserting a day becomes a one-line array splice. Everything
after it re-projects onto later dates automatically. Deleting a day and closing the gap is the
same splice in reverse. A snow day is a new holiday, which shortens the meeting-date list, which
slides every subsequent lesson forward — for all four courses at once, each correctly, because
each course generates its own meeting dates.

The Excel pain was a symptom of storing lessons *by date*. Store them by *order* and the pain
is gone by construction.

### One consequence, accepted deliberately

Shifting moves **everything** after the insertion point, including quizzes and labs. Ben's call:

> "The quiz moved. If I wanted the other behavior I would just change the lessons."

So **no pinning / locking system in v1.** Planbook.com has one ("Lock Lesson to Date") and the
reason is instructive: their shift is a blind numeric nudge with no preview, so teachers *need*
locks as a defensive measure. If you can see the ripple before you commit it and undo it with
one keystroke, most of the motivation for locks evaporates. Build the preview, not the lock.

Revisit only if real use proves otherwise.

---

## 3. Settled decisions

| Decision | Value |
|---|---|
| Storage model | Sequence-first; dates are derived |
| Insert behavior | Ripple everything after forward by one **meeting** (not one calendar day) |
| Drop between two days | Insert here, push the rest forward |
| Drop onto a day | **Swap** the two days |
| Replace / overwrite | Menu only, never a drag gesture |
| Pinned lessons | Not in v1 |
| Rich text in cells | Yes — bold, italic, bullets, numbered lists |
| Row sets | Per course; each course defines its own |
| Users | Single user for now; coworker sharing is a stated future goal (see §9) |
| Platform | Web app, runs in a browser on one Mac and one Windows PC |

### Why swap and not replace on drop-onto

Replace destroys the target day's content. Swap loses nothing and is self-reversing — drag it
back and you're home. A mouse slip should never be able to wipe a day you spent twenty minutes
writing. Destructive operations stay in the menu, named in plain English, where you had to mean it.

---

## 4. The operation vocabulary

### "Delete a day" is three different commands

Excel conflates these, which is part of why it felt bad. Video editors keep them separate
(*lift* vs *extract*) and so does Planbook — because teachers genuinely need all three.

| Command | Meaning | Does the sequence shift? |
|---|---|---|
| **Clear this day** | The class met, but the plan is gone. Fire drill, assembly, surprise review. | No. Day stays as an empty meeting. |
| **Remove this day** | This meeting shouldn't exist in the plan at all. | Yes — everything after slides back one meeting. |
| **Cancel this meeting** | The class does not meet on this date at all (schedule exception). | Yes — the date leaves the meeting list. |

These must never share a button. Label them by *outcome*, not by mechanism: "Remove day & close
gap" beats "Shift future lessons?", which is ambiguous about direction.

### Menus by scope

Three menus, so the reach of an operation is obvious from where you invoked it. Each opens on
right-click *and* on a persistent ⋯ icon — Planbook ships exactly this dual entry point and
millions of teachers already have the muscle memory.

- **Day-header menu** → operations on the whole column: insert, remove, clear, duplicate, move, swap
- **Row-header menu** → operations on one row across a range of days (the "rows of days" ask)
- **Cell menu** → operations on a single cell

No incumbent has a row-scoped menu. Planbook's closest thing is "Extend Standards" — push one
field forward across future days without touching anything else — which teachers describe as a
daily time-saver. Generalizing that to *any row, any day range, {copy forward, shift, clear}*
is a place this app beats everything on the market.

### Drag rules

```
        Mon          Tue          Wed
   ┌──────────┐│┌──────────┐ ┌──────────┐
   │          │││          │ │▓▓▓▓▓▓▓▓▓▓│
   │  lesson  │││  lesson  │ │▓▓lesson▓▓│
   │          │││          │ │▓▓▓▓▓▓▓▓▓▓│
   └──────────┘│└──────────┘ └──────────┘
               ▲                   ▲
        insertion caret       whole card highlights
        = INSERT HERE,        = SWAP these two days
          push rest forward
```

The drop target must be **visually binary**: a thin caret in the gutter between columns, or the
entire day card lighting up. You know which operation will fire before you release the mouse.
This is precisely the ambiguity that causes accidental overwrites in shipping products.

---

## 5. Safety model

Derived directly from documented Planbook failures. Each rule below exists because its absence
caused a real teacher to lose real work.

1. **Preview before commit, not confirm after.** "Are you sure?" carries no information. A
   preview showing the quiz sliding from Oct 14 to Oct 15 does. On hover/drag, dim and offset
   the downstream days so you watch the schedule slide before committing.
2. **Undo is permanent, keyboard-bound, multi-level, and browsable.** ⌘Z / ⌘⇧Z. A toast may
   *announce* an undo but must never be the only way to reach it. Planbook's disappearing
   3-second toast is the single most-complained-about thing in the product.
3. **One ripple = one undo entry.** A 40-day shift undoes in one keystroke, and stays undoable
   after three subsequent edits.
4. **Nothing is ever silently destroyed.** Content pushed past the end of the year goes to a
   visible **overflow tail**, not the void. Planbook deleted it silently until complaints forced
   a warning in 2017.
5. **No operation may delete content you didn't point at.** This is why "bump backward N days"
   will not exist here. If you want to reclaim meetings, remove those days explicitly.
6. **Cross-class operations are one transaction.** Declaring a holiday ripples all four courses
   as a single undoable action, and reports a per-course digest of what moved.
7. **Escape cancels a drag mid-flight.** Three layers of recovery: Escape before commit, ⌘Z
   after, and the moved day stays highlighted so your eye knows where to look.

---

## 6. Data model sketch

```ts
type Id = string;          // nanoid
type IsoDate = string;     // "2026-09-08"

// ── A course you teach ───────────────────────────────────────────
interface Course {
  id: Id;
  name: string;                    // "AP Biology"
  color: string;                   // tab + accent color
  rows: RowDef[];                  // THIS course's row set
  schedule: ScheduleRule[];
  exceptions: ScheduleException[];
  lessons: Id[];                   // ORDERED — this array is the spine
}

interface RowDef {
  id: Id;
  label: string;                   // "Homework Due"
  order: number;
}

// ── When the course meets ────────────────────────────────────────
interface ScheduleRule {
  weekday: 0|1|2|3|4|5|6;
  startTime: string;               // "09:15"
  endTime: string;
  effectiveFrom?: IsoDate;         // schedules change at semester
  effectiveTo?: IsoDate;
}

type ScheduleException =
  | { kind: 'cancelled'; date: IsoDate; reason?: string }
  | { kind: 'added';     date: IsoDate; startTime: string; endTime: string }
  | { kind: 'retimed';   date: IsoDate; startTime: string; endTime: string };

// ── A lesson: content with a position, NOT a date ────────────────
interface Lesson {
  id: Id;
  cells: Record<Id, RichText>;     // keyed by RowDef.id
  tag?: { label: string; color: string };   // "Quiz", "Lab", "Test"
  note?: string;
}

type RichText = object;            // Tiptap / ProseMirror JSON

// ── The calendar: shared by all courses ──────────────────────────
interface Calendar {
  yearStart: IsoDate;
  yearEnd: IsoDate;
  holidays: Holiday[];
}

interface Holiday {
  id: Id;
  date: IsoDate;
  endDate?: IsoDate;               // for breaks
  reason: string;                  // "Thanksgiving Break" — the calendar explains its own gaps
}

// ── The file on disk ─────────────────────────────────────────────
interface PlannerFile {
  schemaVersion: number;
  revision: number;                // increments on every save
  lastWrittenBy: string;           // machine name — conflict detection
  lastWrittenAt: string;           // ISO timestamp
  calendar: Calendar;
  courses: Course[];
  lessons: Record<Id, Lesson>;
  overflow: Record<Id, Id[]>;      // courseId → lessons past year end. Never destroyed.
}
```

Every structural operation reduces to an array operation on `Course.lessons`:

| Operation | Implementation |
|---|---|
| Insert day | `lessons.splice(i, 0, newLessonId)` |
| Remove day (close gap) | `lessons.splice(i, 1)` |
| Clear day | wipe `Lesson.cells`, leave the id in place |
| Swap days | exchange two array positions |
| Ripple move | splice out at `from`, splice in at `to` — one atomic operation, one undo entry |

That is the entire shift engine. The simplicity is the point, and it's the evidence the data
model is right.

### Undo

Use `immer`'s `produceWithPatches`, which hands back inverse patches for free. One user
operation = one `{ forward, inverse }` pair on the stack, no matter how many days rippled.
Boring, correct, ~30 lines.

---

## 7. Stack

**One HTML file, vanilla JavaScript, no dependencies and no build step.**

The React + Vite + TypeScript plan that used to sit here was written before any code existed.
By the time it would have started, the sandbox had already passed everything it described — so
rebuilding would have cost weeks to arrive back at what already worked. Decided 2026-07-25:
the rebuild is off.

What the single file buys:

| | |
|---|---|
| No toolchain | There is no node on this machine and nothing to install |
| No build step | Edit the file, refresh the browser |
| Sharing *is* the file | Emailing one `.html` to a colleague is the whole coworker plan (§9) |
| Nothing to break | No dependency updates, no lockfile, no framework upgrade in year two |

The cost is that everything lives in one file — currently around 3,000 lines. If that stops
being comfortable, split into a few plain `.js` files beside the HTML. That still needs no build
step; it only gives up the emailable-single-file property.

Deliberately hand-rolled rather than pulled in:

- **Rich text** — `contenteditable` plus `document.execCommand`. Deprecated but universally
  working, and the alternative (Tiptap/ProseMirror) is a large dependency for bold and bullets.
  Paste is sanitised down to the tags the toolbar can produce, so Word and Google Docs can't
  inject styling.
- **Drag and drop** — pointer events with geometry-based targeting. Native HTML5 DnD was tried
  first and abandoned: `dragover`/`dragleave` fire per element, so crossing from a day header
  into one of its cells wiped the drop indicator mid-aim.
- **xlsx** — a store-only ZIP writer with hand-computed CRC-32, plus minimal OOXML. About 250
  lines against ~800 KB for SheetJS.

## 8. Storage, sync, and not losing a year of work

### Two layers

1. **A folder you choose**, ideally inside OneDrive. The app writes `planner.json` there on every
   change and keeps a dated copy in `backups/`. This is the real home.
2. **localStorage**, always written as a mirror. It costs nothing and means a folder going
   missing never loses the day's work.

```
Lesson Planner Data/
  planner.json
  backups/
    planner-2026-09-08.json      ← one per day, most recent 30 kept
    planner-2026-09-07.json
```

A *folder* rather than a single file, because a lone file handle can't write siblings — backups
would be impossible.

### How writes work

The directory handle is kept in IndexedDB so it survives restarts (localStorage can't hold one —
strings only). Saves are debounced about a second after the last change and go through
`createWritable()`, which stages to a swap file and swaps atomically on close, so a crash cannot
leave a half-written file.

### Two machines

OneDrive syncs the folder; use is sequential, one machine at a time. Every save stamps an
incrementing `revision` and a `lastWrittenBy` machine label.

If the file on disk is *behind* what this machine last wrote — the signature of OneDrive still
syncing — the app stops and asks, naming both revisions and which machine wrote each. It never
merges. Automatic merging is how a year of lesson plans gets quietly mangled.

### Browser support — resolved

`showDirectoryPicker` is **Chromium only**: Chrome and Edge, which covers the Mac and the PC.
Safari and Firefox fall back to localStorage, and the settings panel says so plainly. A warning
appears in the sub-bar once a backup is more than a week old, so the fallback path can't go
quietly stale.

One caveat still to confirm in real use: this page is opened straight off disk (`file://`), and a
browser may refuse folder access from that origin. The code handles the refusal and explains it,
falling back to Export. If it turns out to be blocked, the fix is to serve the folder over
`localhost` instead.

## 8b. The AI-readable copy

`planner.json` is normalised for the app: lessons in a flat map, cells keyed by row id, no dates
stored anywhere. That's the right shape for splicing an array and the wrong shape for a language
model, which would have to join three structures and still wouldn't know what day anything is on.

So there's a second, derived view — flattened, chronological, real class and row names, resolved
dates, plain text. It is written to `plans-readable.json` alongside every save, and available on
demand from **⋯ → Export for AI**.

It opens with a `_readme` block, which is the important part. An assistant that doesn't know
lessons are an ordered list will confidently tell you to add a day before the quiz without
mentioning that the quiz moves. The block states the model, spells out the consequences, and asks
for suggestions to be phrased against stable lesson *numbers* rather than dates.

The copy is deliberately **read-only**. Nothing imports it back. Name-matching a rewritten export
onto lesson ids is exactly the kind of silent, plausible-looking corruption §5 exists to prevent;
if round-tripping is ever wanted it should be an explicit, reviewable patch format, not a
re-import.

---

## 9. Answered

Recorded so they don't get relitigated.

**Schedule shape.** Not a rotating cycle. Each class meets a fixed set of weekdays, the same
every week — "there's one day a week I don't have each class." A one-off is marked **No Class**
on that date, which ripples that class forward exactly like a private holiday. The 6-day
rotating cycle originally built for this was removed; it came from a misreading.

**Terms and week numbers.** The school owns a default term structure — semester by default, with
whole-year, trimester and custom available — and any class can override it. Week numbers count
from the start of the current term, so the header reads `Week 3 · S2`. The default lives at
school level rather than per class because the All Classes view has no single class to ask, and
because in reality the school owns semester boundaries.

**Coworkers: share the tool, not the plans.** Each teacher runs their own copy with their own
data. No server, no accounts, no merge story. This is why the single emailable HTML file matters.

**Where a ripple stops.** It runs to the end of the sequence. Anything pushed past the class's
last day goes to a visible overflow tail and is never deleted.

**Row sets.** Per class, and freely duplicated across classes. Rows are keyed by id internally,
so cross-class copying matches them by *label* and reports anything the target has no row for
rather than dropping it silently.

**Pinned lessons: still not built.** "The quiz moved. If I wanted the other behaviour I would
just change the lessons." Preview and undo cover the real need.

---

See [ROADMAP.md](ROADMAP.md) for build order.
