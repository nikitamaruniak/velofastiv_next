#!/bin/bash

hostname=staging.velofastiv.org.ua
image_name=velofastiv
container_name=velofastiv-staging

exit_code=0

function usage {
    echo 'Usage: staging.sh COMMAND'
    echo ''
    echo 'Commands:'
    echo '  run'
    echo '  stop'
    exit_code=1
}

function run {
    echo Building the Docker image...
    docker build -t $image_name .
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi

    echo Running the Docker container...
    docker run -d -it -p 80:80 --rm -h $hostname --name $container_name -i $image_name
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi

    echo Modifying the hosts file...
    echo 127.0.0.1 $hostname | sudo tee -a /etc/hosts
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi

    echo "Running smoke tests..."
    ./smoke_tests.sh $hostname
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi

    echo Done
}

function stop {
    echo Stopping the Docker container...
    docker stop $container_name
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi

    echo Removing the Docker image...
    docker rmi $image_name
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi

    echo Modifying the hosts file...
    sudo sed -i '' "/$hostname/d" /etc/hosts
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi

    echo Done
}

function command {
    case $1 in
        "run") run;;
        "stop") stop;;
        *)
            echo Unknown command name: \'$1\'.
            usage;;
    esac
}

PWD_backup=$PWD
cd `dirname $0`

if [ -z $1 ]
then
   usage
else
   command $1
fi

cd $PWD_backup

exit $exit_code
