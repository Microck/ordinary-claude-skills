# Sample file with path traversal vulnerabilities
# This should be detected by check-path-security.ps1

param([string]$UserInput)

# BAD: Unsafe path concatenation
$basePath = "C:\Data"
$fullPath = $basePath + "\" + $UserInput

# BAD: Unsafe string interpolation
$unsafePath = "$basePath\$UserInput"

# BAD: Direct use of .. traversal
if ($UserInput.Contains("..")) {
    Write-Host "Path contains .."
}

# GOOD: Using Join-Path (this should NOT be flagged)
$safePath = Join-Path $basePath $UserInput
