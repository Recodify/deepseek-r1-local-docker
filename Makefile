# Declare all phony targets (targets that don't represent files)
.PHONY: setup-gpu test-gpu docker-up-linux-gpu docker-up-mac-gpu docker-up-windows-gpu docker-up-cpu-only watch-gpu clean-up run-demo run-status-check

# Install NVIDIA drivers and required GPU dependencies
setup-gpu:
	@sudo ./scripts/setup-gpu.sh

# Test GPU availability and NVIDIA driver installation by running a test container
test-gpu:
	@docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

run-status-check:
	@sudo ./scripts/status-check.sh

# Install Docker and required dependencies
install-docker:
	@sudo ./scripts/install-docker.sh

# Start Docker containers with GPU support on Linux
docker-up-linux-gpu:
	@sudo docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d

# Start Docker containers with GPU support on macOS
docker-up-mac-gpu:
	@sudo docker compose -f docker-compose.yml -f docker-compose.mac.yml up -d

# Start Docker containers with GPU support on Windows
docker-up-windows-gpu:
	@sudo docker compose -f docker-compose.yml -f docker-compose.gpu.yml -f docker-compose.windows.yml up -d

# Start Docker containers without GPU support (CPU only)
docker-up-cpu-only:
	@sudo docker compose up -d

# Monitor GPU usage and statistics in real-time (updates every 0.5 seconds)
watch-gpu:
	@watch -n 0.5 nvidia-smi

# Setup the logging chain for TCP monitoring
setup-watch-tcp:
	@sudo ./scripts/watch-tcp-setup.sh

# Watch TCP connections initiated by the containers, in real-time
watch-tcp-raw:
	@echo "Watching TCP connections initiated by the containers..."
	@sudo ./scripts/watch-tcp.sh

# Watch TCP connections in real-time with color-coded output
watch-tcp:
	@echo "Watching TCP connections initiated by the containers..."
	@sudo ./scripts/watch-tcp.sh | python3 ./scripts/log_parser.py

# Watch only the TCP connections to the outside world that are initiated by the containers
watch-tcp-external-only:
	@echo "Watching TCP connections to the outside world initiated by the containers..."
	@sudo ./scripts/watch-tcp.sh | python3 ./scripts/log_parser.py --external-only

# Stop and remove all running containers
clean-up:
	@sudo docker compose down

run-demo:
	@rm -rf ./demo-deploy
	@./run-demo.sh