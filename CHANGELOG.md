# Changelog

Every released version, newest first.

Versions are date stamped: `yyyy.MMdd.<major>.<minor>`, so `2026.903.1.2` is the second release
of 3 September 2026. The day is one number because a VSIX version holds exactly four of them.

---

## Unreleased

**Added**

- **Every result set is mapped, not only the one in focus.** A batch that returns several sets
  stacks a grid for each; all of them are now read, and their layers are labelled
  `Result 2 · VectorData` so two sets carrying a column of the same name do not appear as two
  identical rows in the pane.

**Changed**

- **Each record is drawn in its own colour** rather than one colour per column, which had
  everything on the map the same blue. The colour comes from the row number, stepping the hue by
  the golden angle so consecutive rows are always far apart — a thousand rows produce well over
  seven hundred distinct colours, which a fixed palette cannot. Layers each start from a
  different point, so two layers still read as two layers. The swatch in the pane is a strip of
  the layer's real colours instead of a solid block that matched nothing on the map.

- **Spatial columns already converted to text are mapped too.** A column run through `STAsText`,
  a view that does the conversion, or a `varchar` somebody keeps shapes in — all of them draw,
  alongside the binary the grid normally shows. PostGIS's `SRID=4326;POINT (...)` form is read as
  well, including its SRID. Text needs no decoding and no spatial assembly, so it works even
  where the binary route cannot, and the message when nothing is found now says so instead of
  claiming `STAsText` columns are not recognised.
- A column is only treated as spatial when its values actually parse, so a text column holding
  the bare word `POINT` is left alone rather than becoming a layer of nothing.

## 2026.903.3.5

**Changed**

- **The address search completes as you type.** Matches appear after a short pause in typing
  rather than on Enter — three letters is enough — and Enter still works. It waits for the pause
  instead of firing per keystroke, so "Sandton City" is one look-up rather than twelve, and an
  answer that arrives after a newer one is dropped rather than flickering the list back to
  results for half a word.
- On **OpenStreetMap** the typing goes to Photon rather than Nominatim. Nominatim's usage policy
  names autocomplete as a use it does not allow; Photon is the same OpenStreetMap data from a
  service built for typing into. Pressing Enter still uses Nominatim. TomTom is asked in
  typeahead mode, which is what its Search API is for.

## 2026.903.3.4

**Fixed**

- **Delete, Home, End and the arrow keys work in the map's search box.** The map opened on
  SSMS's own UI thread, so the shell's message loop pre-translated those keys into editor
  commands before the text box ever saw them — it was not ignoring them, it was never told. The
  map now runs on its own thread with its own message loop, and SSMS is made its owner by window
  handle instead, so it still floats above SSMS and minimises with it. It no longer blocks SSMS
  while open either.

**Changed**

- The search is one rounded field with the magnifier inside it and a clear cross, rather than a
  labelled box beside a Go button, and each result is shown on two lines — the name, then the
  rest of the address in grey. Geocoders answer with one long comma separated line, which at the
  width of the pane made every result look the same. Escape clears the search and its marker.

## 2026.903.3.3

**Fixed**

- **Coordinates are read longitude first**, which is how geometry columns are actually
  populated. The previous build read every value as geography first and trusted a validity
  check to catch the difference — but a Johannesburg point stored as `(28.05, -26.20)` reads as
  latitude 28.05, longitude -26.20, which is perfectly valid and puts it in the Indian Ocean.
  Values are now read exactly as stored and the order is worked out from them: a coordinate past
  90 can only be a longitude, so those settle themselves whatever the setting says. Where the
  numbers cannot settle it, **Tools ▸ Options ▸ Jarvis ▸ Map ▸ Coordinates are longitude first**
  decides, and each layer's swap tick shows what was assumed rather than hiding it.
- Self intersecting polygons are drawn instead of skipped. Validity was being used to tell
  geography from geometry, and `STIsValid` rejects them — so ordinary rows the grid was happily
  showing quietly never appeared.

**Added**

- **Address search on the map.** Type an address, press Enter, pick from the matches and the map
  goes there and marks it. The provider drawing the map does the searching — TomTom, Google or
  OpenStreetMap's Nominatim — so the key already entered for the map is the only one needed.
  It searches on Enter rather than as you type, because every keystroke would be a request to
  somebody else's service.

## 2026.903.3.2

**Changed**

- **Jarvis IntelliSense is on from a fresh install.** It was off, on the reasoning that an
  extension should not switch somebody's IntelliSense off uninvited — but the point of
  installing Jarvis is to use it, and a feature nobody finds is a feature that does not exist.
  SSMS's own IntelliSense is switched off while it is on, so only one list ever appears, and
  turning Jarvis IntelliSense off puts SSMS's back exactly as it was. An existing install keeps
  whatever you had chosen; only a machine with no Jarvis setting yet gets the new default.

