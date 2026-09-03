# Jarvis SQL Formatter 2026.903.1.5

A T-SQL formatter and IntelliSense for SQL Server Management Studio 21 and 22.

## Installing

Close SSMS, then from this folder:

    .\install.ps1

With more than one SSMS installed you are asked which to use; `-Version 22` or `-All`
answers in advance. Verify it afterwards with:

    .\check-registration.ps1

## Removing it

    .\uninstall.ps1

## Updating to this build over an older one

    .\update.ps1

## If the Jarvis menu does not appear

    .\doctor.ps1 -Log

## What is here

| file | what it is |
|---|---|
| Jarvis.SqlFormatter-2026.903.1.5.vsix | the extension |
| jsqlfmt-2026.903.1.5.zip | the command line formatter, for hooks and CI |
| install.ps1, uninstall.ps1, update.ps1 | what you run |
| check-registration.ps1, doctor.ps1 | for when something does not work |
| README.md | the full documentation |
| docs\ | the Jarvis Gold style and the IntelliSense design |
| samples\ | a messy script and its formatted twin, plus an IntelliSense walkthrough |
| SHA256SUMS.txt | checksums for everything above |

Built 2026-09-03.
