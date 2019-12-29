# NGINX
Super small NGINX web server, inteded to be used as foundation for web-apps.

## Configuration
The default nginx config includes all config files from `/etc/nginx/conf.d` that end with `.conf`.
The config volume can be mounted read only:
```bash
--mount type=bind,readonly,source="/path/to/server_blocks",target="/etc/nginx/conf.d"
```
To provide a custom nginx config override the default one:
```bash
--mount type=bind,readonly,source="/path/to/nginx.conf",target="/etc/nginx/nginx.conf"
```

## Fork Me!
This is an open project (visit [GitHub](https://github.com/Hetsh/docker-nginx)). Please feel free to ask questions, file an issue or contribute to it.