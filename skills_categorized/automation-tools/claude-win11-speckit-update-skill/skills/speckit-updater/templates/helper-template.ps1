<#
.SYNOPSIS
    [Brief description of what this helper does]

.DESCRIPTION
    Helper function dot-sourced by update-orchestrator.ps1.

    IMPORTANT: This is a HELPER SCRIPT (not a module). Do NOT use Export-ModuleMember.
    Functions defined here are automatically available after dot-sourcing.

.PARAMETER ParameterName
    [Parameter description]

.EXAMPLE
    Invoke-MyHelper -ParameterName "value"
    [Description of what this example does]

.NOTES
    File:    helper-template.ps1
    Pattern: Helper (dot-sourced)
    DO NOT use Export-ModuleMember - causes "Export-ModuleMember cmdlet can only be called from inside a module" errors
#>

function Invoke-MyHelper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ParameterName
    )

    try {
        Write-Verbose "Starting helper function: Invoke-MyHelper"

        # Implementation here

        Write-Verbose "Helper function completed successfully"
    }
    catch {
        Write-Error "Helper function failed: $($_.Exception.Message)"
        throw
    }
}

# No Export-ModuleMember needed - dot-sourced functions are automatically available in caller scope
