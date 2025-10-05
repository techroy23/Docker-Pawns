# Pawns Docker Image

A minimal Alpine based Docker image for running the **Pawns**.

## ✨ Features
- 🪶 Lightweight Alpine Linux base image.
- 🔑 Configurable environment variable (`EMAIL`, `PASSWORD`).
- 🖥️ Multi‑arch support: `amd64` and `arm64`.
- 🔄 Auto‑update support with `--pull=always`.
- 🌐 Proxy support via Redsocks.

## ⚡ Usage
- Before running the container, increase socket buffer sizes (required for high‑throughput streaming).
- To make these settings persistent across reboots, add them to /etc/sysctl.conf or a drop‑in file under /etc/sysctl.d/.

```bash
sudo sysctl -w net.core.rmem_max=8000000
sudo sysctl -w net.core.wmem_max=8000000
```

## 🧩 Environment variables
| Variable | Requirement | Description |
|----------|-------------|-------------|
| `EMAIL`  | Required    | Your Pawns email address. Container exits if not provided. |
| `PASSWORD` | Required  | Your Pawns password. Container exits if not provided. |
| `PROXY`  | Optional    | External proxy endpoint in the form `host:port`. |


## ⏱️ Run the container:
```bash
docker run -d \
  --name=pawns \
  --pull=always \
  --restart=always \
  --privileged \
  --log-driver=json-file \
  --log-opt max-size=5m \
  --log-opt max-file=3 \
  -e EMAIL=example@gmail.com \
  -e PASSWORD=mYv3rYsEcUr3dP@sSw0rD \
  -e PROXY=123.456.789.012:34567 \
  techroy23/docker-pawns:latest
```

# Invite Link
### https://pawns.app/?r=an2kin