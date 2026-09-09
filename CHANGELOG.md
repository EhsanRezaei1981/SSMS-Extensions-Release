# Changelog

Every released version, newest first.

Versions are date stamped: `yyyy.MMdd.<major>.<minor>`, so `2026.903.1.2` is the second release
of 3 September 2026. The day is one number because a VSIX version holds exactly four of them.

---

## Unreleased

**Changed**

- **The map always opens.** It used to refuse with a message box when there was no results grid,
  no spatial column, or nothing drawable in one. That was wrong twice over: the map is worth
  having for the address search on its own, and a box saying "no geometry here" leaves somebody
  nowhere to go next. The window now opens either way and says in its own pane what is missing
  and what to do about it.
- **One snippet setting, not two.** The options page had **Snippet file** and, below it, a
  read-only **Snippet file in use** showing the resolved path — two rows for one file, when the
  path is already in **Jarvis ▸ About ▸ Files**. Its real job was to reveal the case where the
  path you asked for could not be written to and the default was used instead, and it did that
  only by inviting you to notice the two rows disagreed. That fallback is now **stated in
  words** — in the Jarvis output pane when it happens and in the About box, naming the path it
  could not use, the way the query history has always reported the same thing. The store had
  recorded the fact from the beginning and nothing ever read it; the comment beside it claimed
  the About box mentioned it, and the About box did not.
- **Jarvis Gold is the default style profile**, in place of Jarvis Standard. It is the column
  aligned river style this formatter was built to produce, so it is what a fresh install should
  do without anybody going to look for it. Set in all three places that decide the profile —
  the General page, the fallback used before the options pages have loaded, and the About box —
  because a format done early in a session coming out in a different style from one done a
  minute later is the sort of thing nobody would think to report.
  **A profile you have already chosen is untouched**; this only changes what happens where
  nothing was picked. The command line tool is unaffected and still defaults to Standard, since
  scripts depend on its output not changing under them: pass `--style "Jarvis Gold"` there.
- **No API key now draws OpenStreetMap instead of a notice.** A provider chosen without its key
  used to replace the map with a page explaining where to put one — so the first thing a new user
  saw was a page about API keys, and their geometry went undrawn. OpenStreetMap needs no key, so
  that is what it draws. The provider list moves with it, because a box naming TomTom over
  OpenStreetMap tiles is its own kind of wrong, and the status line names the missing key on
  every draw rather than once at startup. The chosen provider is left set in the options, so
  entering a key later is all it takes. That page is gone.
- **Marketplace staging**, `build\marketplace.ps1`: stages the package, the icon and a listing
  overview, prints the form values, and uploads nothing. It reads the manifest out of the
  package rather than off disk and refuses to stage one that targets Visual Studio, that does not
  target SSMS, whose icon is not actually inside it, or whose metadata still names a company.
- **The extension manager's "Getting started" and "Release notes" links** now go to the README
  and the changelog in the release repository, and the tags include the spatial features —
  geometry, geography, spatial, map and WKT were missing, so nobody searching for them found it.
- **A logo.** A white J standing in a data platter, on a navy to teal badge. The old icon was a
  "SQL FORMATTER" wordmark over before-and-after code lines, which named a product that no longer
  exists — this is a toolkit now, not a formatter. Drawn from geometry at each size rather than
  shrunk from one large image, because a 16 pixel icon made by downscaling a 256 pixel one is
  mush; there is a 16 through 512 set, a preview for the extension manager, and a wide wordmark
  for the README and a marketplace listing.
- **"More info" points at the release repository** rather than a company site, which is where the
  README, the changelog and the downloads actually are.
- **A map that cannot open says so.** A failure while building the window was written to a debug
  trace, which goes nowhere in a released build — so the shortcut appeared to do nothing at all,
  while the output window went on reporting the shapes it had found. It now shows what went
  wrong.
- **The record list shows the column chosen as the label.** Picking a label column now relabels
  the ticks as well as the shapes, so the list reads the same as the map. Before a column is
  chosen it shows the first value in the row that says anything, which beats a list of bare
  numbers; where the chosen column is empty for a row, the tick shows nothing rather than
  falling back, since a fallback there looks like the wrong column was picked.

