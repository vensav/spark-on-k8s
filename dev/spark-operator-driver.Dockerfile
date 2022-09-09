ARG IMAGE_TAG

FROM vensav/spark-py:${IMAGE_TAG}

USER root 

# Install Pip
RUN apt-get update && apt-get install -y python3-pip 

WORKDIR /app

COPY dev/requirements.txt .

RUN pip3 install -r requirements.txt

COPY spark_on_k8s /app/spark_on_k8s
