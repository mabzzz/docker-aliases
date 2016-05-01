#!/bin/bash

function __dkcheck () {
    # Check Docker directory
    DOCKER_DIRECTORY=$(pwd)
    if [ -n "$1" ]; then
        DOCKER_DIRECTORY=$DOCKER_DIRECTORY/${1%/}
    fi
    if [ -d "$DOCKER_DIRECTORY/docker" ]; then
        DOCKER_DIRECTORY=$DOCKER_DIRECTORY/docker
    fi
    if [ ! -d $DOCKER_DIRECTORY ]; then
        echo Error: docker directory does not exists: $DOCKER_DIRECTORY
        return 1
    fi

    # Check config file
    local CONFIG_FILE=$DOCKER_DIRECTORY/config
    if [ ! -f $CONFIG_FILE ]; then
        echo Error: missing config file: $CONFIG_FILE
        return 1
    fi

    # Include config vars
    . $CONFIG_FILE

    # Check config vars
    if [ -z "$DOCKER_IMAGE_NAME" ]; then
        echo Error: missing var DOCKER_IMAGE_NAME in config file: $CONFIG_FILE
        return 1
    fi
    if [ -z "$DOCKER_IMAGE_TAG" ]; then
        echo Error: missing var DOCKER_IMAGE_TAG in config file: $CONFIG_FILE
        return 1
    fi
    if [ -z "$DOCKER_CONTAINER_NAME" ]; then
        echo Error: missing var DOCKER_CONTAINER_NAME in config file: $CONFIG_FILE
        return 1
    fi
    if [ -z "$DOCKER_CONTAINER_USER" ]; then
        echo Error: missing var DOCKER_CONTAINER_USER in config file: $CONFIG_FILE
        return 1
    fi
};

function dkbuild () {
    if ! __dkcheck "$1"; then
        return 1
    fi

    # Check Dockerfile
    local DOCKER_FILE=$DOCKER_DIRECTORY/Dockerfile
    if [ ! -f $DOCKER_FILE ]; then
        echo Error: missing Dockerfile: $DOCKER_FILE
        return 1
    fi

    # Build image
    local DOCKER_BUILD_CMD="docker build
                            -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG \
                            -f $DOCKER_FILE \
                            $DOCKER_DIRECTORY"
    echo $DOCKER_BUILD_CMD
    $DOCKER_BUILD_CMD

    return 0
};

function dkrun () {
    if ! __dkcheck "$1"; then
        return 1
    fi

    # Get ports to expose
    local DOCKER_PUBLISH_PORTS=""
    if [ ${#DOCKER_PORTS[@]} -gt 0 ]; then
        for DOCKER_PORT in ${DOCKER_PORTS[@]}; do
            DOCKER_PUBLISH_PORTS="$DOCKER_PUBLISH_PORTS -p $DOCKER_PORT"
        done
    fi

    # Get volumes to mount
    local DOCKER_MOUNT_VOLUMES=""
    if [ ${#DOCKER_VOLUMES[@]} -gt 0 ]; then
        for DOCKER_VOLUME in ${DOCKER_VOLUMES[@]}; do
            DOCKER_MOUNT_VOLUMES="$DOCKER_MOUNT_VOLUMES -v $DOCKER_VOLUME"
        done
    fi

    # Get containers to link
    local DOCKER_LINK_CONTAINERS=""
    if [ ${#DOCKER_LINKS[@]} -gt 0 ]; then
        for DOCKER_LINK in ${DOCKER_LINKS[@]}; do
            DOCKER_LINK_CONTAINERS="$DOCKER_LINK_CONTAINERS --link $DOCKER_LINK"
        done
    fi

    # Get environment variables
    local DOCKER_ENV_VARS=""
    if [ ${#DOCKER_ENVS[@]} -gt 0 ]; then
        for DOCKER_ENV in ${DOCKER_ENVS[@]}; do
            DOCKER_ENV_VARS="$DOCKER_ENV_VARS -e $DOCKER_ENV"
        done
    fi

    # Get user and group ids
    local USER_ID=$(id -u)
    local GROUP_ID=$(id -g)

    # Clean existing container
    local CONTAINER_ID=$(docker ps -a -f "name=$DOCKER_CONTAINER_NAME" -q)
    if [ -n "$CONTAINER_ID" ]; then
        docker rm -f $$CONTAINER_ID
    fi

    # Run container
    local DOCKER_RUN_CMD="docker run -it --rm \
                        --name $DOCKER_CONTAINER_NAME \
                        -h $DOCKER_CONTAINER_NAME \
                        -e USER_UID=$USER_ID \
                        -e USER_GID=$GROUP_ID \
                        -e USER_NAME=$DOCKER_CONTAINER_USER \
                        $DOCKER_PUBLISH_PORTS
                        $DOCKER_MOUNT_VOLUMES \
                        $DOCKER_LINK_CONTAINERS \
                        $DOCKER_ENV_VARS \
                        $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG"

    echo $DOCKER_RUN_CMD
    $DOCKER_RUN_CMD

    return 0
};

function dkstop () {
    if ! __dkcheck "$1"; then
        return 1
    fi

    # Stop container
    local DOCKER_STOP_CMD="docker stop $DOCKER_CONTAINER_NAME"
    echo $DOCKER_STOP_CMD
    $DOCKER_STOP_CMD

    return 0
};

function dkexec () {
    if ! __dkcheck "$1"; then
        return 1
    fi

    # Exec container
    local DOCKER_EXEC_CMD="docker exec -it -u $DOCKER_CONTAINER_USER $DOCKER_CONTAINER_NAME /bin/bash"
    echo $DOCKER_EXEC_CMD
    $DOCKER_EXEC_CMD

    return 0
};

function dkexec-root () {
    if ! __dkcheck "$1"; then
        return 1
    fi

    # Exec container
    local DOCKER_EXEC_CMD="docker exec -it $DOCKER_CONTAINER_NAME /bin/bash"
    echo $DOCKER_EXEC_CMD
    $DOCKER_EXEC_CMD

    return 0
};
