# PrunePath

A PowerShell script to create symlinks for and prune PATH entries for those with many applications.

## What Does It Do?

The PATH environment variable is iterated, and each directory's contents are recursively linked to `C:\Refs`. The PATH environment
variable is then pruned of the directories that had their contents linked. In case an error occurs, the original PATH variable is
backed up to `.\PATH_backup.txt`.

The following directories's contents are included in the PATH search by default:

* `C:\Program Files\*`
* `C:\Program Files (x86)\*`
* `C:\Program Data\*`
* `C:\Users\$USER\*`

Note that this is only a filter, meaning **only the full directories as they appear in PATH are searched** rather than each of the filter directories.

## Considerations

* Symbolic links logically act as normal files but physically are just links to files, meaning the `C:\Refs` reads "0 bytes" when you view its properties.
* Each PATH entry's subdirectories are recreated with the files linked to prevent applications from having errors if they use shared libraries or files outside of their base directory.
* The resulting PATH will (hopefully) be much shorter than it was to start, meaning you won't need to use the Registry Editor to change it if you've exceeded to PATH limit.
* Administrator rights are required for creating symlinks. Please view the source code to check for fishy business at your pleasure.

## How to Use

1. Download and extract the source code.
2. Open PowerShell in administrator mode.
3. Temporarily enable administrator PS scripts: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
4. Run the PS script as administrator (required for symlinks): `.\PathSymlinks.ps1`

## Options

* `-BackupPath "D:\BACKUP_PATH.txt"`: The path to back up PATH to. Defaults to `.\PATH_backup.txt`.
* `-SymlinkPath "D:\Refs"`: The path where symlinks are stored. It is highly recommended to **use no spaces** since some ported applications/scripts do not support quotes. Defaults to `C:\Refs`.
* `-IncludePaths @("C:\Program Files\*", "C:\Python\*", "C:\Applications\*")`: Paths to include in the search when found in PATH. Symlinks will be created for their files and they will be removed from PATH.
  * Note that **the `*` is required** unless you are specifying a single directory to match!
