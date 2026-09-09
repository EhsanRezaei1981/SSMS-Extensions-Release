# Jarvis

**A T-SQL toolkit for SQL Server Management Studio 21 and 22.** One **Jarvis** menu, seven things
you were doing by hand.

Free. No account, no telemetry, no connection of its own — it uses the one you are already
connected with.

---

## What it does

| | |
|---|---|
| **Format** | `Ctrl+K, Ctrl+D` lays a script out to your house style — and checks the result token by token before it touches your file |
| **IntelliSense** | completions that know your schema: tables, columns, procedures, functions, join predicates read off the foreign keys, aliases numbered for you |
| **Snippets** | a shortcut and Tab, from a file that is yours to edit |
| **Query history** | every query you run, searchable by text, server and date |
| **Export** | the results grid to a real `.xlsx`, or pipe-delimited CSV split into files that will actually open |
| **Map** | `Ctrl+K, Ctrl+M` draws geometry and geography columns on a real map |
| **F12** | the definition of the procedure under the caret, open and ready to change |

## The formatter cannot break your script

This is the part worth reading twice, because it is the reason to trust a formatter at all.

Every format is verified before it is applied. Jarvis tokenises the original and the formatted
text and compares them token by token; if a single token differs in anything but whitespace, the
format is **abandoned and your script is left exactly as it was**. A formatter that garbles one
procedure in a thousand is worse than no formatter, because you stop reading its output.

Comments, string literals, `GO` batch separators, unusual collations and dynamic SQL survive it.
You can also tell it to leave a region alone.

## Spatial columns on a map

Run a query with a `geometry` or `geography` column and press `Ctrl+K, Ctrl+M`. Points, lines,
polygons and the multi and collection forms of each, one layer per column, a colour per record,
and a label column you choose.

- **Eight map providers** — TomTom, Google, OpenStreetMap, Azure Maps, MapTiler, Stadia Maps, and
  satellite imagery from TomTom and Azure. Switchable on the map itself.
- **Address search and reverse geocoding** — confined to one country, or the whole world.
- **Coordinates either way round.** SQL Server stores `geometry` and `geography` opposite ways
  and the grid does not say which you have. Jarvis works it out from the values, and where the
  numbers genuinely cannot settle it, one tick per layer corrects it.
- **Text and number columns too** — a WKT string column, or a pair of X and Y columns, are drawn
  as readily as a real spatial type.

Curved geometry is reported as skipped rather than approximated. There is no GeoJSON for a curve,
and drawing a guess would put something on the map the database never said.

## Requirements

- **SSMS 21 or 22** (x64 or Arm64). SSMS 18 and 19 are not supported — they bind their shell
  assemblies at versions this cannot load.
- Nothing else. No runtime to install, no service, no account.

## Install

Download the `.vsix` from the [latest release][latest] and double-click it, or run
`install.ps1` from the same release for an unattended install. Close SSMS first — a running
instance blocks the installer.

Everything is documented in the [README][readme], and every change in the [changelog][changelog].

[latest]: https://github.com/EhsanRezaei1981/SSMS-Extensions-Release/releases/latest
[readme]: https://github.com/EhsanRezaei1981/SSMS-Extensions-Release/blob/main/README.md
[changelog]: https://github.com/EhsanRezaei1981/SSMS-Extensions-Release/blob/main/CHANGELOG.md