## 2026.903.3.1

**Added**

- **Geometry on a map.** **Jarvis ▸ Results ▸ Show on Map...** draws the spatial columns of the
  results grid — points, lines and polygons, and the multi and collection forms of each — on a
  real map with pan and zoom. It reads the grid you are already looking at, so nothing is
  queried twice, and a selection maps just that selection.
- **A layer pane beside the map.** Every geometry column becomes its own layer with its own
  colour, a tick to switch it off, its shape count, its SRID, and a **zoom to fit**. Clicking a
  shape shows the rest of its row.
- **The map is yours to choose.** TomTom by default, Google or OpenStreetMap on the window
  itself. TomTom and Google need your own API key — **Tools ▸ Options ▸ Jarvis ▸ Map** — and
  without one Jarvis says so and offers OpenStreetMap, which needs none, rather than showing an
  empty window. Google is drawn through its own API because its terms do not allow its tiles
  in another map library.
- **A swap lat/long tick per layer.** SQL Server stores `geometry` and `geography` coordinates
  the opposite way round and the grid does not say which a column is — the same bytes read one
  way give `POINT (28.05 -26.20)` and the other `POINT (-26.20 28.05)`. Jarvis reads geography
  first and checks it is valid, which rejects planar coordinates, but where the guess is wrong
  the fix is one tick rather than shapes silently in the wrong hemisphere.
- Curved geometry — `CIRCULARSTRING`, `COMPOUNDCURVE`, `CURVEPOLYGON` — is **counted and
  reported, never approximated**: there is no GeoJSON for a curve, and drawing a guess would put
  something on the map the database did not say.

## 2026.903.2.3

Same extension as 2026.903.2.2. What changed is the release itself, which that version got wrong.

**Fixed**

- **The download links work.** 2026.903.2.2 was pushed as a tag with no GitHub Release behind it,
  so every `releases/download/...` link in the README answered 404 — the bundle, the `.vsix` and
  the permanent latest link alike. Publishing now **refuses** to push when it cannot create a
  Release, rather than publishing a page telling people to fetch files that are not there.
- **The README no longer links to the source repository.** It is not public, so that link was a
  404 for every visitor and pointed at a private repository besides. It is now behind a switch
  that is off, and turning it on makes the publish check anonymously that the repository really
  is public before it will go ahead.

## 2026.903.2.2

**Added**

- **Update checking.** Jarvis asks the public release page whether a newer version has been
  published, **every time SSMS starts**, and tells you when there is one — showing the version
  and what changed. **Nothing is ever downloaded or installed without you choosing it**: the
  notice has Download, Release page, Skip this version and Remind me later, and closing it means
  later. Installing still needs SSMS closed, because VSIXInstaller refuses to run while it is
  open, and the notice says so rather than starting something that fails afterwards.
- **Jarvis ▸ Updates ▸ Check for Updates...** does the same on demand, and unlike the automatic
  check it also says when you are already up to date.
- **Jarvis ▸ Updates ▸ Check Automatically**, and **Tools ▸ Options ▸ Jarvis ▸ Updates ▸ Check
  for updates automatically**, turn the startup check on and off. The tick box on the notice
  itself is the same setting, so it can be turned off from the thing that is interrupting you.
- The check is anonymous, sends nothing about you or your servers, runs off the UI thread and
  never delays SSMS starting. No network, a proxy that refuses, or a repository with no releases
  all mean "no news" — silent, never an error. It also reads plain **tags** when a version was
  tagged without a Release attached, so it still works before Release pages exist.

## 2026.903.2.1

The major goes to 2 because this renames everything the code calls itself.

**Changed**

- **`Jarvis.SqlFormatter` is now `Jarvis.SSMSExtension`** throughout: namespaces, assemblies,
  project and folder names, the solution, and the package class (`JarvisSqlFormatterPackage` is
  now `JarvisSsmsExtensionPackage`). The shipped assemblies are `Jarvis.SSMSExtension.Core.dll`
  and `Jarvis.SSMSExtension.Vsix.dll`. Names that genuinely mean the formatter — the
  `Jarvis ▸ SQL Formatter` menu, `FormattingService`, the `jsqlfmt` CLI — are unchanged, because
  those really are about formatting.

**Upgrading from 2026.903.1.11 or earlier**

- The **VSIX identity changed with the name**, so the shell sees a new extension rather than an
  upgrade and will not replace the old one on its own. Both register the same package GUID, so
  two installs at once means a Jarvis menu that misbehaves, not two versions side by side.
  `install.ps1` now removes a pre-rename copy before installing, `uninstall.ps1` and
  **Jarvis ▸ Uninstall Jarvis...** remove either, and `check-registration.ps1` reports one if it
  finds it left behind.