**Fixed**

- **It no longer installs itself into Visual Studio.** The manifest listed Visual Studio
  Community, Pro and Enterprise as targets, so VSIXInstaller offered Visual Studio alongside
  SSMS and had it ticked by default — the extension arrived in Visual Studio without anybody
  asking for it. Nothing in Jarvis is of any use there: every feature wants a SQL connection, a
  T-SQL editor or the SSMS results grid. The package now targets **SSMS only**.
  An existing copy in Visual Studio has to be removed there — Extensions, Manage Extensions —
  since this only stops it happening again.

- **The map opens on the screen SSMS is on.** It was appearing on the primary monitor regardless.
  The map runs on its own thread, so it has a Win32 owner but no WPF `Owner`, and
  `CenterOwner` with nothing to centre on falls back to the primary screen. It is now centred
  over the SSMS window in physical pixels — two monitors can be at different DPI, and the
  arithmetic that is right on one is wrong on the other — and clamped to that monitor's work
  area, so it cannot land off screen or under the taskbar.

- **A SELECT following another SELECT now gets its semicolon.** Two queries in a row — the
  everyday shape of an ad hoc script — left the first unterminated, because a `SELECT` was not
  treated as ending the statement before it. It could not simply be added to the list of
  keywords that start a statement: `INSERT INTO t SELECT`, `CREATE VIEW AS SELECT`,
  `UNION SELECT` and a subquery are all continuations, and terminating those would break the
  SQL. A `SELECT` now ends the previous statement only when that statement was itself a
  `SELECT` and it is not joined on by `UNION`, `EXCEPT`, `INTERSECT`, `AS`, a bracket, a comma
  or an operator.

**Added**

- **Ctrl+K, Ctrl+M** opens the map. Global scope rather than editor scope, unlike the other
  Ctrl+K bindings: the map is about the results grid, so the key has to work with the focus in
  the grid and not only in the editor.

- **Points built from pairs of ordinary number columns.** A great deal of spatial data never
  becomes a geometry column — it sits as two numbers per point, named in pairs. Jarvis now finds
  `START_X_LEFT` with `START_Y_LEFT`, `CENTER_X` with `CENTER_Y` and the like, and offers each as
  a point layer beside the real geometry columns, switched on with a tick like any other.
  Pairing is by name and exactly one token apart, so a left x never pairs with a right y — the
  mistake a looser rule makes. `X`/`Y`, `LON`/`LAT`, `LNG`/`LAT` and `LONGITUDE`/`LATITUDE` are
  understood as prefix or suffix, with underscores or in camel case, and each column is used
  once. **The values then have to agree**: both must parse as numbers inside coordinate range,
  so a `MIN_X`/`MIN_Y` pair holding prices matches by name and is thrown out rather than drawn
  in the Atlantic.

- **A country above the address search**, starting at the one this machine is set to, because
  somebody searching "Main Road" means the country they are in — searching the planet returns
  Nottinghamshire when Cape Town was wanted. **(anywhere)** clears it and searches the world.
  Each provider is asked its own way: TomTom `countrySet`, Google `components=country`,
  Nominatim `countrycodes`. Photon has no country parameter, so a larger page is fetched and
  filtered on the country code its results carry — which keeps the typing on Photon rather than
  on the service that asks not to be used for autocomplete.

**Fixed**

- **The chosen country settles which typed number is the latitude.** `-26.0558576, 27.9767704`
  and `27.9767704, -26.0558576` now reach the same place. Both numbers are legal latitudes, so
  no rule about ranges can separate them — but with South Africa selected, one ordering is in
  South Africa and the other is out in the Atlantic, and only one of those was meant. Jarvis
  takes whichever lands nearer the country and reports that it worked it out. The country's
  position is looked up once and kept, not on every keystroke.
  With **(anywhere)** selected there is nothing to reason from, so the pair is taken exactly as
  entered — first number as x, the order the providers themselves read — and the status line
  says so rather than pretending to certainty.

