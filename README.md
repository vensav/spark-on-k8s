# spark-on-k8s

In this guide, we will setup spark with minio on kubernetes

## Pre-requisites
1. An existing kubernetes cluster
2. MINIO Installed in kubernetes in the namespace called minio
3. Optional - Download JDK 17 if testing locally
4. Optional - Install poetry for testing python code locally
5. GPU enabled on Kubernetes (if using gpu powered notebook)
6. If following this guide, namespace called ml-data-engg should be defined

For this demo, I am going to upload a json file from [here](data/orders.json) to a bucket called test-bucket in minio


## Getting started - Spark Installation locally

- Download latest version of spark from [here](https://dlcdn.apache.org/spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz). Using spark 3.3.0 with scala-12 and hadoop-3.3 in this example.


-  Add additional jars needed for aws-sdk and hadoop-3 (this will ensure that these JARs get copied over to docker image that we would be building under the section build base image)
``` 
tar xvzf spark-3.3.0-bin-hadoop3.tgz
sudo mv spark-3.3.0-bin-hadoop3 /usr/local/spark-3.3
export SPARK_HOME=/usr/local/spark-3.3
export PATH=$PATH:$SPARK_HOME/bin

cd /usr/local/spark-3.3/jars
wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.298/aws-java-sdk-bundle-1.12.298.jar
```
 
- Make a few edits to the default dockerfiles and jars provided by spark. Edit the file under $SPARK_HOME/kubernetes/dockerfiles/spark/bindings/python/Dockerfile. Add entry to install pyspark
```
RUN mkdir ${SPARK_HOME}/python
RUN apt-get update && \
    apt install -y python3 python3-pip && \
    pip3 install --upgrade pip setuptools && \
    pip3 install pyspark==3.3.0 py4j==0.10.9.5 && \  <-- Add this line
    # Removed the .cache to save space
    rm -r /root/.cache && rm -rf /var/cache/apt/*
```


- Add minio secrets and reference it later
```
kubectl create secret generic minio-api-client-credentials  \
    --from-literal=MINIO_HOST_URL="<MINIO_SVC_HOST_NAME>.minio:9000" \
    --from-literal=MINIO_HTTP_ENDPOINT="http://<MINIO_SVC_HOST_NAME>.minio:9000" \
    --from-literal=MINIO_ACCESS_KEY="YourAccessKey" \
    --from-literal=MINIO_SECRET_KEY="YourSecretKey" \
    -n ml-data-engg 
```


## Local testing and base images

### Quick Test Locally (to check if spark JARs and minio are working fine)
```
poetry install
export SPARK_LOCAL_IP=<Local IP>
spark-submit spark_on_k8s/main.py --master=local[1]
```

### Build Base Image
```
chmod +x ./dev/base_spark_image/build_base_image.sh && ./dev/base_spark_image/build_base_image.sh
```


### Build Spark Notebook Image
```
chmod +x ./dev/base_notebook_image/build_spark_notebook.sh && ./dev/base_notebook_image/build_spark_notebook.sh
```

### Build GPU Spark Notebook
```
chmod +x ./dev/base_notebook_image/build_gpu_spark_notebook.sh && ./dev/base_notebook_image/build_gpu_spark_notebook.sh
```


### Another option - reuse gpu-jupyter image from iot-salzburg
- Refer: [iot-salzburg/gpu-jupyter](https://github.com/iot-salzburg/gpu-jupyter#build-your-own-image)
```
cd $HOME
git clone https://github.com/iot-salzburg/gpu-jupyter.git
git checkout v1.4_cuda-11.6_ubuntu-20.04
./generate-Dockerfile.sh --slim --python-only
cp -r .build <Path to current project>
```
- Add Spark related dependencies to it and run
```
docker build -t vensav/gpu-jupyter-spark:v1.4_cuda-11.7_ubuntu-22.04_slim .build/
docker push vensav/gpu-jupyter-spark:v1.4_cuda-11.7_ubuntu-22.04_slim
```


## Deploy Spark Notebook on Kubernetes
Using namepsace ml-data-engg. Change namespace as needed for your use case. Make sure the namespace exists.
Inspired by blog posted by [Itay Bittan](https://towardsdatascience.com/jupyter-notebook-spark-on-kubernetes-880af7e06351)
- Select `vensav/spark-notebook:3.3.0-scala_2.12-jre_17-slim-bullseye` for regular spark-notebook or
- `vensav/gpu-jupyter-spark:v1.4_cuda-11.7_ubuntu-22.04_slim` for gpu enabled notebook. In this case make sure you are deploying on a node with gpu
```
kubectl apply -f dev/service-account.yaml
kubectl apply -f dev/spark-notebook.yaml -n ml-data-engg
kubectl apply -f dev/gpu-spark-notebook.yaml -n ml-data-engg
```
See sample notebook under [here](notebook/spark-k8s-test.ipynb). If everything works fine, you should get a monitor like below

![jupyter-sparkmonitor](notebook/sparkmonitor.png)


### Test Spark Image
```
$SPARK_HOME/bin/spark-submit \
    --master k8s://https://<KUBE CLUSTER IP>:16443 \
    --deploy-mode cluster \
    --name spark-submit-examples-sparkpi \
    --conf spark.executor.instances=3 \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=vensav-ml-data-deployer \
    --conf spark.kubernetes.namespace=ml-data-engg \
    --class org.apache.spark.examples.SparkPi \
    --conf spark.kubernetes.container.image=vensav/spark:3.3.0-scala_2.12-jre_17-slim-bullseye \
     local:///opt/spark/examples/jars/spark-examples_2.12-3.3.0.jar 80
```

### Cleaning up if needed
`kubectl delete pods -l  spark-app-name=test-app -n ml-data-engg`
`kubectl delete pods -l  spark-app-name=pyspark-submit-test -n ml-data-engg`


## Using Spark-Operator on k8s

### Install using helm
```
# https://github.com/GoogleCloudPlatform/spark-on-k8s-operator
helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
helm install spark-operator spark-operator/spark-operator --namespace spark-operator --create-namespace 
```

### Build and test Pyspark code using spark operator
Note:- Uses the service account that is defined when `kubectl apply -f dev/service-account.yaml` is run
```
poetry export --without-hashes --format=requirements.txt > dev/requirements.txt
chmod +x ./dev/spark-operator-create-driver.sh && ./dev/spark-operator-create-driver.sh
kubectl apply -f dev/spark-operator-python-test.yaml -n ml-data-engg
```
Unlike spark notebook above where sparkmonitor is currently not supported on scala 2.13, operator seems to work fine on both scala-2.12 and scala-2.13 images



## Using spark-submit on k8s instead of using operator
```
$SPARK_HOME/bin/spark-submit \
    --master k8s://https://<KUBE CLUSTER IP>:16443 \
    --deploy-mode cluster \
    --name pyspark-submit-test \
    --conf spark.executor.instances=3 \
    --conf spark.driver.cores=1  \
    --conf spark.driver.memory=1g \
    --conf spark.executor.cores=2 \
    --conf spark.executor.memory=2g  \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=vensav-ml-data-deployer \
    --conf spark.kubernetes.namespace=ml-data-engg \
    --conf spark.kubernetes.container.image=vensav/spark-operator-driver:3.3.0-scala_2.12-jre_17-slim-bullseye \
    --conf spark.kubernetes.container.image.pullPolicy=Always \
    --conf spark.kubernetes.driver.secretKeyRef.S3_HOST_URL=minio-api-client-credentials:MINIO_HOST_URL \
    --conf spark.kubernetes.driver.secretKeyRef.AWS_ACCESS_KEY_ID=minio-api-client-credentials:MINIO_ACCESS_KEY \
    --conf spark.kubernetes.driver.secretKeyRef.AWS_SECRET_ACCESS_KEY=minio-api-client-credentials:MINIO_SECRET_KEY \
    --conf spark.kubernetes.executor.secretKeyRef.S3_HOST_URL=minio-api-client-credentials:MINIO_HOST_URL \
    --conf spark.kubernetes.executor.secretKeyRef.AWS_ACCESS_KEY_ID=minio-api-client-credentials:MINIO_ACCESS_KEY \
    --conf spark.kubernetes.executor.secretKeyRef.AWS_SECRET_ACCESS_KEY=minio-api-client-credentials:MINIO_SECRET_KEY \
     local:///app/spark_on_k8s/main.py
```
