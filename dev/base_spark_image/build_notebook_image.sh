#!/bin/sh

BASE_OS="buster"
SPARK_VERSION="3.3.0"
SCALA_VERSION="scala_2.12"
DOCKERFILE="Dockerfile"
DOCKERIMAGETAG="17-slim"


docker build --build-arg IMAGE_TAG=${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS} \
 -t vensav/spark-notebook  -f spark-notebook.Dockerfile .

docker tag vensav/spark-notebook:latest vensav/spark-notebook:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}
docker push vensav/spark-notebook:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}

