$Script:LogLevels = @("TRACE","DEBUG","INFO","WARN","ERROR")
$Script:LoggerTargets = @()
[scriptblock]$Script:TargetExceptionHandler=$null

function Validate-LogLevel($Level)
{
    if (($Script:LogLevels -contains $Level) -eq $false)
    {
        throw ("Invalid log level, valid values [{0}]" -f $Script:LogLevels -join "; ")
    }
}

function Get-LoggerTarget($Name=$null)
{
    if ($Name -ne $null)
    {
        $FoundTargets = ($Script:LoggerTargets | ? {$_.Name -like $Name})
        if ($FoundTargets -eq $null)
        {
            throw "Cannot find target with name [$Name]"
        }
        else
        {
            return $FoundTargets
        }
    }

    return $Script:LoggerTargets
}

function Test-LoggerTarget($Name)
{
    try
    {
        Get-LoggerTarget -Name $Name

        return $true
    }
    catch
    {
        return $false
    }
}

function Set-LoggerTargetExceptionHandler
{
    Param
    (
        [Parameter(Mandatory=$true)][scriptblock]$Handler
    )

    if ($Handler -eq $null)
    {
        throw "Invalid scriptblock"
    }

    $Script:TargetExceptionHandler = $Handler
}

function Add-LoggerTarget
{
    Param
    (
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$Invoke,
        [Parameter(Mandatory=$true)][string]$MinLevel,
        [Parameter(Mandatory=$true)][string]$MessageFormat,
        [Parameter(Mandatory=$false)][switch]$Passive,
        [Parameter(Mandatory=$false)][hashtable]$Parameters = @{}

    )
        
    Validate-LogLevel -Level $MinLevel

    if (Test-LoggerTarget -Name $Name)
    {
        throw "Logger Target already exists"
    }

    $LoggerTarget = New-Object -TypeName PSObject -Property `
    @{
        Name = $Name
        Invoke = $Invoke
        MinLevel = $MinLevel
        MessageFormat = $MessageFormat
        Passive = $Passive
        Parameters = $Parameters
    }

    $Script:LoggerTargets += $LoggerTarget
}

function Add-LoggerFileTarget
{
    Param
    (
        [Parameter(Mandatory=$true)]$Name,
        [Parameter(Mandatory=$false)]$LogPath,
        [Parameter(Mandatory=$false)]$MinLevel = "INFO",
        [Parameter(Mandatory=$false)]$MessageFormat = "{{date}} - {{level}} - [{{stack}}] --> {{message}}",
        [Parameter(Mandatory=$false)][switch]$Passive
    )

    if ([string]::IsNullOrEmpty($LogPath))
    {
        $LogPath = ("{0}.log" -f [System.IO.Path]::Combine($env:TEMP, $Name))
    }

    Add-LoggerTarget -Name $Name -Invoke ${Function:Fire-LoggerFileTarget} -MinLevel $MinLevel -MessageFormat $MessageFormat -Passive:$Passive -Parameters @{LogPath=$LogPath}
}

function Fire-LoggerFileTarget
{
    Param
    (
        $Message,
        $Level,
        $Parameters
    )

    Add-Content -Path $Parameters.LogPath -Value $Message
}

function Add-LoggerEmailTarget
{

}

function Add-LoggerRestTarget
{

}

function Add-LoggerHostTarget
{
    Param
    (
        [Parameter(Mandatory=$true)]$Name,
        [Parameter(Mandatory=$false)]$MinLevel = "TRACE",
        [Parameter(Mandatory=$false)]$MessageFormat = "{{date}} - {{level}} - [{{stack}}] --> {{message}}",
        [Parameter(Mandatory=$false)][switch]$Passive
    )

    Add-LoggerTarget -Name $Name -Invoke ${Function:Fire-LoggerHostTarget} -MinLevel $MinLevel -MessageFormat $MessageFormat -Passive:$Passive
}

function Fire-LoggerHostTarget
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
            Write-Host -ForegroundColor Magenta -Object $Message
        }
        "DEBUG"
        {
            Write-Host -ForegroundColor Cyan -Object $Message
        }
        "INFO"
        {
            Write-Host -Object $Message
        }
        "WARN"
        {
            Write-Host -ForegroundColor Yellow -Object $Message
        }
        "ERROR"
        {
            Write-Host -ForegroundColor Red -Object $Message
        }
        "FATAL"
        {
            Write-Host -ForegroundColor DarkRed -Object $Message
        }
        default
        {
            Write-Host -Object $Message
        }
    }
}

function Write-Logger
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)][string]$Level,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Message,
        [Parameter(Mandatory=$false)][int]$ScopeOffset,
        [Parameter(Mandatory=$false)][string]$Target
    )

    Begin
    {
        $Date = Get-Date
        $CallStack = (Get-CallStack -ScopeOffset ($ScopeOffset + 1))
        if ([string]::IsNullOrEmpty($Target) -eq $false)
        {
            $Targets = Get-LoggerTarget -Name $Target
        }
        else
        {
            $Targets = Get-LoggerTarget | ? {$_.Passive -eq $false}
        }
    }

    Process
    {
        foreach ($LoggerTarget in $Targets)
        {
            if ([array]::IndexOf($Script:LogLevels,$LoggerTarget.MinLevel) -le [array]::IndexOf($Script:LogLevels,$Level))
            {
                foreach ($CurrentMessage in $Message)
                {
                    $InvokeParameters = @{
                        Message = (Format-LoggerMessage -Log @{Level=$Level;Date=$Date;Stack=$CallStack;Message=$CurrentMessage} -MessageFormat $LoggerTarget.MessageFormat)
                        Level = $Level
                        Parameters = $LoggerTarget.Parameters
                    }

                    try
                    {
                        & $LoggerTarget.Invoke @InvokeParameters
                    }
                    catch
                    {
                        if ($Script:TargetExceptionHandler -ne $null)
                        {
                            $InvokeParameters = @{Target=$LoggerTarget;Exception=$_.Exception}
                            & $Script:TargetExceptionHandler @InvokeParameters
                        }
                    }
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

    $Stack = @()
    $CallStack = Get-PSCallStack | Select-Object -Skip ($ScopeOffset+1) -First 1

    $ScriptName = ""
    if ([string]::IsNullOrEmpty($CallStack.ScriptName) -eq $false)
    {
        $Stack += [System.IO.Path]::GetFileName($CallStack.ScriptName)
    }
    else
    {
        $Stack += "Interactive"
    }

    if ($CallStack.FunctionName -ne "<ScriptBlock>")
    {
        $Stack += $CallStack.FunctionName
    }

    return (($Stack -join "::") + "($($CallStack.ScriptLineNumber))")
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
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Message,
        [Parameter(Mandatory=$false)][string]$Target
    )

    Process
    {
        $Message | Write-Logger -Level "TRACE" -ScopeOffset 1 -Target $Target
    }
}

function Write-LoggerDebug
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Message,
        [Parameter(Mandatory=$false)][string]$Target
    )

    Process
    {
        $Message | Write-Logger -Level "DEBUG" -ScopeOffset 1 -Target $Target
    }
}

function Write-LoggerInfo
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Message,
        [Parameter(Mandatory=$false)][string]$Target
    )

    Process
    {
        $Message | Write-Logger -Level "INFO" -ScopeOffset 1 -Target $Target
    }
}

function Write-LoggerWarn
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Message,
        [Parameter(Mandatory=$false)][string]$Target
    )

    Process
    {
        $Message | Write-Logger -Level "WARN" -ScopeOffset 1 -Target $Target
    }
}

function Write-LoggerError
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Message,
        [Parameter(Mandatory=$false)][string]$Target
    )

    Process
    {
        $Message | Write-Logger -Level "ERROR" -ScopeOffset 1 -Target $Target
    }
}

function Write-LoggerFatal
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Message,
        [Parameter(Mandatory=$false)][int]$ExitCode=1,
        [Parameter(Mandatory=$false)][string]$Target
    )

    Process
    {
        $Message | Write-Logger -Level "FATAL" -ScopeOffset 1 -Target $Target
    }

    End
    {
        [Environment]::Exit($ExitCode)
    }
}

Export-ModuleMember -Function "Get-LoggerTarget"
Export-ModuleMember -Function "Test-LoggerTarget"
Export-ModuleMember -Function "Set-LoggerTargetExceptionHandler"
Export-ModuleMember -Function "Add-LoggerTarget"
Export-ModuleMember -Function "Add-LoggerFileTarget"
Export-ModuleMember -Function "Add-LoggerStreamsTarget"
Export-ModuleMember -Function "Add-LoggerHostTarget"
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
Export-ModuleMember -Alias Logger.*
