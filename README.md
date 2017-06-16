# PSLogger
A logging module for PowerShell


## Importing Module

> Import-Module C:\Path\To\PSLogger.psm1


## Log Targets:

One or more log targets must be added into the logger before any logging will be possible.

The module has several pre-defined log targets, each sharing the following common parameters:

* ``Name``: (Required) A unique name for the target
* ``MinLevel``: Minimum log level (Default: INFO)
* ``MessageFormat``: Format of log message (Default: {{date}} - {{level}} - [{{stack}}] --> {{message}})
* ``Passive``: Specifies that target should be passive - target must be explicitly targeted

### File Target

This target will log to a single log file

> Add-LoggerFileTarget [-Name] [-MinLevel] [-MessageFormat] [-Passive] [-LogPath]

* ``LogPath``: Path of log file (Default: $Env:TEMP\{Name}.log)

### Host Target

This target will output to host

> Add-LoggerHostTarget [-Name] [-MinLevel] [-MessageFormat] [-Passive]

### Custom target

More log targets can be added via ``Add-LoggerTarget``:

> Add-LoggerTarget [-Name] [-MinLevel] [-MessageFormat] [-Passive] [-Invoke] [-Parameters]

* ``Invoke``: (Required) A scriptblock with a parameter ``Message``, which will be invoked by the logger. ``Level`` and ``Parameters`` parameters will be passed also, if available
* ``Parameters`` A hashtable of parameters which will be passed into Invoke


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
