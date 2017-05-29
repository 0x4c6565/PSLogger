# powershell-logging-module
A logging module for PowerShell


## Importing Module

> Import-Module C:\Path\To\PSLogger.psm1


## Log Providers:

One or more log providers must be added into the logger before any logging will be possible.

The module has one pre-defined log provider, FileLogProvider, which can be added via ``Add-FileLogProvider``:

> Add-FileLogProvider [-LogName] [-LogPath] [-Level] [-MessageFormat]

* ``LogName``: Name of logfile (Default: MyScript)
* ``LogPath``: Path of log file (Default: $Env:TEMP)
* ``Level``: Minimum log level (Default: INFO)
* ``MessageFormat``: Format of logfile (Default: {{date}} - {{level}} - [{{stack}}] --> {{message}})

More log providers can be added via ``Add-LogProvider``:

> Add-LogProvider [-ScriptBlock] [-Level] [-MessageFormat]

* ``ScriptBlock``: A scriptblock with a single parameter ``Message``, which will be invoked by the logger
* ``Level``: Minimum log level
* ``MessageFormat``: Format of logfile, with replaceable tokens e.g. ``{{date}} - {{message}}``


## Basic Usage

> Logger.Info "some information"

> "LOL" | Logger.Info

> "nope","errorz" | Logger.Error

> Logger.Trace -Messages "down the rabbit hole","and back out again"