#!/bin/sh

BASE_OS="buster"
SPARK_VERSION="3.3.0"
SCALA_VERSION="scala_2.12"
DOCKERIMAGETAG="17-slim"

docker build --build-arg IMAGE_TAG=${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS} \
 -t vensav/spark-operator-driver:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}  -f dev/spark-operator-driver.Dockerfile .

docker push vensav/spark-operator-driver:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}

