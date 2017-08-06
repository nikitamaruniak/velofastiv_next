#!/bin/bash

image_name=velofastiv
container_name=velofastiv

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
    echo Building Docker image...
    docker build -t $image_name .
    if [[ $? != 0 ]]; then exit_code=$?; return; fi

    echo Running Docker container...
    docker run -d -it -p 80:80 --rm -h velofastiv.org.ua --name $container_name -i $image_name
    if [[ $? != 0 ]]; then exit_code=$?; return; fi

    echo Modifying hosts file...
    echo 127.0.0.1 velofastiv.org.ua | sudo tee -a /etc/hosts
    if [[ $? != 0 ]]; then exit_code=$?; return; fi
    echo 127.0.0.1 www.velofastiv.org.ua | sudo tee -a /etc/hosts
    if [[ $? != 0 ]]; then exit_code=$?; return; fi

    echo Done
}

function stop {
    echo Stopping Docker container...
    docker stop $container_name
    if [[ $? != 0 ]]; then exit_code=$?; return; fi

    echo Removing Docker image...
    docker rmi $image_name
    if [[ $? != 0 ]]; then exit_code=$?; return; fi

    echo Modifying hosts file...
    sudo sed -i '' '/velofastiv\.org\.ua/d' /etc/hosts
    if [[ $? != 0 ]]; then exit_code=$?; return; fi

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

if [ -z $1 ]
then
   usage
else
   command $1
fi

exit $exit_code
