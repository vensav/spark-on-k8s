
#!/bin/sh

docker build -t vensav/gpu-spark-notebook:v1.4_cuda-11.7_ubuntu-22.04_slim_spark-3.3 \
 -f ./dev/base_notebook_image/gpu-spark-notebook.Dockerfile .

docker push vensav/gpu-spark-notebook:v1.4_cuda-11.7_ubuntu-22.04_slim_spark-3.3

