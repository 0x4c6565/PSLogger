# powershell-logging-module
Very basic logging module

Importing Module:


Import-Module C:\Path\To\PSLogger.psm1




Basic Usage:


"LOL" | Logger.Info

"nope","errorz" | Logger.Error

Logger.Trace -Messages "down the rabbit hole"




Configuration:


Set-Log [-LogName]  [-LogExtension]  [-LogLevel]  [-LogPath]  [-LogMessageFormat] 


LogName: Name of logfile (Default: MyScript)

LogExtension: Extension of logfile (Default: log)

LogLevel: Level of logging (Default: INFO)

LogPath: Path of log file (Default: $Env:TEMP)

LogMessageFormat: Format of logfile (Default: {{date}} - {{level}} - [{{stack}}] --> {{message}})



This is a very basic implementation, and has no advanced functionality such as log rotation
