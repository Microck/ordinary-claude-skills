# Sample file with Invoke-Expression vulnerability
# This should be detected by PSScriptAnalyzer

param([string]$UserCommand)

# BAD: Using Invoke-Expression with user input (code injection risk)
Invoke-Expression $UserCommand

# BAD: Another example
$script = "Write-Host 'Hello'"
Invoke-Expression $script
