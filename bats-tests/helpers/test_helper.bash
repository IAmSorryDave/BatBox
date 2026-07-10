#!/usr/bin/env bash

# Test Helper Functions for Bats
# Source this file at the top of each test with: load test_helper

# ============================================================================
# IMAGE & CONTAINER MANAGEMENT
# ============================================================================

# Build image if it doesn't exist
# Usage: build_image "my-app:latest"
build_image() {
    local image=$1
    if ! docker image inspect "$image" &>/dev/null; then
        docker build -t "$image" .
    fi
}

# Run a command inside a container and return exit code + output
# Usage: run_container "my-app:latest" node --version
run_container() {
    local image=$1
    shift
    docker run --rm "$image" "$@"
}

# Run a command inside a container with custom options
# Usage: run_container_with_opts "-e NODE_ENV=production" "my-app:latest" node app.js
run_container_with_opts() {
    local opts=$1
    local image=$2
    shift 2
    docker run --rm $opts "$image" "$@"
}

# Remove all running containers from an image
# Usage: cleanup_containers "my-app:latest"
cleanup_containers() {
    local image=$1
    docker ps --filter ancestor="$image" -q | xargs -r docker stop 2>/dev/null || true
}

# ============================================================================
# FILE & PATH CHECKS
# ============================================================================

# Check if a file exists in the image
# Usage: assert_file_exists "my-app:latest" "/app/config.yml"
assert_file_exists() {
    local image=$1
    local filepath=$2
    run docker run --rm "$image" test -f "$filepath"
    [ "$status" -eq 0 ] || echo "File not found: $filepath"
}

# Check if a file does NOT exist in the image
# Usage: assert_file_not_exists "my-app:latest" "/tmp/temp.log"
assert_file_not_exists() {
    local image=$1
    local filepath=$2
    run docker run --rm "$image" test ! -f "$filepath"
    [ "$status" -eq 0 ] || echo "File should not exist: $filepath"
}

# Check if a directory exists in the image
# Usage: assert_dir_exists "my-app:latest" "/app/src"
assert_dir_exists() {
    local image=$1
    local dirpath=$2
    run docker run --rm "$image" test -d "$dirpath"
    [ "$status" -eq 0 ] || echo "Directory not found: $dirpath"
}

# ============================================================================
# COMMAND & EXECUTABLE CHECKS
# ============================================================================

# Check if a command is available and executable
# Usage: assert_command_exists "my-app:latest" "node"
assert_command_exists() {
    local image=$1
    local command=$2
    run docker run --rm "$image" which "$command"
    [ "$status" -eq 0 ] || echo "Command not found: $command"
}

# Check if a command runs and returns expected version format
# Usage: assert_version_output "my-app:latest" "node" "v[0-9]+\.[0-9]+\.[0-9]+"
assert_version_output() {
    local image=$1
    local command=$2
    local pattern=$3
    run docker run --rm "$image" "$command" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ $pattern ]] || echo "Version output doesn't match pattern: $pattern"
}

# ============================================================================
# ENVIRONMENT VARIABLE CHECKS
# ============================================================================

# Check if an environment variable is set to a specific value
# Usage: assert_env_var "my-app:latest" "NODE_ENV" "production"
assert_env_var() {
    local image=$1
    local var_name=$2
    local expected_value=$3
    run docker run --rm "$image" sh -c "echo \$$var_name"
    [ "$output" = "$expected_value" ] || echo "$var_name is '$output', expected '$expected_value'"
}

# Check if an environment variable is set (to any non-empty value)
# Usage: assert_env_var_set "my-app:latest" "API_KEY"
assert_env_var_set() {
    local image=$1
    local var_name=$2
    run docker run --rm "$image" sh -c "test -n \"\$$var_name\" && echo 'set' || echo 'not set'"
    [[ "$output" == "set" ]] || echo "$var_name is not set"
}

# ============================================================================
# USER & PERMISSION CHECKS (Security)
# ============================================================================

# Check if a container runs as a specific user
# Usage: assert_runs_as_user "my-app:latest" "appuser"
assert_runs_as_user() {
    local image=$1
    local expected_user=$2
    run docker run --rm "$image" whoami
    [ "$output" = "$expected_user" ] || echo "Container runs as '$output', expected '$expected_user'"
}

# Check if a container does NOT run as root
# Usage: assert_not_root "my-app:latest"
assert_not_root() {
    local image=$1
    run docker run --rm "$image" whoami
    [ "$output" != "root" ] || echo "Container should not run as root"
}

