# sandboxer

Basic sandboxing environment for all kinds of experiments. The idea is to mainly use existing images to keep it as simple as possible for new Docker users.


Currently insecure for production and only intended for educational purposes and quick testing + learning Docker, and I wanted it to be very simple to spin up without having to think about file permissions on the host. Etc. Etc.

Run the containers:
```
docker compose up
```

Stop the containers:
```
docker compose stop
```
Or hit `CTRL` + `C` inside your console window.

View your running containers after starting them:
```
docker ps
```

If you need CLI access to the database:

```
docker exec -it sandboxer-db bash
mariadb -uroot -p
```

The `root` password is `superduperroot`.

- To open phpMyAdmin, open `http://database.localhost` in a browser.
- To open the default (localhost) website host, open `http://localhost`

Published ports bind to `127.0.0.1` (IPv4 loopback) for access from the Docker host.
For a database client on the host, connect to `127.0.0.1:3306`; containers continue
to use `db:3306`. Access from another device requires an intentional change to
the port bindings and a review of the development credentials.

After changing port bindings, run `docker compose up -d` to recreate affected
containers. `docker compose restart` does not apply Compose configuration changes.
Use `docker compose ps` to confirm published ports show `127.0.0.1`.

> [!WARNING]  
> **Do NOT use this for deployment on production!**
>
> Local-only port bindings do not make the development credentials or configuration suitable for production.
