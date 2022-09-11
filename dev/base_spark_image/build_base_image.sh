#!/bin/sh

BASE_OS="buster"
SPARK_VERSION="3.3.0"
SCALA_VERSION="scala_2.12"
#SCALA_VERSION="scala_2.13"
DOCKERFILE="Dockerfile"
DOCKERIMAGETAG="17-slim"
SPARK_BASE=/usr/local/spark-3.3
#SPARK_BASE=/usr/local/spark-3.3-scala-2.13

# Building Docker image for spark on kubernetes
$SPARK_BASE/bin/docker-image-tool.sh \
              -r spark \
              -t ${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS} \
              -b java_image_tag=${DOCKERIMAGETAG} \
              -p $SPARK_BASE/kubernetes/dockerfiles/spark/${DOCKERFILE} \
               build

docker tag spark/spark-py:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS} vensav/spark-py:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}

docker tag spark/spark:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS} vensav/spark:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}

docker push vensav/spark-py:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}
docker push vensav/spark:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}

