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
docker exec -it sandboxer-mariadb-1 bash
mariadb -uroot -p
```

To open phpMyAdmin, open `localhost:40001` in a browser.

If port numbers are annoying, you can simplyfy access via standard port **80**. E.g. By adding a custom lan host-name to the host file in your OS, then adjust the web server v-host to handle the custom hostname. I suggest using ".localhost". E.g. `phpmyadmin.localhost`.
E.g. `/etc/host` on mac/linux, and `c:\Windows\System32\Drivers\etc\hosts` on Windows!


> [!WARNING]  
> **Do NOT use this for deployment on production!**
>
> Ports may be exposed directly on the host WAN!!
