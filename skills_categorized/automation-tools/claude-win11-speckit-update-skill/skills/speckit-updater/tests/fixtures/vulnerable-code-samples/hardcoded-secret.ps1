# Sample file with hardcoded secrets
# This should be detected by GitLeaks

# BAD: Hardcoded API key
$apiKey = "AKIAIOSFODNN7EXAMPLE"

# BAD: Hardcoded GitHub token
$githubToken = "ghp_1234567890abcdefghijklmnopqrstuvwxyz"

# BAD: Hardcoded password
$password = "SuperSecret123!"

# GOOD: Using environment variables (this should NOT be flagged)
$safeApiKey = $env:API_KEY
