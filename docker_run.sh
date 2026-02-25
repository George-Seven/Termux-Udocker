#!/bin/bash
echo $(dirname "${BASH_SOURCE[0]}")
source "$(dirname "${BASH_SOURCE[0]}")/source.env"
cd "$(dirname "${BASH_SOURCE[0]}")"

# Function to display usage information
usage() {
    echo "Usage:"
    echo "  $0 [docker options] --name <container name> <image[:tag]>"
    echo "  $0 [docker options] --name <container name> --entrypoint <command> <image[:tag]> [arguments...]"
    echo ""
    echo "Examples:"
    echo "  $0 --name mycontainer nginx:latest"
    echo "  $0 -d -p 8080:80 --name webserver nginx:latest"
    echo "  $0 --rm -it --name interactive --entrypoint bash ubuntu:20.04"
    echo "  $0 -v /host/path:/container/path --name mycontainer --entrypoint bash ubuntu:20.04 -c 'echo hello'"
    exit 1
}

# Check if we have at least 3 arguments (minimum required)
if [ $# -lt 3 ]; then
    echo "Error: Insufficient arguments"
    usage
fi

# Initialize variables
name_flag=false
entrypoint_flag=false
container_name=""
image=""
entrypoint_cmd=""
docker_options=()
docker_args=()

# Parse arguments
i=1
while [ $i -le $# ]; do
    case "${!i}" in
        --name)
            name_flag=true
            ((i++))
            if [ $i -le $# ]; then
                container_name="${!i}"
            else
                echo "Error: --name requires a container name"
                usage
            fi
            ;;
        --entrypoint)
            entrypoint_flag=true
            ((i++))
            if [ $i -le $# ]; then
                entrypoint_cmd="${!i}"
            else
                echo "Error: --entrypoint requires a command"
                usage
            fi
            ;;
        *)
            if [ "$name_flag" = false ]; then
                # Arguments before --name are docker options
                docker_options+=("${!i}")
            else
                # Arguments after --name are image and additional arguments
                docker_args+=("${!i}")
            fi
            ;;
    esac
    ((i++))
done

# Validate that we have --name
if [ "$name_flag" = false ]; then
    echo "Error: --name argument is required"
    usage
fi

# Validate that we have a container name
if [ -z "$container_name" ]; then
    echo "Error: Container name cannot be empty"
    usage
fi

# Validate that we have at least one additional argument (the image)
if [ ${#docker_args[@]} -eq 0 ]; then
    echo "Error: Image name is required"
    usage
fi

# Extract the image (first argument in docker_args)
image="${docker_args[0]}"

# Validate image format (basic check for image[:tag])
if [[ ! "$image" =~ ^[a-zA-Z0-9./-]+(:[a-zA-Z0-9.-]+)?$ ]]; then
    echo "Error: Invalid image format. Expected format: image[:tag]"
    usage
fi

# example: -v $DATA_DIR/logs:/etc/logs
DATA_DIR="$(pwd)/data-$container_name"

udocker_check
# necessary step to remove previous container
udocker_prune
# obsolete?
udocker_create "$container_name" "$image"


# Build and execute the docker run command
if [ "$entrypoint_flag" = true ]; then
    # Pattern: [docker_options] --name <container_name> --entrypoint <command> <image[:tag]> [arguments...]
    if [ -z "$entrypoint_cmd" ]; then
        echo "Error: Entrypoint command cannot be empty"
        usage
    fi

    # Remove the image from docker_args to get remaining arguments
    remaining_args=("${docker_args[@]:1}")

    echo "Running: udocker_run ${docker_options[*]} --entrypoint $entrypoint_cmd $container_name ${remaining_args[*]}"
    udocker_run "${docker_options[@]}" --entrypoint "$entrypoint_cmd" "$container_name" "${remaining_args[@]}"
else
    # Pattern: [docker_options] --name <container_name> <image[:tag]>
    if [ ${#docker_args[@]} -gt 1 ]; then
        echo "Error: Too many arguments for basic pattern. Use --entrypoint if you need to pass additional arguments."
        usage
    fi

    echo "Running: udocker_run ${docker_options[*]} $container_name"
    udocker_run "${docker_options[@]}" "$container_name"
fi

# Capture and display the exit code
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "Docker container '$container_name' completed successfully"
else
    echo "Docker container '$container_name' exited with code $exit_code"
fi

exit $exit_code

