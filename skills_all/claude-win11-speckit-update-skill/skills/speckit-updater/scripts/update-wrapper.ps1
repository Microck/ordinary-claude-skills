#Requires -Version 7.0

<#
.SYNOPSIS
    Wrapper script that normalizes CLI arguments before invoking the orchestrator.

.DESCRIPTION
    This wrapper handles conversion of Linux-style double-dash arguments (--flag)
    to PowerShell-style single-dash arguments (-Flag) before calling the main
    orchestrator script. This allows the skill to work seamlessly with both
    command-line conventions.

.NOTES
    This script is invoked by Claude Code via SKILL.md.
#>

# Normalize arguments: convert --flag to -Flag
# Use a hashtable for splatting to avoid positional parameter issues
$params = @{}
$positionalArgs = @()

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]

    if ($arg -match '^--(.+)=(.+)') {
        # Handle --flag=value format
        $flagName = $matches[1]
        $flagValue = $matches[2]
        $parts = $flagName -split '-'
        $pascalCase = ($parts | ForEach-Object {
            if ($_.Length -gt 0) {
                $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()
            }
        }) -join ''
        $params[$pascalCase] = $flagValue
    }
    elseif ($arg -match '^--(.+)') {
        # Handle --flag format (switch or flag with next arg as value)
        $flagName = $matches[1]
        $parts = $flagName -split '-'
        $pascalCase = ($parts | ForEach-Object {
            if ($_.Length -gt 0) {
                $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()
            }
        }) -join ''

        # Check if next argument looks like a value (doesn't start with -)
        if (($i + 1) -lt $args.Count -and $args[$i + 1] -notmatch '^-') {
            # This flag has a value
            $params[$pascalCase] = $args[$i + 1]
            $i++  # Skip the next argument
        }
        else {
            # This is a switch (boolean flag)
            $params[$pascalCase] = $true
        }
    }
    elseif ($arg -match '^-(.+)') {
        # Already PowerShell style, parse it
        $flagName = $matches[1]

        # Check if next argument looks like a value
        if (($i + 1) -lt $args.Count -and $args[$i + 1] -notmatch '^-') {
            $params[$flagName] = $args[$i + 1]
            $i++
        }
        else {
            $params[$flagName] = $true
        }
    }
    else {
        # Positional argument (no dash)
        $positionalArgs += $arg
    }
}

# Invoke the real orchestrator with normalized arguments
$orchestratorPath = Join-Path $PSScriptRoot "update-orchestrator.ps1"

if ($positionalArgs.Count -gt 0) {
    & $orchestratorPath @params @positionalArgs
}
else {
    & $orchestratorPath @params
}

exit $LASTEXITCODE
