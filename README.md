# caddy-cloudflare-l4

Custom [Caddy](https://caddyserver.com/) Docker image with:

- [caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare) — DNS-01 ACME challenge support
- [mholt/caddy-l4](https://github.com/mholt/caddy-l4) — layer 4 (TCP/UDP) proxying and protocol multiplexing

Built automatically from the official `caddy:alpine` image for all upstream Linux platforms.

## Supported Platforms

`linux/amd64`, `linux/arm64`, `linux/arm/v6`, `linux/arm/v7`, `linux/ppc64le`, `linux/riscv64`, `linux/s390x`

## Usage

```bash
docker pull bpopovych/caddy-cloudflare-l4
```

### Docker Run

```bash
docker run -d \
  --name caddy \
  -p 80:80 -p 443:443 -p 443:443/udp \
  -v caddy_data:/data \
  -v caddy_config:/config \
  -v $PWD/Caddyfile:/etc/caddy/Caddyfile \
  -e CF_API_TOKEN=your-cloudflare-api-token \
  bpopovych/caddy-cloudflare-l4
```

### Docker Compose

```yaml
services:
  caddy:
    image: bpopovych/caddy-cloudflare-l4
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    environment:
      - CF_API_TOKEN=your-cloudflare-api-token

volumes:
  caddy_data:
  caddy_config:
```

### Caddyfile Example

```
example.com {
    tls {
        dns cloudflare {env.CF_API_TOKEN}
    }

    reverse_proxy localhost:8080
}
```

## Cloudflare API Token

Create a token in the [Cloudflare dashboard](https://dash.cloudflare.com/profile/api-tokens) with the following permissions:

- **Zone / Zone / Read**
- **Zone / DNS / Edit**

Set the token as the `CF_API_TOKEN` environment variable.

## Layer 4 Proxying

`caddy-l4` is configured through the `layer4` block in the Caddyfile [global options](https://caddyserver.com/docs/caddyfile/options), which must come first in the file. Remember to publish any extra ports it listens on (`-p`/`ports:`).

Plain TCP forwarding:

```
{
    layer4 {
        :5432 {
            route {
                proxy 10.0.0.5:5432
            }
        }
    }
}
```

Matching on the protocol, e.g. routing SSH and HTTPS off the same port:

```
{
    layer4 {
        :443 {
            @ssh ssh
            route @ssh {
                proxy 10.0.0.5:22
            }
            route {
                proxy 127.0.0.1:8443
            }
        }
    }
}
```

TLS termination in front of a plain backend, reusing Caddy's Cloudflare-issued certificate:

```
{
    layer4 {
        :9000 {
            route {
                tls
                proxy 127.0.0.1:9001
            }
        }
    }
}

example.com {
    tls {
        dns cloudflare {env.CF_API_TOKEN}
    }
}
```

See the [caddy-l4 README](https://github.com/mholt/caddy-l4#readme) for the full matcher and handler reference.

## Automatic Updates

A GitHub Actions workflow runs daily to check for upstream changes to `caddy:alpine` and rebuilds the image when updates are detected. The image is also rebuilt on every push to `main`.

`caddy-l4` has no tagged releases, so builds track the latest commit on its default branch.

## GitHub Actions Setup

To enable automated builds, add these secrets to your GitHub repository:

- `DOCKERHUB_USERNAME` — your Docker Hub username
- `DOCKERHUB_TOKEN` — a Docker Hub [access token](https://hub.docker.com/settings/security)
