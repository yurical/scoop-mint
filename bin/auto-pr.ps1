param(
    # overwrite upstream param
    [ValidatePattern('^(.+)\/(.+):(.+)$')]
    [String] $Upstream = $((git config --get remote.origin.url) -replace '^.+[:/](?<user>.*)\/(?<repo>.*)(\.git)?$', '${user}/${repo}:master')
)

if(!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$autopr = "$env:SCOOP_HOME/bin/auto-pr.ps1"
$dir = "$PSScriptRoot/../bucket" # checks the parent dir
Invoke-Expression -command "& '$autopr' -dir '$dir' -upstream $upstream $($args | ForEach-Object { "$_ " })"
