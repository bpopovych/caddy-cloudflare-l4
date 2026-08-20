FROM --platform=$BUILDPLATFORM caddy:builder-alpine AS builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOARM=${TARGETVARIANT#v} \
    xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-l4

# Set the capability in this stage, which runs on the build platform: doing it
# in the final stage would need emulation to execute setcap for foreign targets.
# BuildKit preserves the security.capability xattr across COPY --from.
RUN setcap cap_net_bind_service=+ep /usr/bin/caddy

FROM caddy:alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