- **The wheel no longer zooms in jumps, and how far it zooms is now a setting.** A notch moved a
  whole level, and WebView2 reports large wheel deltas, so one flick could cross two or three
  levels at once. **Tools ▸ Options ▸ Jarvis ▸ Map ▸ Mouse wheel zoom** offers Stepped, Balanced
  and Smooth — named for how they feel rather than exposing the two numbers behind them — since
  it is a matter of taste and no fixed pair suits everybody. On Google the same thing needed
  fractional zoom turning on, which a raster map has off by default.

**Added**

- **Moving the map is animated.** Going to a search result, a coordinate, a country or a zoom to
  fit now flies rather than cuts. A map that jumps leaves you nowhere — the shapes you were
  looking at are gone with no sense of which way they went — and flying out, across and back in
  keeps the two places related. Leaflet has this built in; Google has nothing equivalent, so its
  move is interpolated frame by frame with an ease, which works only because fractional zoom is
  enabled.

- **As many dropped points as you like.** **Address here** and a typed coordinate used to
  replace the previous point, which made comparing two places impossible. Each is now kept, with
  its own popup and its own address. The right click menu offers **Remove this point** — the one
  nearest where you right clicked, so clicking a pin removes that pin rather than the newest —
  and **Remove all points** once there is more than one.

- **Each provider is sent a point in the order it expects**, from one function with each
  service's convention written down beside it: **latitude first** for TomTom, Azure Maps and
  Google, **longitude first** for MapTiler, whose path is GeoJSON order. Nominatim and Stadia
  Maps name their parameters, so there is nothing to get wrong there.
  The order a service wants for a point it is *given* is a different question from the order a
  geometry column stores its ordinates in — SQL writes x first, most of these services read
  latitude first — and both conventions are in play at once. That is why it lives in one place
  rather than at each call site.

**Added**

- **The layer panel can be dragged wider or narrower**, from the thin strip beside it. Dragging
  and collapsing are separate strips on purpose: one control doing both would turn an unsteady
  click into a resize nobody asked for. It is clamped at both ends — too narrow and its controls
  are unusable, too wide and the map it describes has nowhere to be — snaps shut below half the
  minimum, and a dragged width is remembered, so hiding and showing returns the panel to the
  size you chose.

- **The layer panel folds away**, from the narrow handle between it and the map, so a wide shape
  can have the whole window. It slides rather than snapping: the map grows into the space the
  panel leaves, and a map that resizes instantly gives no hint of where the panel went or that
  it can be brought back. The handle sits outside the panel so it is still there to press when
  the panel has gone, and the panel is clipped while it moves so its contents do not spill over
  the map.

- **Satellite imagery, switchable on the map.** The layers button at the top right of the map
  lists every background there is a key for — road and satellite together — so going from streets
  to imagery is one click rather than a trip through the provider list. Google keeps its own
  Map/Satellite buttons, being drawn by its own API rather than as tiles. Providers with no key
  are left out of the list instead of offered and then failing, and the button is not shown at
  all when there is only one background, since a switcher with nothing to switch to is furniture.
- **TomTom satellite** as an eighth entry, on the same key as TomTom's road map — the default
  provider can now show imagery without a second account.
- **Azure Maps, MapTiler and Stadia Maps** join TomTom, Google and OpenStreetMap, with **Azure
  Maps satellite** sharing the Azure key — imagery being what most spatial
  data wants behind it. Each brings its own address search and reverse geocoding, so one key
  covers the map and the searching, and each renders its required attribution.
  They all serve ordinary XYZ raster tiles, so they went through the existing Leaflet path with
  no new rendering code; only Google still needs one of its own. MapTiler and Stadia both answer
  GeoJSON, so one reader serves them and a fourth service in that shape would need nothing new.
  Keys are now read per provider in one place rather than passed into the map window, so
  switching provider inside the window picks up the right key.

- **An empty map opens on the selected country**, not on the whole world. Whoever opens a map
  with nothing to draw is about to look something up, and it is almost certainly in the country
  already chosen. Changing the country with nothing typed and nothing drawn moves the map there
  too. With the country cleared, the world view is the honest answer and is left alone.

