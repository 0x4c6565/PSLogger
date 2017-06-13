$Script:LogLevels = @("TRACE","DEBUG","INFO","WARN","ERROR")
$Script:LoggerTargets = @()

#TODO - LOOK AT CMDLET BINDING BEGIN PROCESS END BLOCKS PIPELINE/PARAMETER SPECIFIED!!

function Validate-LogLevel($Level)
{
    if (($Script:LogLevels -contains $Level) -eq $false)
    {
        throw ("Invalid log level, valid values [{0}]" -f $Script:LogLevels -join "; ")
    }
}

function Get-LoggerTarget($Name)
{
    if ([string]::IsNullOrEmpty($Name) -eq $false)
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

function Add-LoggerTarget
{
    Param
    (
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$Invoke,
        [Parameter(Mandatory=$true)][string]$MinLevel,
        [Parameter(Mandatory=$true)][string]$MessageFormat,
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
        Parameters = $Parameters
    }

    $Script:LoggerTargets += $LoggerTarget
}

function Add-LoggerFileTarget
{
    Param
    (
        [Parameter(Mandatory=$true)]$Name,
        [Parameter(Mandatory=$true)]$LogName,
        [Parameter(Mandatory=$false)]$LogPath = $env:TEMP,
        [Parameter(Mandatory=$false)]$MinLevel = "INFO",
        [Parameter(Mandatory=$false)]$MessageFormat = "{{date}} - {{level}} - [{{stack}}] --> {{message}}"
    )

    Add-LoggerTarget -Name $Name -Invoke ${Function:Fire-LoggerFileTarget} -MinLevel $MinLevel -MessageFormat $MessageFormat -Parameters @{LogPath=$LogPath; LogName=$LogName}
}

function Fire-LoggerFileTarget
{
    Param
    (
        $Message,
        $Level,
        $Parameters
    )

    Add-Content -Path ("{0}.log" -f ([System.IO.Path]::Combine("$($Parameters.LogPath)", "$($Parameters.LogName)"))) -Value $Message
}

function Add-LoggerStreamsTarget
{
    Param
    (
        [Parameter(Mandatory=$true)]$Name,
        [Parameter(Mandatory=$false)]$MinLevel = "TRACE",
        [Parameter(Mandatory=$false)]$MessageFormat = "{{date}} - {{level}} - [{{stack}}] --> {{message}}"
    )

    Add-LoggerTarget -Name $Name -Invoke ${Function:Fire-LoggerStreamsTarget} -MinLevel $MinLevel -MessageFormat $MessageFormat
}

function Fire-LoggerStreamsTarget
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

function Add-LoggerEmailTarget
{

}

function Add-LoggerRestTarget
{

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
            $Targets = $Script:LoggerTargets
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

                    & $LoggerTarget.Invoke @InvokeParameters
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
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string[]]$Message,
        [Parameter(Mandatory=$false)][string]$Target
    )

    Process
    {
        Write-Logger -Level "TRACE" -Message $Message -ScopeOffset 1 -Target $Target
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
        Write-Logger -Level "DEBUG" -Message $Message -ScopeOffset 1 -Target $Target
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
        Write-Logger -Level "INFO" -Message $Message -ScopeOffset 1 -Target $Target
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
        Write-Logger -Level "WARN" -Message $Message -ScopeOffset 1 -Target $Target
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
        Write-Logger -Level "ERROR" -Message $Message -ScopeOffset 1 -Target $Target
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
        Write-Logger -Level "FATAL" -Message $Message -ScopeOffset 1 -Target $Target
    }

    End
    {
        [Environment]::Exit($ExitCode)
    }
}

Export-ModuleMember -Function "Get-LoggerTarget"
Export-ModuleMember -Function "Test-LoggerTarget"
Export-ModuleMember -Function "Add-LoggerTarget"
Export-ModuleMember -Function "Add-LoggerFileTarget"
Export-ModuleMember -Function "Add-LoggerStreamsTarget"
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