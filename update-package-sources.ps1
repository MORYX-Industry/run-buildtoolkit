# Load Toolkit
. ".build\Output.ps1";

$NugetConfig = ".\NuGet.Config"
$GithubNugetConfig = ".\NuGet-Github.Config"
$internalMoryxNpmSource = 'http://dockerregistry.europe.phoenixcontact.com/repository/pxc-npm-moryx-proxy'
$moryxNpmSource = 'https://www.myget.org/F/moryx-ci/npm'
$internalNpmSource = 'http://dockerregistry.europe.phoenixcontact.com/repository/pxc-npm-proxy'
$npmSource = 'https://registry.npmjs.org'

function Update-Nuget-Sources {
    if (Test-Path -Path $GithubNugetConfig) {
        Copy-Item -Path $GithubNugetConfig -Destination $NugetConfig -Force
    } else {
        Write-Output "NuGet-Github.Config does not exist keeping current content in Nuget.Config"
    }
}

function Update-Npm-Sources {
    # Get all .npmrc and package-lock.json files recursively
    $files = Get-ChildItem -Path . -Recurse -Include '.npmrc', 'package-lock.json'

    foreach ($file in $files) {
        # Read the content of the file
        $content = Get-Content -Path $file.FullName -Raw

        # Replace the old strings with the new strings
        $content = $content -replace [regex]::Escape($internalMoryxNpmSource), $moryxNpmSource
        $content = $content -replace [regex]::Escape($internalNpmSource), $npmSource

        # Write the updated content back to the file
        Set-Content -Path $file.FullName -Value $content
    }
}

function Get-Nuget-Package-Source() {
    # Load the XML content from the Nuget.config file
    [xml]$xmlContent = Get-Content -Path $NugetConfig

    # Retrieve the value for the key "nuget.org"
    $packageSourceValue = $xmlContent.configuration.packageSources.add | Where-Object { $_.key -eq "nuget.org" } | Select-Object -ExpandProperty value
    return $packageSourceValue
}

Update-Nuget-Sources
$nugetOrgValue = Get-Nuget-Package-Source

Update-Npm-Sources


Write-Step "Update package sources to..."
Write-Variable "MORYX_NUGET_SOURCE" $nugetOrgValue;
Write-Variable "MORYX_NPM_SOURCE" $npmSource;
