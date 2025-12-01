# Sample file with plain text password usage
# This should be detected by PSScriptAnalyzer

function Connect-ToService {
    param(
        [string]$Username,
        [string]$Password  # BAD: Plain text password parameter
    )

    # BAD: Using ConvertTo-SecureString with plain text
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force

    Write-Host "Connecting with $Username"
}

# GOOD: Using PSCredential type (this should NOT be flagged)
function Connect-Safely {
    param(
        [PSCredential]$Credential
    )

    Write-Host "Connecting safely"
}
