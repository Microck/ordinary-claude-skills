#Requires -Version 7.0

<#
.SYNOPSIS
    VSCode integration module for SpecKit Safe Update Skill.

.DESCRIPTION
    Provides functions to detect execution context (VSCode vs terminal) and
    integrate with VSCode tools (diff viewer, merge editor, Quick Pick).

.NOTES
    Module: VSCodeIntegration.psm1
    Author: SpecKit Safe Update Skill
    Version: 1.0
#>

function Get-ExecutionContext {
    <#
    .SYNOPSIS
        Detects the current execution context.

    .DESCRIPTION
        Determines whether the script is running in:
        - 'vscode-extension': VSCode extension context
        - 'vscode-terminal': VSCode integrated terminal
        - 'standalone-terminal': Standalone PowerShell terminal

    .OUTPUTS
        String. Returns 'vscode-extension', 'vscode-terminal', or 'standalone-terminal'

    .EXAMPLE
        $context = Get-ExecutionContext
        if ($context -eq 'vscode-extension') {
            # Use VSCode-specific features
        }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($env:VSCODE_PID) {
        # Running inside VSCode
        if ($env:TERM_PROGRAM -eq 'vscode') {
            return 'vscode-terminal'
        }
        else {
            return 'vscode-extension'
        }
    }
    else {
        return 'standalone-terminal'
    }
}

function Show-QuickPick {
    <#
    .SYNOPSIS
        Shows a Quick Pick menu for user selection.

    .DESCRIPTION
        In VSCode context, returns a sentinel hashtable for Claude orchestration.
        In terminal context, falls back to numbered menu with Read-Host.

    .PARAMETER Prompt
        The question to ask the user.

    .PARAMETER Options
        Array of options for the user to choose from.

    .PARAMETER MultiSelect
        If specified, allows multiple selections (terminal mode only for now).

    .OUTPUTS
        String or String[]. Returns selected option(s).

    .EXAMPLE
        $choice = Show-QuickPick -Prompt "Select an option" -Options @("Yes", "No")

    .EXAMPLE
        $choices = Show-QuickPick -Prompt "Select features" -Options @("Feature1", "Feature2", "Feature3") -MultiSelect
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [string[]]$Options,

        [Parameter(Mandatory = $false)]
        [switch]$MultiSelect
    )

    $context = Get-ExecutionContext

    if ($context -eq 'vscode-extension' -or $context -eq 'vscode-terminal') {
        # In VSCode context: return sentinel hashtable for Claude orchestration
        # Claude Code extension will intercept this and show native Quick Pick
        return @{
            __ClaudeQuickPick = $true
            Prompt = $Prompt
            Options = $Options
            MultiSelect = $MultiSelect.IsPresent
        }
    }
    else {
        # Terminal fallback: numbered menu with Read-Host
        Write-Host ""
        Write-Host $Prompt
        Write-Host ""

        for ($i = 0; $i -lt $Options.Count; $i++) {
            Write-Host "  [$($i + 1)] $($Options[$i])"
        }
        Write-Host ""

        if ($MultiSelect) {
            Write-Host "Enter selection numbers separated by commas (e.g., 1,3,4): " -NoNewline
            $input = Read-Host
            $selections = $input -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

            $result = @()
            foreach ($sel in $selections) {
                $index = [int]$sel - 1
                if ($index -ge 0 -and $index -lt $Options.Count) {
                    $result += $Options[$index]
                }
            }
            return $result
        }
        else {
            do {
                Write-Host "Enter selection (1-$($Options.Count)): " -NoNewline
                $input = Read-Host
                $selection = 0
                $valid = [int]::TryParse($input, [ref]$selection)
            } while (-not $valid -or $selection -lt 1 -or $selection -gt $Options.Count)

            return $Options[$selection - 1]
        }
    }
}

function Open-DiffView {
    <#
    .SYNOPSIS
        Opens VSCode diff viewer for two files.

    .DESCRIPTION
        Executes 'code --diff' command to show differences between two files.
        Requires VSCode CLI to be available in PATH.

    .PARAMETER LeftPath
        Path to the left (original) file.

    .PARAMETER RightPath
        Path to the right (modified) file.

    .PARAMETER Title
        Optional title for the diff view.

    .EXAMPLE
        Open-DiffView -LeftPath "original.md" -RightPath "modified.md" -Title "My Changes"

    .NOTES
        Throws an error if 'code' command is not available.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LeftPath,

        [Parameter(Mandatory = $true)]
        [string]$RightPath,

        [Parameter(Mandatory = $false)]
        [string]$Title
    )

    # Check if 'code' command is available
    $codeCommand = Get-Command code -ErrorAction SilentlyContinue
    if (-not $codeCommand) {
        throw "VSCode CLI ('code' command) not found in PATH. Please install VSCode and ensure the CLI is available."
    }

    # Convert to absolute paths
    $leftAbs = Resolve-Path $LeftPath -ErrorAction Stop
    $rightAbs = Resolve-Path $RightPath -ErrorAction Stop

    try {
        # Execute diff command
        if ($Title) {
            Write-Host "Opening diff view: $Title"
        }
        else {
            Write-Host "Opening diff view for: $leftAbs vs $rightAbs"
        }

        & code --diff "$leftAbs" "$rightAbs"
    }
    catch {
        throw "Failed to open diff view: $($_.Exception.Message)"
    }
}

