$source = "D:\Setup"
$destination = "C:\Windows\Setup"

if (-not (Test-Path -Path $destination)) {
    New-Item -Path $destination -ItemType Directory
}

Copy-Item -Path "$source\*" -Destination $destination -Recurse -Force
