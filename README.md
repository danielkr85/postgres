# Postgres Docker Compose

This repository contains a minimal Docker Compose configuration to run a PostgreSQL instance locally.

Files added
- `docker-compose.yml` — Compose file that defines a `db` service using the official Postgres image, a host bind mount by default (./pgdata), and a healthcheck.
- `.env` — Default environment variables (username, password, database).

Quick start (PowerShell)

1. Optionally edit `.env` to change credentials.

2. Start Postgres in the background:

```
docker compose up -d
```

3. Check status and logs:

```
docker compose ps
docker compose logs -f db
```

4. Connect with psql inside the container:

```
docker compose exec db psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB
```

If you prefer a host-based psql client, use the values from `.env` to connect on port `5432` (for example using a GUI client or `psql` on the host).

Notes
- The service is configured to persist database files into the host folder `./pgdata` by default (so data is directly visible in the repository folder).
- To remove containers while keeping the `pgdata` folder, run `docker compose down`.
- If you prefer Docker-managed storage instead, switch back to the named volume by editing `docker-compose.yml` (see the "Persisting data on the host" section).

Persisting data on the host (optional)

If you'd prefer the database files to be stored in a folder inside this repository (useful for simple backups or inspection), you can use a host bind mount instead of the named Docker volume.

1. Create a `pgdata` folder at the repository root (PowerShell):

```
New-Item -ItemType Directory -Path .\pgdata
```

2. Allow Docker access to your drive (Docker Desktop on Windows must have the drive/shared resource enabled).

3. Edit `docker-compose.yml` and switch the `volumes` entry for the `db` service from the named volume:

```
- postgres_data:/var/lib/postgresql/data
```

to the host bind mount (uncomment):

```
# - ./pgdata:/var/lib/postgresql/data
```

so it becomes:

```
- ./pgdata:/var/lib/postgresql/data
```

4. Restart the stack:

```
docker compose down
docker compose up -d
```

VS Code Tasks

This project includes several VS Code tasks to help manage the Postgres instance. To run a task:
1. Open the Command Palette (Ctrl+Shift+P)
2. Type "Tasks: Run Task"
3. Select one of these tasks:

Database Control:
- `Start Postgres`: Starts the database container
- `Stop Postgres`: Stops and removes containers (keeps the data volume)
- `Restart Postgres`: Restarts the container
- `Clean All`: Removes containers AND volume (DANGER: deletes all data)

Monitoring:
- `View Logs`: Shows live container logs in a dedicated terminal
- `List Volumes`: Shows all Podman volumes including pgdata
- `psql Shell`: Opens a PostgreSQL interactive shell inside the container

Backup:
- `Backup Volume`: Exports the volume data to `./backups/postgres_backup_[timestamp].tar`

Additional Tasks

- `Restore Latest Backup (DANGER)`: Restores the most recent backup from `./backups` into the `pgdata` volume. This task will stop the stack, remove the named volume `pgdata`, recreate it, extract the backup into the volume, and restart the stack. Use with caution.
- `Create Database (appdb)`: Runs `CREATE DATABASE appdb;` inside the running container. Change the database name in the task if you prefer a different name.
- `Show DB Sizes`: Runs a query to display all databases and their sizes.

Keyboard Shortcuts (workspace)

The workspace includes a set of suggested keybindings you can enable in VS Code (see `.vscode/keybindings.json`) — default examples are:

- Ctrl+Alt+S — Start Postgres
- Ctrl+Alt+K — Stop Postgres
- Ctrl+Alt+R — Restart Postgres
- Ctrl+Alt+L — View Logs
- Ctrl+Alt+B — Backup Volume
- Ctrl+Alt+Shift+R — Restore Latest Backup (DANGER)

Notes
- The restore task expects a backup file named like `postgres_backup_YYYYMMDD_HHMMSS.tar` inside the `backups` folder. The task picks the most recent one.
- All tasks use `podman` commands (adjust to `docker` if you prefer Docker Desktop). If you want Docker instead, I can add duplicate tasks that use `docker compose` and `docker volume` commands.

Notes and caveats
- Data is persisted in a named Podman volume `pgdata` and survives container restarts/recreation
- Use `Clean All` task with caution - it will delete all database data
- Backups are stored in the `backups` directory with timestamps

Exposing the Postgres port for external access

By default this compose file publishes Postgres on port 5432 and is now explicitly bound to all host network interfaces so other machines on your LAN can connect.

1. Ensure your Windows firewall allows inbound TCP connections on port 5432 (or the port you choose). In PowerShell (run as Administrator) you can add a rule:

```
New-NetFirewallRule -DisplayName "Allow Postgres 5432" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow
```

2. If you only want access from specific hosts, update `docker-compose.yml` to bind to a specific host IP instead of `0.0.0.0` (for example `192.168.1.100:5432:5432`).

3. Test from another machine on the same network (replace `<HOST_IP>` with the host machine IP):

```
# using psql on a remote machine
psql -h <HOST_IP> -p 5432 -U postgres -d postgres
```

4. If you're using `podman compose` or other runtimes, published ports are handled similarly but check the runtime docs — podman on Windows can behave differently than Docker Desktop.

Security notes
- Do not expose Postgres to the public internet without additional protections (VPN, SSH tunnel, firewall rules). If you must, use strong passwords, restrict allowed client IPs, and consider TLS/SSL.
- You can also tunnel connections over SSH instead of opening the DB port directly:

```
# Example SSH local port forward
ssh -L 5432:localhost:5432 user@<HOST_IP>
# Then connect to localhost:5432 on your client machine
psql -h localhost -p 5432 -U postgres -d postgres
```


