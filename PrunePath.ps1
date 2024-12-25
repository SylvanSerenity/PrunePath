# Define configurable parameters
param(
    [string]$SymlinkPath = "C:\Refs",
    [string]$BackupPath = ".\PATH_backup.txt",
    [array]$IncludePaths = @(
        "C:\Program Files\*",
        "C:\Program Files (x86)\*",
        "C:\ProgramData\*",
        (Join-Path $Env:USERPROFILE "*")
    )
)

# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    exit
}

# Create the target directory if it doesn't exist
if (-not (Test-Path $SymlinkPath)) {
    New-Item -ItemType Directory -Path $SymlinkPath
	Write-Host "Created symlink target directory: $SymlinkPath"
}

# Get all directories from the PATH environment variable
$originalPath = $Env:PATH
$pathDirs = $originalPath -split ';'

# Back up PATH
if (-not (Test-Path $BackupPath)) {
    Set-Content -Path $BackupPath -Value $originalPath
    Write-Host "Original PATH backed up to $BackupPath"
} else {
    Write-Host "Backup already exists at $BackupPath. Skipping backup creation."
}

# Filter only valid directories based on user-defined paths
$filteredDirs = $pathDirs | Where-Object { $curDir = $_;
    ($curDir -ne $SymlinkPath) -and (Test-Path $curDir) -and (($IncludePaths | Where-Object { $curDir -like $_ }).Count -gt 0)
}
Write-Host "Directories to prune: $filteredDirs"

# Initialize counters for summary
$symlinkCreated = 0
$symlinkSkipped = 0
$foldersCreated = 0

# Iterate through each directory in PATH
foreach ($dir in $filteredDirs) {
	Write-Host "Processing directory: $dir"

    # Recursively get all files and folders
    $items = Get-ChildItem -Path $dir -Recurse -Force
    foreach ($item in $items) {
        # Calculate the relative path from the source directory
        $relativePath = $item.FullName.Substring($dir.Length).TrimStart("\")
        $targetPath = Join-Path $SymlinkPath $relativePath

        if ($item.PSIsContainer) {
            # Ensure the folder exists in the target directory
            if (-not (Test-Path $targetPath)) {
                New-Item -ItemType Directory -Path $targetPath | Out-Null
                Write-Host "Created folder: $targetPath"
                $foldersCreated++
            }
        } else {
		    # Skip if the symlink already exists
            if (Test-Path $targetPath) {
                Write-Host "Symlink for $($item.Name) already exists. Skipping..."
                $symlinkSkipped++
                continue
            }

            # Create a symlink for the file
            try {
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $item.FullName | Out-Null
                Write-Host "Created symlink: $($item.FullName) -> $targetPath"
                $symlinkCreated++
            } catch {
                Write-Warning "Failed to create symlink for $($item.FullName): $_"
            }
        }
    }
}

# Remove filtered directories from the PATH environment variable
$remainingPathDirs = ($pathDirs | Where-Object { $_ -notin $filteredDirs }) -join ';'

# Add the new symlink to PATH
if ($pathDirs -notcontains $SymlinkPath) {
    $remainingPathDirs += ";$SymlinkPath"
}

# Update the PATH environment variable
Write-Host "Old PATH: $originalPath"
[System.Environment]::SetEnvironmentVariable("Path", $remainingPathDirs, [System.EnvironmentVariableTarget]::Machine)
Write-Host "New PATH: $remainingPathDirs"

# Summary output
Write-Host "Summary:"
Write-Host " - Folders created: $foldersCreated"
Write-Host " - Symlinks created: $symlinkCreated"
Write-Host " - Symlinks skipped: $symlinkSkipped"
Write-Host "All symbolic links have been created in $SymlinkPath, and the filtered directories have been removed from PATH."
