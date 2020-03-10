#!/bin/bash

# Script to manage the Aigents SNET service.

BASE_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

B_TAG=$(date +%b%d)
C_PORT=9999
H_PORT=9999

if [ ! -z $2 ] ; then
    B_TAG=$2
fi
if [ ! -z $3 ] ; then
    H_PORT=$3
fi
I_NAME="snet_aigents:$B_TAG"
C_NAME="aigents_server-$B_TAG"

build_docker() {
    docker build -t $I_NAME $BASE_DIR
}

run_service() {
    if [ -f /.dockerenv ] ; then
        printf "${BAD_COLOR}Ignoring! Running in a docker container${NORMAL_COLOR}\n"
    else
        docker inspect $C_NAME > /dev/null 2>&1
        if [ $? -eq 1 ] ; then
            printf "${GOOD_COLOR}Starting new container...${NORMAL_COLOR}\n"
            docker run -d --name $C_NAME \
                       -p $H_PORT:$C_PORT \
                       $I_NAME \
                       python3 aigents_news_service.py
        else
            if [ "$(docker inspect -f '{{.State.Running}}' $C_NAME)" = "true"] ; then
                printf "${OKAY_COLOR}Container already running. ${NORMAL_COLOR}\n"
            else
                printf "${OKAY_COLOR}Container exited. Starting... ${NORMAL_COLOR}\n"
                docker start $C_NAME
            fi
        fi
    fi
}

run_service_with_daemon() {
    H_PORT=7110
    if [ -f /.dockerenv ] ; then
        printf "${BAD_COLOR}Ignoring! Running in a docker container${NORMAL_COLOR}\n"
    else
        docker inspect $C_NAME > /dev/null 2>&1
        if [ $? -eq 1 ] ; then
            printf "${GOOD_COLOR}Starting new container...${NORMAL_COLOR}\n"
            docker run -d --name $C_NAME \
                       -p $H_PORT:$C_PORT \
                       -p 7113:7113 \
                        -v /home/yitbarek/.certs/:/opt/singnet/.certs/ \
                       $I_NAME \
                       python3  with_daemon/run_aigent.py   --daemon-config with_daemon/snetd_configs/snetd.ropsten.json
        else
            if [ "$(docker inspect -f '{{.State.Running}}' $C_NAME)" = "true"] ; then
                printf "${OKAY_COLOR}Container already running. ${NORMAL_COLOR}\n"
            else
                printf "${OKAY_COLOR}Container exited. Starting... ${NORMAL_COLOR}\n"
                docker start $C_NAME
            fi
        fi
    fi
}

stop_service() {
    if [ "$(docker inspect -f '{{.State.Running}}' $C_NAME)" = "true" ]; then
        docker stop $C_NAME
    else
        printf "${OKAY_COLOR}Container \"$C_NAME\" not running currently ${NORMAL_COLOR}\n"
    fi
}

build_proto() {
    docker inspect $I_NAME > /dev/null 2>&1
    if [ $? -eq 1 ] ; then
        printf "${BAD_COLOR}Error: Image \"$I_NAME\" doesn't exist! ${NORMAL_COLOR}\n"
    else
        export HOST_UID=$UID
        docker run --rm \
                   -v $BASE_DIR/service_spec:/singnet/aigents/service_spec \
                   -e "HOST_UID" \
                   $I_NAME \
                   sh -c 'protoc --proto_path=/singnet/aigents/service_spec \
                                 --php_out=/singnet/aigents/service_spec \
                                 --grpc_out=/singnet/aigents/service_spec \
                                 --plugin=protoc-gen-grpc=$(which grpc_php_plugin) \
                                 /singnet/aigents/service_spec/aigents.proto \
                                 && \
                          protoc --proto_path=/singnet/aigents/service_spec \
                                 --python_out=/singnet/aigents/service_spec \
                                 --grpc_out=/singnet/aigents/service_spec \
                                 --plugin=protoc-gen-grpc=$(which grpc_python_plugin) \
                                 /singnet/aigents/service_spec/aigents.proto \
                                 && \
                                 chown -R $HOST_UID:$HOST_UID /singnet/aigents/service_spec'
    fi
}

help () {
    echo "Usage: bash manage.sh OPTION [LABEL] [SERVICE_PORT]"
    echo "  Options:"
    echo "    build        build the docker image"
    echo "    run          run the snet service with out daemon (start container)"
    echo "    run-with-daemon        run the snet service with daemon"
    echo "    stop         stop the snet service (stop container)"
    echo "    build-proto  build the proto files"
    echo -e "\n  LABEL  :  image and container label (optional - default=date)"
    echo -e "\n  SERVICE_PORT  :  port to expose the service through (optional - default=9999)"
}

case $1 in
  build) build_docker ;;
  run) run_service ;;
  run-with-daemon) run_service_with_daemon ;;
  stop) stop_service ;;
  build-proto) build_proto ;;
  *) help ;;
esac