- **Nothing of yours moves.** Snippets and query history stay in `%APPDATA%\Jarvis\`, and your
  Options are keyed on the package GUID, which has not changed.

## 2026.903.1.11

**Added**

- **Jarvis ▸ Uninstall Jarvis...** removes the extension without leaving SSMS, through the
  shell's own extension manager, so it goes the same way Extensions, Manage Extensions,
  Uninstall would take it: marked now, gone on the next restart. **The snippet file and the
  query history are kept**, and the confirmation names both paths rather than just promising
  it. If the shell will not do it — a per machine install needs administrator rights — it says
  so and points at `uninstall.ps1` instead of failing quietly.

## 2026.903.1.10

**Changed**

- **Options...** now sits directly under **Jarvis** instead of inside **Jarvis ▸ SQL Formatter**.
  It stopped being formatter-only some time ago — it holds the IntelliSense settings and the
  snippet and history file paths as well — so hiding it under the formatter sub menu was
  misleading. The command is now `Jarvis.Options` rather than `Jarvis.FormatterOptions`.

## 2026.903.1.9

**Added**

- **Jarvis > Licence...** shows the terms, read from the LICENSE.txt inside the installed
  extension rather than from a copy in the code, so the menu can never say something the package
  does not. It leads with the two lines that matter: free to use, including at work; not to be
  sold.

## 2026.903.1.8

**Changed**

- **The licence is no longer MIT.** It is still free to use for anything, including commercially,
  and free to pass on unmodified — but it may no longer be sold, charged for, or included in
  anything that is sold. The no-warranty terms are unchanged, and the terms are summarised in the
  README as well as in `LICENSE.txt`.

## 2026.903.1.7

**Changed**

- The package is now **Jarvis SSMS Extension**. The name says what it is and where it runs; the
  menu, the Options page and the output pane are still just **Jarvis**.

## 2026.903.1.6

**Supersedes 2026.903.1.5**, whose `install.ps1` could not install anything. If you downloaded
that one, take this instead.

**Fixed**

- `install.ps1` could not find the package when run from the release repository. It looked for a
  `.vsix` beside itself, but a release keeps packages under `releases/<version>/` so older ones
  stay downloadable — so a fresh download reported "No .vsix found". It now searches there too
  and picks the newest, ordered by parsed version rather than by name.

## 2026.903.1.4

**Changed**

- **About** is a real window instead of a message box. The shell's box silently truncates a long
  body, so everything below the first heading was being cut off with no sign it was missing.
- About now reports **what Jarvis is doing right now** — active style, terminators, format on
  save, IntelliSense, the connected database, what the catalogue holds, whether the history is
  recording — rather than reciting features. Values are selectable and there is a **Copy
  details** button, because that is what belongs in a bug report.
- One version shown, not two. The build stamp said the same thing as the date stamped version.

## 2026.903.1.2

**Added**

- The **snippet file** and the **query history file** each get a **...** button in Options,
  opening a file dialog on wherever the setting currently resolves to.

**Changed**

- The extension is now **Jarvis for SSMS** rather than Jarvis SQL Formatter — it has not been
  only a formatter for some time. The Options page, the output pane and the status messages all
  say Jarvis.
- Snippets moved from `%APPDATA%\Jarvis SQL Formatter\` to `%APPDATA%\Jarvis\`, beside the query
  history. **An existing snippet file is moved across automatically** the first time Jarvis looks
  for it; it is copied and then the original deleted, so a file that cannot be deleted still
  leaves the snippets readable.

## 2026.903.1.1

**Changed**

- README rewritten for what the product actually is, and corrected where it had drifted: it
  claimed three `sys.*` queries when there are four, and that only Jarvis Gold terminated
  statements when that is now a setting that holds across every style.

## 2026.902.1.8

**Fixed**

- The semicolon on a generated procedure call went on a line of its own. It now goes on the last
  parameter's line, after the value and **before** its comment — where a semicolon after the
  comment would be inside the comment and do nothing at all.

## 2026.902.1.7

**Fixed**

- **Procedure parameters were never written.** Committing a completion reset the session before
  building the call template, which cleared the catalogue it needed, so it silently produced
  nothing every time. Input parameters, OUTPUT declarations and the trailing SELECT all now
  appear as intended.

## 2026.902.1.6

**Added**

- **F12** is now Jarvis's own command with its own key binding. SSMS binds nothing to F12 in a
  query window, so hooking the shell's Go To Definition meant no command was ever dispatched and
  the key did nothing. Also on **Jarvis ▸ IntelliSense ▸ Go To Definition**, and it says on the
  status bar when it declines.

## 2026.902.1.5

**Fixed**

- Switching database left the first completion reporting "Reading `<database>`…" and offering
  nothing, because the catalogue loads on demand. Jarvis now notices the switch when the editor
  takes focus and starts reading straight away.

## 2026.902.1.4

**Changed**

- **Refresh Column Metadata** is now **Refresh Metadata** — it re-reads tables, columns, keys,
  procedures and parameters, not just columns — and has a shortcut, **Ctrl+K, Ctrl+R**.

## 2026.902.1.3

**Fixed**

- The completion list stayed open when switching between query tabs. Switching tabs does not
  deactivate SSMS, so nothing else noticed; the list now closes when its editor loses focus, and
  when the caret moves to another line.

## 2026.902.1.2

**Fixed**

- The completion list could appear outside SSMS, over the desktop, and followed you onto another
  virtual desktop. It was a top level window with no owner. SSMS now owns it, and it closes when
  SSMS stops being the active application.

## 2026.902.1.1

**Added**

- **Date stamped versions.** `publish.ps1 -Date -Major 1` produces `yyyy.MMdd.<major>.<minor>`
  and works the minor out from what is already published.
- **Terminate statements with ;** in Options, on by default, holding whichever style is picked.

## 1.5.0

**Added**

- **Choosing a procedure writes the call**, not just the name: every parameter on its own line as
  a named argument, types shown, optional ones marked. **OUTPUT parameters** bring their `DECLARE`
  lines above and a `SELECT` below, since a call that omits the keyword fails silently and one
  naming an undeclared variable does not run at all.
- **F12** opens the definition of the procedure, function, view or trigger under the caret.
- Routine parameters are read into the catalogue, from a fourth `sys.*` query.

## 1.4.1

**Fixed**

- The IntelliSense list appeared far from the caret on a scaled display: the DPI came from
  `Application.Current.MainWindow`, which is often null in SSMS, and the fallback was wrong by
  exactly the scale factor. It now comes from the editor's own monitor, and the list is clamped
  to that monitor.
- **Snippets now win on Tab.** With the list open, `ssf` + Tab committed whatever the list had
  highlighted instead of expanding the snippet.

## 1.4.0

**Added**

- The **snippet file** can be moved — a shared folder for a team, or a repository.

**Changed**

- Options renamed from **Jarvis SQL Formatter** to **Jarvis**.

## 1.3.6

**Changed**

- The query history window opens about twice as tall, with wider columns.

## 1.3.5

**Fixed**

- **Open in editor** failed with `E_FAIL`. It called one command name that SSMS may not have and
  that is disabled while focus is in a tool window. It now hands focus back first, tries several
  names, and falls back to opening the query as a file, then the clipboard. It also verifies a
  new window actually opened before writing, so the query can never land in the middle of the
  script you already had open.
- Choosing a query now closes the history window.

## 1.3.4

**Added**

- The **query history file** can be moved, and falls back to the default when the path cannot be
  written to rather than silently dropping every query.

**Fixed**

- The history window failed to open at all with "Catastrophic failure": a tool window's content
  has to exist before the shell builds the frame around it.

## 1.3.3

**Fixed**

- The **Query** column in the history was always blank — it bound to a method rather than a
  property, which WPF renders as an empty cell without complaining.
- An empty history now says which kind of empty it is, rather than looking broken.

## 1.3.2

**Fixed**

- Splitting an export by size produced wildly uneven files — a 464 KB file next to a 41 MB one —
  because each file was planned by splitting the whole result set again, which moved every
  boundary. Files are now planned forward from where the export has reached, and each one is
  measured after it is written: anything over the limit is written again smaller, so the maximum
  is a real maximum.

**Changed**

- The size split is a single **maximum** rather than a minimum and maximum.

## 1.3.1

**Added**

- A long export runs on a **background thread** with a **progress window** and a **Cancel**
  button, instead of freezing SSMS.

**Fixed**

- `.xlsx` files came out about a fifth of the size asked for, because the split was planned from
  the uncompressed size and a workbook is a compressed zip.

## 1.3.0

**Added**

- **Every export asks how to split it**, because the answer depends on the result set: one file,
  a number of rows, or a maximum size. It shows the total size before you choose and what your
  choice will produce.

## 1.2.1

**Added**

- Exports split into files of 500,000 rows by default, for Excel and CSV alike. Every file
  carries the header row, and a worksheet is capped at Excel's own 1,048,575 row limit.

## 1.2.0

**Added**

- **Query history.** Every query you run is recorded with the server, database and time, and
  searchable by text, server and date range.

## 1.1.3

**Fixed**

- Exporting a large result set failed with "capacity was less than the current size". Both
  writers built the whole file as one string first; they now stream, so there is no size ceiling
  and half the peak memory.
- A trailing dot in the suggested file name, which Windows silently drops.

## 1.1.0

**Added**

- **Export the results grid** to a real `.xlsx` workbook or to pipe delimited CSV, from the
  grid's right click menu or **Jarvis ▸ Results**. Headers included, numbers written as numbers,
  and anything that only looks like a number — `007`, a leading zero phone number — kept as text.