- **One box for addresses and coordinates.** The separate "Go to x and y" field is gone: the
  search box takes either, and works out which from what is typed. Two numbers are a coordinate
  and anything else is an address — numbers cannot be mistaken for a street name, so the test is
  safe both ways and there is no switch to set. While typing, a coordinate is *offered* as a row
  rather than acted on: jumping the map on every keystroke of "28.0473" would move it four times
  before the number was finished. Enter, or picking the row, goes there.
- **A typed coordinate picked from the list now gets its address too.** Pressing Enter looked it
  up, but choosing the row from the list only moved the map — so it dropped a point and said
  nothing about where it was. Both routes now go through the same lookup, which is why only one
  of them had it.
- **The results list is drawn under the search box, not over the map.** As a popup it was
  positioned against the window rather than the pane and could end up floating in the middle of
  the map. It is now an overlay inside the pane, anchored to the top of everything below the
  search box — so it still takes no space and pushes nothing down, but it cannot be drawn
  anywhere else.
- **The results list opens against the search box rather than halfway down the pane.** Moving it
  off the popup put it in with the datasets, which are below the Zoom to fit button — so a match
  appeared under the button, clear of the box that had been typed into and on top of the "nothing
  to draw" note. The pane is now laid out in rows down to the search box with one stretching row
  beneath it, and the list is anchored to the top of that row: directly under the box, and with
  the row's height already settled, still unable to move anything.

- **The results float above the pane instead of pushing it down.** A match arriving used to
  shove the country, the coordinate box and every dataset down the pane, and pull them back up
  when it went — so the pane moved under the mouse while it was being read. The list is now a
  popup, which takes no space, and the address line under the box keeps its space rather than
  appearing and disappearing.
- **A tint per result set** behind each dataset block, so where one ends and the next begins is
  obvious. Very pale, and the first is left plain: with one result set a colour would mean
  nothing, and it must not compete with the colours on the shapes, which do.

- **Latitude and longitude are shown with their x and y named** — "lat -26.2041 (y), long
  28.0473 (x)" — in the status line, the coordinate box and the right click menu. Those two
  namings are the commonest way to get a coordinate the wrong way round, and a window that deals
  in both should say which it means.
- **Go to x and y looks up the address as well**, showing it under the box and in the marker's
  popup: somebody typing a coordinate out of a query usually wants to know where it is.
- **Address here marks the point** and writes the answer into its popup, so it sits beside the
  place it describes instead of only on the status line.

- **Go to x and y**, taking the pair **either way round**. A number past 90 can only be a
  longitude, so most real coordinates sort themselves out whichever order they were typed;
  where both are within 90 the **Coordinates are longitude first** setting decides and the
  status line says which way round it read them, so a point that lands oddly can be explained.
  Comma, space, tab or semicolon separate the pair, and the parsing is invariant so a machine
  set to a comma decimal separator reads it the same.

- **Remove the point** in the right click menu takes away the marker left by a typed coordinate
  or by **Address here**, and clears the address under the search box with it. It is shown only
  when there is a point to remove — a row that does nothing is worse than no row — which the
  menu now supports generally: an item can say when it applies.

- **A right click menu on the map**: copy the coordinates in either order, look up the address,
  or centre the map there. Both orders are offered because both are wanted — latitude first for
  a map site, longitude first for a `geometry::Point`. The items are a list in one place, so
  another can be added later as a label and what it does rather than any new plumbing. The
  browser's own menu is suppressed so only this one appears, and it is kept inside the window so
  a right click near an edge cannot open a menu half of which is unreachable.

- **The address under a shape.** A shape's popup has an **Address here** button that reverse
  geocodes the exact point clicked — not the shape's centre, which for a long road is nowhere
  near where you were looking. Whichever provider draws the map does the lookup, so the key
  already entered is the only one needed; OpenStreetMap uses Nominatim, which permits a reverse
  lookup unlike the autocomplete it asks callers not to do.
  Asked for rather than fetched on opening: a click is not a request to call somebody else's
  geocoder, and on a paid key a popup that queried the internet every time would be a bill. One
  point at a time, never in a loop over a result set.

