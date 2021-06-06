# NGINX
Super small and easy to setup NGINX web server.

## Running the server
```bash
docker run --detach --name nginx --publish 80:80 --publish 443:443 hetsh/nginx
```

## Stopping the container
```bash
docker stop nginx
```

## Configuration
The default nginx config includes all config files from `/etc/nginx/http.d` that end with `.conf`.
The config volume can be mounted read only:
```bash
--mount type=bind,readonly,source="/path/to/hosts",target="/etc/nginx/http.d"
```
To provide a custom nginx config override the default one:
```bash
--mount type=bind,readonly,source="/path/to/nginx.conf",target="/etc/nginx/nginx.conf"
```
There are also volumes for sockets, and logs:
```bash
--mount type=bind,readonly,source="/path/to/sockets",target="/run/nginx"
--mount type=bind,readonly,source="/path/to/logs",target="/var/log/nginx"
```

## Automate startup and shutdown via systemd
The systemd unit can be found in my GitHub [repository](https://github.com/Hetsh/docker-nginx).
```bash
systemctl enable nginx --now
```
By default, the systemd service assumes `/apps/nginx/config` for hosts, `/srv` for website data and `/etc/localtime` for timezone.
Since this is a personal systemd unit file, you might need to adjust some parameters to suit your setup.

## Fork Me!
This is an open project (visit [GitHub](https://github.com/Hetsh/docker-nginx)).
Please feel free to ask questions, file an issue or contribute to it.