# PSScriptAnalyzer Settings for SpecKit Safe Update Skill
#
# This configuration defines the linting rules for PowerShell code quality.
# Enforces best practices, security, performance, and style guidelines.
#
# See: https://github.com/PowerShell/PSScriptAnalyzer

@{
    # Severity levels to include (Error, Warning, Information)
    Severity = @(
        'Error',
        'Warning'
        # 'Information'  # Uncomment for stricter checking
    )

    # Include only specific rules (comment out to include all)
    # IncludeDefaultRules = $true

    # Specific rules to include (enforced)
    IncludeRules = @(
        # Cmdlet design rules
        'PSAvoidUsingCmdletAliases',              # Use full cmdlet names, not aliases (% -> ForEach-Object)
        'PSUseApprovedVerbs',                     # Use approved PowerShell verbs (Get, Set, New, Remove, etc.)
        'PSUseSingularNouns',                     # Function names should use singular nouns
        'PSReservedCmdletChar',                   # Avoid special characters in cmdlet names
        'PSReservedParams',                       # Don't override reserved parameter names

        # Script functions
        'PSProvideCommentHelp',                   # Functions must have comment-based help
        'PSAvoidDefaultValueSwitchParameter',     # Switch parameters shouldn't have default values

        # Security rules
        'PSAvoidUsingPlainTextForPassword',       # Use SecureString for passwords
        'PSAvoidUsingConvertToSecureStringWithPlainText',  # Don't convert plain text to SecureString
        'PSUsePSCredentialType',                  # Use PSCredential type for credentials
        'PSAvoidUsingUsernameAndPasswordParams',  # Use PSCredential instead of separate username/password

        # Performance rules
        'PSUseDeclaredVarsMoreThanAssignments',   # Variables should be used after assignment
        'PSAvoidUsingInvokeExpression',           # Avoid Invoke-Expression (security risk)
        'PSAvoidAssignmentToAutomaticVariable',   # Don't assign to $?, $input, etc.

        # Code quality rules
        'PSAvoidUsingPositionalParameters',       # Use named parameters for clarity
        'PSAvoidGlobalVars',                      # Avoid $global: scope (use parameters instead)
        'PSUseCmdletCorrectly',                   # Cmdlets should follow correct syntax
        'PSUseConsistentWhitespace',              # Enforce consistent whitespace
        'PSUseConsistentIndentation'              # Enforce consistent indentation
        # 'PSAlignAssignmentStatement',           # Align assignment statements (disabled - too strict for JSON/hashtable alignment)

        # Error handling
        'PSAvoidShouldContinueWithoutForce',      # ShouldContinue requires -Force parameter
        'PSUseShouldProcessForStateChangingFunctions',  # State-changing functions should support -WhatIf

        # Best practices
        # 'PSAvoidUsingWriteHost',                  # Excluded below - we use Write-Host for colored output
        'PSAvoidUsingEmptyCatchBlock',            # Catch blocks should have error handling
        'PSUseOutputTypeCorrectly',               # [OutputType()] should match actual output
        'PSUseSupportsShouldProcess'              # Functions modifying state should declare SupportsShouldProcess
        # Note: PSUseBOMForUnicodeEncodedFile excluded (see ExcludeRules)
        # Note: PSAvoidUsingWriteHost excluded (see ExcludeRules)
        # Note: Compatibility rules (PSUseCompatible*) excluded (require complex profile configuration)
    )

    # Rules to exclude (disabled)
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',  # We use Write-Host intentionally for colored user-facing output
        'PSUseBOMForUnicodeEncodedFile'  # We explicitly avoid BOM in HashUtils for cross-platform compatibility
    )

    # Rules configuration (custom settings for specific rules)
    Rules = @{
        # Whitespace consistency
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator = $true
            CheckParameter = $false  # Allow flexibility in parameter spacing
        }

        # Indentation consistency
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4       # 4 spaces per indent level
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'            # Use spaces, not tabs
        }

        # Alignment
        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }

        # Comment help requirements
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $true      # Only exported functions require comment help
            BlockComment = $true      # Use block comments (<# #>), not line comments
            VSCodeSnippetCorrection = $true
            Placement = 'before'      # Comment help should be before function definition
        }

        # Compatibility targets (commented out - requires complex profile configuration)
        # PSUseCompatibleCmdlets = @{
        #     Compatibility = @('core-7.0.0-windows', 'core-7.0.0-linux')
        # }
        #
        # PSUseCompatibleSyntax = @{
        #     Enable = $true
        #     TargetVersions = @('7.0')
        # }
        #
        # PSUseCompatibleTypes = @{
        #     Enable = $true
        #     TargetVersions = @('7.0')
        # }
    }
}
