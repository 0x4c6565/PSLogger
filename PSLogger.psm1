$Global:LogLevels = @("TRACE","DEBUG","INFO","WARN","ERROR")
$Global:LogProviders = @()

function Add-LogProvider
{
    Param
    (
        [scriptblock]$ScriptBlock,
        [string]$Level,
        [string]$MessageFormat
    )
    
    Validate-LogLevel -LogLevel $LogLevel

    $LogProvider = New-Object -TypeName PSObject -Property `
    @{
        ScriptBlock = $ScriptBlock
        Level = $Level
        MessageFormat = $MessageFormat
    }

    $Global:LogProviders += $LogProvider
}

function Add-FileLogProvider
{
    Param
    (
        $LogName = "MyScript",
        $LogPath = $env:TEMP,
        $Level = "INFO",
        $MessageFormat = "{{date}} - {{level}} - [{{stack}}] --> {{message}}" 
    )

    $ScriptBlock = [scriptblock]::Create("
    Param
    (
        `$Message
    )
    Add-Content -Path (`"{0}.log`" -f ([System.IO.Path]::Combine(`"$LogPath`", `"$LogName`"))) -Value `$Message")

    Add-LogProvider -ScriptBlock $ScriptBlock -Level $Level -MessageFormat $MessageFormat
}

function Validate-LogLevel
{
    if (($Global:LogLevels -contains $LogLevel) -eq $false)
    {
        throw ("Invalid log level, valid values [{0}]" -f $Globals:LogLevels -join "; ")
    }
}

function Logger.Log
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)][string]$Level,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages,
        [Parameter(Mandatory=$false)][int]$ScopeOffset
    )

    Process
    {
        foreach ($LogProvider in $Global:LogProviders)
        {
            if ([array]::IndexOf($Global:LogLevels,$LogProvider.Level) -le [array]::IndexOf($Global:LogLevels,$Level))
            {
                foreach ($Message in $Messages)
                {
                    $LogHash = @{
                        Level = $Level
                        Date = Get-Date
                        Stack = (Generate-Stack -ScopeOffset ($ScopeOffset + 1))
                        Message = $Message
                    }

                    $FormattedMessage = Format-Message -Message $LogProvider.MessageFormat -LogHash $LogHash

                    & $LogProvider.ScriptBlock -Message $FormattedMessage
                }
            }
        }
    }
}

function Generate-Stack
{
    Param
    (
        $ScopeOffset=0
    )

    $CallerInvocation = Get-Variable MyInvocation -Scope $ScopeOffset    

    $Stack = @()
    if ([string]::IsNullOrEmpty($CallerInvocation.Value.ScriptName) -eq $false)
    {
        $Stack += (Split-Path -Path $CallerInvocation.Value.ScriptName -Leaf)
    }

    return (($Stack -join "::") + "($($CallerInvocation.Value.ScriptLineNumber))")
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
        Logger.Log -Level "TRACE" -Messages $Messages -ScopeOffset 1
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
        Logger.Log -Level "DEBUG" -Messages $Messages -ScopeOffset 1
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
        Logger.Log -Level "INFO" -Messages $Messages -ScopeOffset 1
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
        Logger.Log -Level "WARN" -Messages $Messages -ScopeOffset 1
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
        Logger.Log -Level "ERROR" -Messages $Messages -ScopeOffset 1
    }
}

function Logger.Fatal
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages,
        [Parameter(Mandatory=$false)][int]$ExitCode=1
    )

    Process
    {
        Logger.Log -Level "FATAL" -Messages $Messages -ScopeOffset 1
    }

    End
    {
        [Environment]::Exit($ExitCode)
    }
}

Export-ModuleMember -Function "Add-LogProvider"
Export-ModuleMember -Function "Add-FileLogProvider"
Export-ModuleMember -Function "Logger.Log"
Export-ModuleMember -Function "Logger.Trace"
Export-ModuleMember -Function "Logger.Debug"
Export-ModuleMember -Function "Logger.Info"
Export-ModuleMember -Function "Logger.Warn"
Export-ModuleMember -Function "Logger.Error"
Export-ModuleMember -Function "Logger.Fatal"