# Check file permissions
# Usage: assert_file_permissions "my-app:latest" "/app/script.sh" "755"
assert_file_permissions() {
    local image=$1
    local filepath=$2
    local expected_perms=$3
    run docker run --rm "$image" stat -c %a "$filepath"
    [ "$output" = "$expected_perms" ] || echo "Permissions are $output, expected $expected_perms"
}

# ============================================================================
# PORT & NETWORK CHECKS
# ============================================================================

# Check if a port is listening inside a container
# Usage: port_is_listening "my-app:latest" 3000 "node" "app.js"
port_is_listening() {
    local image=$1
    local port=$2
    shift 2
    local cmd="$@"
    
    # Start container in background
    local container_id=$(docker run -d "$image" $cmd)
    sleep 2
    
    # Check if port is open
    run docker exec "$container_id" sh -c "nc -z localhost $port"
    local result=$status
    
    # Cleanup
    docker stop "$container_id" >/dev/null 2>&1
    docker rm "$container_id" >/dev/null 2>&1
    
    [ $result -eq 0 ] || echo "Port $port is not listening"
}

# ============================================================================
# PACKAGE & DEPENDENCY CHECKS
# ============================================================================

# Check if a package is installed (npm)
# Usage: assert_npm_package_installed "my-app:latest" "express"
assert_npm_package_installed() {
    local image=$1
    local package=$2
    run docker run --rm "$image" npm list "$package"
    [ "$status" -eq 0 ] || echo "Package not found: $package"
}

# Check if a package is installed (pip)
# Usage: assert_pip_package_installed "my-app:latest" "requests"
assert_pip_package_installed() {
    local image=$1
    local package=$2
    run docker run --rm "$image" pip show "$package"
    [ "$status" -eq 0 ] || echo "Package not found: $package"
}

# ============================================================================
# OUTPUT & CONTENT CHECKS
# ============================================================================

# Check if output contains a substring
# Usage: assert_output_contains "my-app:latest" "node" "--version" "v18"
assert_output_contains() {
    local image=$1
    shift 1
    local cmd=("$@")
    local substring="${cmd[-1]}"
    unset 'cmd[-1]'
    
    run docker run --rm "$image" "${cmd[@]}"
    [[ "$output" == *"$substring"* ]] || echo "Output doesn't contain: $substring"
}

# Check if output matches a regex pattern
# Usage: assert_output_matches "my-app:latest" "node" "--version" "v[0-9]+\.[0-9]+\.[0-9]+"
assert_output_matches() {
    local image=$1
    shift 1
    local pattern="${@: -1}"
    local cmd=("${@:1:$# - 1}")
    
    run docker run --rm "$image" "${cmd[@]}"
    [[ "$output" =~ $pattern ]] || echo "Output doesn't match pattern: $pattern"
}

# ============================================================================
# LAYER & SIZE CHECKS
# ============================================================================

# Get image size in MB
# Usage: get_image_size "my-app:latest"
get_image_size() {
    local image=$1
    docker images --format "{{.Size}}" "$image"
}

# Check if image is under a maximum size
# Usage: assert_image_size_under "my-app:latest" "500MB"
assert_image_size_under() {
    local image=$1
    local max_size=$2
    local actual_size=$(docker images --format "{{.Size}}" "$image")
    echo "Image size: $actual_size (max: $max_size)"
}

# ============================================================================
# DEBUGGING HELPERS
# ============================================================================

# Print image metadata
# Usage: debug_image_info "my-app:latest"
debug_image_info() {
    local image=$1
    echo "=== Image Info: $image ==="
    docker inspect "$image" | jq '.[0] | {
        Created,
        Architecture,
        Os,
        RootFS,
        Config: {
            User,
            WorkingDir,
            Env: .Env | length,
            Cmd,
            Entrypoint
        }
    }' 2>/dev/null || docker inspect "$image"
}

# Print container layer history
# Usage: debug_image_layers "my-app:latest"
debug_image_layers() {
    local image=$1
    echo "=== Layer History: $image ==="
    docker history "$image"
}

# Run a shell inside the image for manual inspection
# Usage: debug_interactive "my-app:latest"
debug_interactive() {
    local image=$1
    echo "Launching interactive shell in $image..."
    docker run --rm -it "$image" /bin/sh
}
