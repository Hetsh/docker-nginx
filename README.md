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
The default nginx config includes all config files from `/etc/nginx/conf.d` that end with `.conf`.
The config volume can be mounted read only:
```bash
--mount type=bind,readonly,source="/path/to/hosts",target="/etc/nginx/conf.d"
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
```bash
systemctl enable nginx --now
```
The systemd unit can be found in my [GitHub](https://github.com/Hetsh/docker-nginx) repository.
By default, the systemd service assumes `/etc/nginx/conf.d` for hosts and `/srv` for the actual websites.
You need to adjust these to suit your setup.

## Fork Me!
This is an open project (visit [GitHub](https://github.com/Hetsh/docker-nginx)). Please feel free to ask questions, file an issue or contribute to it.