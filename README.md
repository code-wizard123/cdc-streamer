## Local development

This Compose setup runs PostgreSQL, Spark 4.1.3 with Python 3.12, and JupyterLab. The Jupyter server and its notebook files are local; the kernel submits jobs to the Spark master over the private Compose network. Published ports bind only to `127.0.0.1`.

### Configure local values

Copy `.env.example` to `.env` and fill in the local configuration values there. `.env` is ignored by Git. Set `JUPYTER_UID` and `JUPYTER_GID` to the values returned by `id -u` and `id -g`; this lets Jupyter save notebooks as the host user without running the server as root.

Set `POSTGRES_SECRET_FILE` to `./secrets/postgres_password`. Create the PostgreSQL password file once; this guarded command will not overwrite an existing credential:

```sh
mkdir -p secrets
if [ ! -f secrets/postgres_password ]; then
	openssl rand -hex 32 > secrets/postgres_password
fi
chmod 600 secrets/postgres_password
```

The password file and the `secrets/` directory are ignored by Git and excluded from Docker build contexts. Compose mounts the file as a local secret; the password is not stored in Compose YAML or passed as a normal environment variable. Local Compose secrets are file mounts, not an encrypted secrets manager. Do not share the password file or rendered configuration output.

PostgreSQL reads the secret when it initializes an empty data directory. This setup creates a new named volume and does not remove any existing anonymous Postgres volumes. Replacing the secret file later does not rotate the password in an already initialized database.

### Start services

```sh
docker compose up -d --build postgres spark-master spark-worker jupyter
docker compose ps
```

JupyterLab is available at `http://127.0.0.1:<JUPYTER_HOST_PORT>`. Get the generated login token from the local Jupyter logs:

```sh
docker compose logs jupyter
```

The Spark master and worker UIs are available at the loopback ports configured by `SPARK_MASTER_UI_HOST_PORT` and `SPARK_WORKER_UI_HOST_PORT`. PostgreSQL and the Spark master RPC port are also published only on their configured loopback ports.

Open `notebooks/example.ipynb` in JupyterLab and run its cells. It creates a Spark session at `spark://spark-master:7077`, builds a small DataFrame, and calls `show()`. The notebook directory is bind-mounted, so notebook edits remain in the repository.

To run the notebook smoke check without opening a browser:

```sh
docker compose exec -T jupyter jupyter nbconvert \
	--to notebook --execute --ExecutePreprocessor.timeout=120 \
	/opt/cdc-streamer/notebooks/example.ipynb \
	--output /tmp/example-executed.ipynb
```

### CLI commands

Build the application image:

```sh
docker compose build main
```

Run the entrypoint or example command:

```sh
docker compose run --rm --no-deps main
docker compose run --rm --no-deps main cdc-streamer-example
```

Both commands are currently scaffolds that print a message and exit. CDC processing and long-running behavior will be implemented later. The notebook is the current working Spark example.

### Stop services

```sh
docker compose down
```

This stops and removes the containers but preserves the named PostgreSQL volume and notebook files. Removing the volume is destructive and deletes the local database.
