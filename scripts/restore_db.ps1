# scripts/restore_db.ps1

$latest=(Get-ChildItem -Path .\\backups\\postgres_backup_*.tar | Sort-Object LastWriteTime -Descending | Select-Object -First 1);

if (-not $latest) {
    Write-Host 'No backup found in .\\backups'
    exit 1
}

Write-Host "Restoring backup: $($latest.Name)"

podman compose down
podman volume rm postgres_pgdata -f
podman volume create postgres_pgdata

# Use double quotes inside the sh -c command, PowerShell handles the escaping when executed
$command = "tar -xvf /backups/$($latest.Name) -C /data"

podman run --rm -v ${PWD}\\backups:/backups -v postgres_pgdata:/data busybox sh -c $command

podman compose up -d
