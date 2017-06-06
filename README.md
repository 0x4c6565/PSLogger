# powershell-logging-module
A logging module for PowerShell


## Importing Module

> Import-Module C:\Path\To\PSLogger.psm1


## Log Providers:

One or more log providers must be added into the logger before any logging will be possible.

The module has several pre-defined log providers, outlined below:

### FileLogProvider

This provider will log to a single log file, and can be added via ``Add-FileLogProvider``:

> Add-FileLogProvider [-LogName] [-LogPath] [-MinLevel] [-MessageFormat]

* ``LogName``: Name of logfile (Default: MyScript)
* ``LogPath``: Path of log file (Default: $Env:TEMP)
* ``MinLevel``: Minimum log level (Default: INFO)
* ``MessageFormat``: Format of logfile (Default: {{date}} - {{level}} - [{{stack}}] --> {{message}})

### Custom log provider

More log providers can be added via ``Add-LogProvider``:

> Add-LogProvider [-Invoke] [-MinLevel] [-MessageFormat] [-Parameters]

* ``Invoke``: A scriptblock with a parameter ``Message``, which will be invoked by the logger. ``Level`` and ``Parameters`` parameters will be passed also, if required
* ``MinLevel``: Minimum log level
* ``MessageFormat``: Format of logfile, with replaceable tokens e.g. ``{{date}} - {{message}}``
* ``Parameters`` (Optional): A hashtable of parameters which will be passed into Invoke


## Basic Usage

### Commands

> Write-LoggerTrace [-Messages]

> Write-LoggerDebug [-Messages]

> Write-LoggerInfo [-Messages]

> Write-LoggerWarn [-Messages]

> Write-LoggerError [-Messages]

> Write-LoggerFatal [-Messages] [-ExitCode]

### Aliases

Aliases are also defined for writing logs:

> ``Logger.Trace``

> ``Logger.Debug``

> ``Logger.Info``

> ``Logger.Warn``

> ``Logger.Error``

> ``Logger.Fatal``

### Examples

> Write-LoggerInfo "Testing log"

> Write-LoggerInfo "some information"

> "some more information" | Write-LoggerInfo

> "an error occurred","oops" | Write-LoggerError

> Write-LoggerTrace -Messages "down the rabbit hole","and back out again"