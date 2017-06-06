$Global:LogLevels = @("TRACE","DEBUG","INFO","WARN","ERROR")
$Global:LogProviders = @()

function Validate-LogLevel($Level)
{
    if (($Global:LogLevels -contains $Level) -eq $false)
    {
        throw ("Invalid log level, valid values [{0}]" -f $Globals:LogLevels -join "; ")
    }
}

function Add-LoggerProvider
{
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][scriptblock]$Invoke,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string]$MinLevel,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string]$MessageFormat,
        [Parameter(Mandatory=$false)][hashtable]$Parameters = @{}
    )
    
    Validate-LogLevel -Level $MinLevel

    $LogProvider = New-Object -TypeName PSObject -Property `
    @{
        Invoke = $Invoke
        MinLevel = $MinLevel
        MessageFormat = $MessageFormat
        Parameters = $Parameters
    }

    $Global:LogProviders += $LogProvider
}

function Add-LoggerFileProvider
{
    Param
    (
        $LogName = "MyScript",
        $LogPath = $env:TEMP,
        $MinLevel = "INFO",
        $MessageFormat = "{{date}} - {{level}} - [{{stack}}] --> {{message}}"
    )

    Add-LoggerProvider -Invoke ${Function:Fire-LoggerFileProvider} -MinLevel $MinLevel -MessageFormat $MessageFormat -Parameters @{LogPath=$LogPath; LogName=$LogName}
}

function Add-LoggerEmailProvider
{

}

function Add-LoggerRestProvider
{

}

function Add-LoggerStreamsProvider
{
    Param
    (
        $MinLevel = "TRACE",
        $MessageFormat = "{{date}} - {{level}} - [{{stack}}] --> {{message}}"
    )

    Add-LoggerProvider -Invoke ${Function:Fire-LoggerStreamsProvider} -MinLevel $MinLevel -MessageFormat $MessageFormat
}

function Fire-LoggerFileProvider
{
    Param
    (
        $Message,
        $Level,
        $Parameters
    )

    Add-Content -Path ("{0}.log" -f ([System.IO.Path]::Combine("$($Parameters.LogPath)", "$($Parameters.LogName)"))) -Value $Message
}

function Fire-LoggerStreamsProvider
{
    Param
    (
        $Message,
        $Level
    )

    switch ($Level)
    {
        "TRACE"
        {
            Write-Debug -Message $Message
        }
        "DEBUG"
        {
            Write-Debug -Message $Message
        }
        "INFO"
        {
            Write-Output -InputObject $Message
        }
        "WARN"
        {
            Write-Warning -Message $Message
        }
        "ERROR"
        {
            Write-Error -Message $Message
        }
        "FATAL"
        {
            Write-Error -Message $Message
        }
        default
        {
            Write-Output -InputObject $Message
        }
    }
}

function Write-Logger
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
        $Date = Get-Date
        $CallStack = (Get-CallStack -ScopeOffset ($ScopeOffset + 1))

        foreach ($LogProvider in $Global:LogProviders)
        {
            if ([array]::IndexOf($Global:LogLevels,$LogProvider.MinLevel) -le [array]::IndexOf($Global:LogLevels,$Level))
            {
                foreach ($Message in $Messages)
                {
                    $InvokeParameters = @{
                        Message = (Format-LoggerMessage -Log @{Level=$Level;Date=$Date;Stack=$CallStack;Message=$Message} -MessageFormat $LogProvider.MessageFormat)
                        Level = $Level
                        Parameters = $LogProvider.Parameters
                    }

                    & $LogProvider.Invoke @InvokeParameters
                }
            }
        }
    }
}

function Get-CallStack
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
    else
    {
        $Stack += "Interactive"
    }

    return (($Stack -join "::") + "($($CallerInvocation.Value.ScriptLineNumber))")
}

function Format-LoggerMessage
{
    Param
    (
        [Parameter(Mandatory=$true)][hashtable]$Log,
        [Parameter(Mandatory=$true)][string]$MessageFormat
    )

    foreach ($KV in $Log.GetEnumerator())
    {
        $MessageFormat = $MessageFormat -replace "{{$($KV.Key)}}", $KV.Value
    }

    return $MessageFormat
}

function Write-LoggerTrace
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Write-Logger -Level "TRACE" -Messages $Messages -ScopeOffset 1
    }
}

function Write-LoggerDebug
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Write-Logger -Level "DEBUG" -Messages $Messages -ScopeOffset 1
    }
}

function Write-LoggerInfo
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Write-Logger -Level "INFO" -Messages $Messages -ScopeOffset 1
    }
}

function Write-LoggerWarn
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Write-Logger -Level "WARN" -Messages $Messages -ScopeOffset 1
    }
}

function Write-LoggerError
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages
    )

    Process
    {
        Write-Logger -Level "ERROR" -Messages $Messages -ScopeOffset 1
    }
}

function Write-LoggerFatal
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Messages,
        [Parameter(Mandatory=$false)][int]$ExitCode=1
    )

    Process
    {
        Write-Logger -Level "FATAL" -Messages $Messages -ScopeOffset 1
    }

    End
    {
        [Environment]::Exit($ExitCode)
    }
}

Export-ModuleMember -Function "Add-LoggerProvider"
Export-ModuleMember -Function "Add-LoggerFileProvider"
Export-ModuleMember -Function "Add-LoggerStreamsProvider"
Export-ModuleMember -Function "Write-LoggerTrace"
Export-ModuleMember -Function "Write-LoggerDebug"
Export-ModuleMember -Function "Write-LoggerInfo"
Export-ModuleMember -Function "Write-LoggerWarn"
Export-ModuleMember -Function "Write-LoggerError"
Export-ModuleMember -Function "Write-LoggerFatal"

Set-Alias -Name "Logger.Trace" -Value "Write-LoggerTrace"
Set-Alias -Name "Logger.Debug" -Value "Write-LoggerDebug"
Set-Alias -Name "Logger.Info" -Value "Write-LoggerInfo"
Set-Alias -Name "Logger.Warn" -Value "Write-LoggerWarn"
Set-Alias -Name "Logger.Error" -Value "Write-LoggerError"
Set-Alias -Name "Logger.Fatal" -Value "Write-LoggerFatal"
Export-ModuleMember -Alias *