- **A dataset is now the result set, with its geometry columns as a multi-select inside it.**
  Each geometry column was becoming a dataset of its own, so a query selecting a shape, its
  centroid and its two end points showed as four datasets that each claimed the same two shapes
  — the same rows counted four times. It is now one dataset per result set, with a tick per
  geometry column deciding which are drawn, and **only the first is drawn to begin with**:
  several geometries per row piled on top of each other is unreadable.
  **Swap lat/long** and **Label** now apply to the whole dataset, since every geometry column of
  one row set was written the same way round and describes the same rows, and a **record** is a
  row — switching it off removes it from every geometry column at once. Zoom now frames what is
  actually visible rather than every column including the hidden ones.

- **Shapes can be labelled with a column of your choosing.** Each layer has a **Label**
  dropdown listing its own columns; pick one and every shape is captioned with that value, the
  way SSMS's own Spatial results tab labels its polygons. Per layer, because two layers rarely
  share a column worth showing. The values were already sent with the geometry, so it asks the
  server nothing. Labels are drawn with a white halo and no box, since a bubble on every polygon
  would hide the thing being labelled; a label goes and returns with its record, and survives a
  swap of lat/long or a change of provider.

- **Every record on the map can be switched on and off.** **Records** under each layer lists its
  shapes with their number, their colour and the first identifying value from their row; any one
  can be hidden without disturbing the rest, and **All on** / **All off** does the lot. What is
  switched off **stays** off through a swap of lat/long or a change of map provider, instead of
  quietly reappearing when the layer is rebuilt.
  The list is built when first opened, so a large layer costs nothing until it is wanted, and it
  lists the first 500 — beyond that the ticks are no longer something anybody scrolls. Records
  past the limit stay on the map and the pane says so, rather than appearing to have been lost.

- **About carries a link to the releases page**, the same address Check for Updates asks, so the
  two can never disagree about where downloads live. It opens in the browser; a URL somebody has
  to retype is a URL nobody follows.

- **The star says it can be expanded.** With the caret after a `*`, a small note appears beside
  it — "Tab to expand 14 columns" — because the feature was there and invisible: nothing in the
  editor suggested Tab would do anything, so only somebody who already knew ever used it. It
  appears **only where it is true**, asking the expander about that particular star rather than
  guessing from the character, so it never shows on a multiplication, outside a `SELECT` list,
  or on a table that has not been read. It takes no focus and handles no keys — Tab works
  exactly as before — and it stays away entirely when **Expand \* to columns on Tab** is off.
  Its own switch is **Tools ▸ Options ▸ Jarvis ▸ IntelliSense ▸ Show the Tab hint beside a ***.

- **What you picked last comes up first in the completion list.** The last 30 choices are
  remembered and floated to the top, because working against a database you know means reaching
  for the same few tables repeatedly. It promotes **within a group, never across one** — a
  recently used table must not jump above the columns of the table you are listing right now —
  and everything else keeps exactly the order the filter gave it. Shared across query windows,
  since the tables somebody is working on are the same across their open tabs.

- **Hover a name to see what it holds, in a grid you can copy from.** Resting the mouse on a
  table or view shows its columns in a real table — number, name, type, nullability and whether
  it is an identity, computed or defaulted — the facts that decide how an `INSERT` has to be
  written. A procedure or function shows its parameters, with a direction column marking
  `OUTPUT`.
  **It is a panel rather than a tooltip**: it stays open when you move onto it, rows can be
  selected with click, Ctrl+click and Shift+click, and **Ctrl+C** takes them. **Copy names**
  gives a comma separated column list for a `SELECT`; **Copy rows** gives the grid tab separated,
  so it arrives in a spreadsheet as columns. With nothing selected both copy everything. Escape,
  a click elsewhere or typing closes it.
  It reads the catalogue Jarvis already holds and **never asks the server** — hovering cannot set
  a query going, so a database that has not been read yet simply shows nothing. Off under
  **Tools ▸ Options ▸ Jarvis ▸ IntelliSense ▸ Describe a name when I hover on it**.

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
