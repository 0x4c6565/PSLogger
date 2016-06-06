$Global:LogName = "MyScript"
$Global:LogExtension = "log"
$Global:LogLevel = "INFO"
$Global:LogPath = $env:TEMP
$Global:LogMessageFormat = "{{date}} - {{level}} - [{{stack}}] --> {{message}}"

$Global:LogLevels = @("TRACE","DEBUG","INFO","WARN","ERROR")

function Set-Log
{
    Param
    (
        [Parameter(Mandatory=$false)][string]$LogName,
        [Parameter(Mandatory=$false)][string]$LogExtension,
        [Parameter(Mandatory=$false)][string]$LogLevel,
        [Parameter(Mandatory=$false)][string]$LogPath,
        [Parameter(Mandatory=$false)][string]$LogMessageFormat
    )
    

    if ([string]::IsNullOrWhiteSpace($LogName) -eq $false)
    {
        $Global:LogName = $LogName
    }

    if ([string]::IsNullOrWhiteSpace($LogExtension) -eq $false)
    {
        $Global:LogExtension = $LogExtension
    }

    if ([string]::IsNullOrWhiteSpace($LogLevel) -eq $false)
    {
        if (($LogLevels -contains $LogLevel) -eq $false)
        {
            throw ("Invalid log level provided, valid values [{0}]" -f $LogLevels -join "; ")
        }
    }
    
    if ([string]::IsNullOrWhiteSpace($LogPath) -eq $false)
    {
        $Global:LogPath = $LogPath
    }
    
    if ([string]::IsNullOrWhiteSpace($LogMessageFormat) -eq $false)
    {
        $Global:LogMessageFormat = $LogMessageFormat
    }
}

function Logger.Log
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)][string]$Level,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        if ([array]::IndexOf($Global:LogLevels,$Global:LogLevel) -le [array]::IndexOf($Global:LogLevels,$Level))
        {
            foreach ($Message in $Messages)
            {
                $LogHash = @{
                    Level = $Level
                    Date = Get-Date
                    Stack = (Generate-Stack)
                    Message = $Message
                }

                $FormattedMessage = Format-Message -Message $Global:LogMessageFormat -LogHash $LogHash
                Add-Content -Path ("{0}.{1}" -f ([System.IO.Path]::Combine($Global:LogPath, $Global:LogName)), $Global:LogExtension) -Value $FormattedMessage
            }
        }
    }
}

function Generate-Stack
{
    $ScopeDepth = (Get-ScopeDepth -Offset 4)
    $ScopeArray = @("Script")        
    for ($i = 1; $i -lt $ScopeDepth; $i++)
    {
        $Invocation = (Get-Variable MyInvocation -Scope $i)
        $ScopeArray += "{0}({1})" -f $Invocation.Value.MyCommand, $Invocation.Value.ScriptLineNumber
    }

    return ($ScopeArray -join "::")
}

function Get-ScopeDepth
{
    Param
    (
        [Parameter(Mandatory=$true)][int]$Offset = 1
    )

    trap [System.ArgumentOutOfRangeException]
    {
        return ($Depth - $Offset)
    }

    [int]$Depth = 0
    while ($?)
    {
        Set-Variable -Name scope_test -Scope $Depth
        $depth++
    }
}

function Format-Message
{
    Param
    (
        [Parameter(Mandatory=$true)]$Message,
        [Parameter(Mandatory=$true)]$LogHash
    )

    foreach ($KV in $LogHash.GetEnumerator())
    {
        $Message = $Message -replace "{{$($KV.Key)}}", $KV.Value
    }

    return $Message
}

function Logger.Trace
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Logger.Log -Level "TRACE" -Messages $Messages
    }
}

function Logger.Debug
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Logger.Log -Level "DEBUG" -Messages $Messages
    }
}

function Logger.Info
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Logger.Log -Level "INFO" -Messages $Messages
    }
}

function Logger.Warn
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Logger.Log -Level "WARN" -Messages $Messages
    }
}

function Logger.Error
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Logger.Log -Level "ERROR" -Messages $Messages
    }
}

Export-ModuleMember -Function Set-Log
Export-ModuleMember -Function Logger.Trace
Export-ModuleMember -Function Logger.Debug
Export-ModuleMember -Function Logger.Info
Export-ModuleMember -Function Logger.Warn
Export-ModuleMember -Function Logger.Error