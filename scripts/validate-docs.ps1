param(
    [string]$Root = (Resolve-Path ".").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$issues = New-Object System.Collections.Generic.List[string]

function Add-Issue {
    param(
        [string]$Path,
        [int]$Line,
        [string]$Message
    )

    $relative = [System.IO.Path]::GetRelativePath($Root, $Path)
    if ($Line -gt 0) {
        $issues.Add("${relative}:${Line}: ${Message}")
    }
    else {
        $issues.Add("${relative}: ${Message}")
    }
}

function Test-LocalMarkdownLink {
    param(
        [string]$SourcePath,
        [string]$Target
    )

    if ([string]::IsNullOrWhiteSpace($Target)) {
        return
    }

    if ($Target.StartsWith("#")) {
        return
    }

    if ($Target -match "^[a-zA-Z][a-zA-Z0-9+.-]*:") {
        return
    }

    $pathOnly = ($Target -split "#", 2)[0]
    $pathOnly = ($pathOnly -split "\s+`"", 2)[0]

    if ([string]::IsNullOrWhiteSpace($pathOnly)) {
        return
    }

    $sourceDir = Split-Path -Parent $SourcePath
    $candidate = Join-Path $sourceDir $pathOnly

    if (-not (Test-Path -LiteralPath $candidate)) {
        throw "broken local markdown link '${Target}'"
    }
}

$markdownFiles = Get-ChildItem -Path $Root -Recurse -File -Filter "*.md" |
    Where-Object { $_.FullName -notmatch "[\\/]\.git[\\/]" } |
    Sort-Object FullName

if ($markdownFiles.Count -eq 0) {
    throw "No markdown files found."
}

foreach ($file in $markdownFiles) {
    $lines = Get-Content -LiteralPath $file.FullName -Encoding UTF8
    $inFence = $false
    $fenceStart = 0
    $fenceLang = ""
    $fenceHasBody = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNumber = $i + 1
        $line = $lines[$i]

        if ($line -match "^(<<<<<<<|=======|>>>>>>>)") {
            Add-Issue $file.FullName $lineNumber "merge conflict marker found"
        }

        if ($line -match "^```\s*([A-Za-z0-9_-]*)\s*$") {
            if (-not $inFence) {
                $inFence = $true
                $fenceStart = $lineNumber
                $fenceLang = $Matches[1]
                $fenceHasBody = $false
            }
            else {
                if ($fenceLang -eq "mermaid" -and -not $fenceHasBody) {
                    Add-Issue $file.FullName $fenceStart "empty mermaid block"
                }

                $inFence = $false
                $fenceStart = 0
                $fenceLang = ""
                $fenceHasBody = $false
            }

            continue
        }

        if ($inFence) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $fenceHasBody = $true
            }
            continue
        }

        $matches = [regex]::Matches($line, "(?<!\!)\[[^\]]+\]\(([^)]+)\)")
        foreach ($match in $matches) {
            $target = $match.Groups[1].Value.Trim()
            try {
                Test-LocalMarkdownLink -SourcePath $file.FullName -Target $target
            }
            catch {
                Add-Issue $file.FullName $lineNumber $_.Exception.Message
            }
        }
    }

    if ($inFence) {
        Add-Issue $file.FullName $fenceStart "unclosed fenced code block"
    }
}

if ($issues.Count -gt 0) {
    $issues | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Validated $($markdownFiles.Count) markdown files."
