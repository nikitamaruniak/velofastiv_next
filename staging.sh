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
    echo "Checking if the Docker image exists: '$container_name'..."
    image_id=`docker images $image_name:latest --format '{{.ID}}'`
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    if [[ -z $image_id ]]
    then
        echo Building the Docker image...
        docker build -t $image_name .
        if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    else
        echo "The Docker image exists: '$image_id'."
    fi

    echo "Checking if the Docker container exists: '$container_name'..."
    container_id=`docker ps -f name=$container_name --format '{{.ID}}'`
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    if [[ -z $container_id ]]
    then
    echo Running the Docker container...
        docker run -d -it -p 80:80 --rm -h $hostname --name $container_name -i $image_name
        if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    else
        echo "The Docker container exists: '$container_id'."
    fi

    echo "Checking if the hostname is mapped to an IP address: '$hostname'."
    grep -q $hostname /etc/hosts
    grep_exit_code=$?
    if [[ $grep_exit_code -eq 1 ]]
    then
        echo Modifying the hosts file...
        echo "127.0.0.1 $hostname" | sudo tee -a /etc/hosts
        if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    elif [[ $grep_exit_code -eq 0 ]]
    then
        echo "The hostname is mapped to an IP address."
    else
        exit_code=$grep_exit_code
        return
    fi

    echo "Running smoke tests..."
    ./smoke_tests.sh $hostname
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi

    echo Done
}

function stop {
    echo "Checking if the Docker container exists: '$container_name'..."
    container_id=`docker ps -f name=$container_name --format '{{.ID}}'`
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    if [[ -n $container_id ]]
    then
        echo Stopping the Docker container...
        docker stop $container_name
        if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    else
        echo "The Docker container does not exist."
    fi

    echo "Checking if the Docker image exists: '$image_name:latest'..."
    image_id=`docker images $image_name:latest --format '{{.ID}}'`
    if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    if [[ -n $image_id ]]
    then
        echo Removing the Docker image...
        docker rmi $image_name
        if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    else
        echo "The Docker image does not exist."
    fi

    echo "Checking if the hostname is mapped to an IP address: '$hostname'..."
    grep -q $hostname /etc/hosts
    grep_exit_code=$?
    if [[ $grep_exit_code -eq 0 ]]
    then
        echo Modifying the hosts file...
        sudo sed -i '' "/$hostname/d" /etc/hosts
        if [[ $? -ne 0 ]]; then exit_code=$?; return; fi
    elif [[ $grep_exit_code -eq 1 ]]
    then
        echo "The hostname is not mapped to an IP address."
    else
        exit_code=$grep_exit_code
        return
    fi

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
