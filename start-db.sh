set -e

docker rm -f geo |:

docker run -d --rm --name geo -p 5432:5432 -v $PWD/output:/output postgres:9.6
