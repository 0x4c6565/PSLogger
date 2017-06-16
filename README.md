# powershell-logging-module
A logging module for PowerShell


## Importing Module

> Import-Module C:\Path\To\PSLogger.psm1


## Log Targets:

One or more log targets must be added into the logger before any logging will be possible.

The module has several pre-defined log targets, outlined below:

### FileLoggerTarget

This target will log to a single log file, and can be added via ``Add-FileLoggerTarget``:

> Add-FileLoggerTarget [-Name] [-LogPath] [-MinLevel] [-MessageFormat]

* ``Name``: A unique name for the target
* ``LogPath``: (Optional) Path of log file (Default: $Env:TEMP\{Name}.log)
* ``MinLevel``: (Optional) Minimum log level (Default: INFO)
* ``MessageFormat``: (Optional) Format of logfile (Default: {{date}} - {{level}} - [{{stack}}] --> {{message}})
* ``Passive``: (Optional) Specifies that target should be passive - target must be explicitly targeted

### Custom target

More log targets can be added via ``Add-LoggerTarget``:

> Add-LoggerTarget [-Name] [-Invoke] [-MinLevel] [-MessageFormat] [-Passive] [-Parameters]

* ``Name``: A unique name for the target
* ``Invoke``: A scriptblock with a parameter ``Message``, which will be invoked by the logger. ``Level`` and ``Parameters`` parameters will be passed also, if available
* ``MinLevel``: Minimum log level
* ``MessageFormat``: Format of logfile, with replaceable tokens e.g. ``{{date}} - {{message}}``
* ``Passive``: (Optional) Specifies that target should be passive - target must be explicitly targeted
* ``Parameters`` (Optional): A hashtable of parameters which will be passed into Invoke


## Basic Usage

### Commands

> Write-LoggerTrace [-Message]

> Write-LoggerDebug [-Message]

> Write-LoggerInfo [-Message]

> Write-LoggerWarn [-Message]

> Write-LoggerError [-Message]

> Write-LoggerFatal [-Message] [-ExitCode]

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

> "an error occurred","oops" | Write-LoggerError