function Open-MergeEditor {
    <#
    .SYNOPSIS
        Opens VSCode 3-way merge editor.

    .DESCRIPTION
        Executes 'code --merge' command to open VSCode's merge editor for conflict resolution.
        Blocks until merge is complete. Requires VSCode CLI to be available in PATH.

    .PARAMETER BasePath
        Path to the base (common ancestor) file.

    .PARAMETER CurrentPath
        Path to the current (your version) file.

    .PARAMETER IncomingPath
        Path to the incoming (upstream version) file.

    .PARAMETER ResultPath
        Path where the merged result will be saved.

    .OUTPUTS
        Boolean. Returns $true if merge was successful, $false otherwise.

    .EXAMPLE
        $success = Open-MergeEditor -BasePath "base.md" -CurrentPath "current.md" -IncomingPath "incoming.md" -ResultPath "result.md"

    .NOTES
        Throws an error if 'code' command is not available.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$CurrentPath,

        [Parameter(Mandatory = $true)]
        [string]$IncomingPath,

        [Parameter(Mandatory = $true)]
        [string]$ResultPath
    )

    # Check if 'code' command is available
    $codeCommand = Get-Command code -ErrorAction SilentlyContinue
    if (-not $codeCommand) {
        throw "VSCode CLI ('code' command) not found in PATH. Please install VSCode and ensure the CLI is available."
    }

    # Convert to absolute paths
    $baseAbs = Resolve-Path $BasePath -ErrorAction Stop
    $currentAbs = Resolve-Path $CurrentPath -ErrorAction Stop
    $incomingAbs = Resolve-Path $IncomingPath -ErrorAction Stop

    # ResultPath might not exist yet, so handle it separately
    if (Test-Path $ResultPath) {
        $resultAbs = Resolve-Path $ResultPath
    }
    else {
        $resultAbs = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ResultPath)
    }

    try {
        Write-Host "Opening merge editor..."
        Write-Host "  Base: $baseAbs"
        Write-Host "  Current: $currentAbs"
        Write-Host "  Incoming: $incomingAbs"
        Write-Host "  Result: $resultAbs"
        Write-Host ""
        Write-Host "Waiting for merge to complete..."

        # Execute merge command with --wait flag
        & code --merge "$baseAbs" "$currentAbs" "$incomingAbs" "$resultAbs" --wait

        # Check if result file exists after merge
        if (Test-Path $resultAbs) {
            Write-Host "Merge completed successfully."
            return $true
        }
        else {
            Write-Warning "Merge result file not found. Merge may have been cancelled."
            return $false
        }
    }
    catch {
        Write-Error "Failed to open merge editor: $($_.Exception.Message)"
        return $false
    }
}

function Show-Notification {
    <#
    .SYNOPSIS
        Shows a notification message.

    .DESCRIPTION
        Displays a message with appropriate color coding based on level.
        In VSCode context, could potentially integrate with extension notifications.
        In terminal, uses Write-Host with color coding.

    .PARAMETER Message
        The message to display.

    .PARAMETER Level
        The severity level: 'info', 'warning', or 'error'.

    .EXAMPLE
        Show-Notification -Message "Update completed successfully" -Level info

    .EXAMPLE
        Show-Notification -Message "Conflict detected" -Level warning

    .EXAMPLE
        Show-Notification -Message "Update failed" -Level error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('info', 'warning', 'error')]
        [string]$Level = 'info'
    )

    switch ($Level) {
        'info' {
            Write-Host $Message -ForegroundColor Cyan
        }
        'warning' {
            Write-Host $Message -ForegroundColor Yellow
        }
        'error' {
            Write-Host $Message -ForegroundColor Red
        }
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Get-ExecutionContext',
    'Show-QuickPick',
    'Open-DiffView',
    'Open-MergeEditor',
    'Show-Notification'
)
