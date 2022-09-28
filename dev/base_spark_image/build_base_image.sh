#!/bin/sh

BASE_OS="bullseye"
SPARK_VERSION="3.3.0"
#SCALA_VERSION="scala_2.12"
SCALA_VERSION="scala_2.13"
DOCKERFILE="Dockerfile"
DOCKERIMAGETAG="17-slim"
#SPARK_BASE=/usr/local/spark-3.3
SPARK_BASE=/usr/local/spark-3.3-scala-2.13

current_dir=$PWD

export SPARK_HOME=$SPARK_BASE

# Building Docker image for spark on kubernetes
cd $SPARK_BASE
./bin/docker-image-tool.sh \
              -u root \
              -r vensav \
              -t ${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS} \
              -b java_image_tag=${DOCKERIMAGETAG} \
              -p kubernetes/dockerfiles/spark/bindings/python/${DOCKERFILE} \
               build

#docker tag spark/spark:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS} vensav/spark:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}
#docker tag spark/spark-py:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS} vensav/spark-py:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}

docker push vensav/spark:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}
docker push vensav/spark-py:${SPARK_VERSION}-${SCALA_VERSION}-jre_${DOCKERIMAGETAG}-${BASE_OS}

cd $current_dir

