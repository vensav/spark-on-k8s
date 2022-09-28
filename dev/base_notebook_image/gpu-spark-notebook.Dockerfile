FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu22.04

USER root

# Let us install tzdata painlessly
ENV DEBIAN_FRONTEND=noninteractive
# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    # - bzip2 is necessary to extract the micromamba executable.
    bzip2 \
    ca-certificates \
    fonts-liberation \
    locales \
    # - pandoc is used to convert notebooks to html files
    #   it's not present in arm64 ubuntu image, so we install it here
    pandoc \
    # - run-one - a wrapper script that runs no more
    #   than one unique  instance  of  some  command with a unique set of arguments,
    #   we use `run-one-constantly` to support `RESTARTABLE` option
    run-one \
    sudo \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# JRE-17 install and other common software
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    software-properties-common \
    openjdk-17-jre \
    python3-pip \
    wget sudo nano-tiny vim-tiny \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/cache/apt/*

ENV LD_LIBRARY_PATH /usr/local/cuda-11.7/targets/x86_64-linux/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH 

#------------------------------------------- SPARK SETUP  ---------------------------------------------------

RUN cd /opt && \
    wget https://archive.apache.org/dist/spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz  && \
    tar -xzf spark-3.3.0-bin-hadoop3.tgz && rm -f spark-3.3.0-bin-hadoop3.tgz && \
    mv  spark-3.3.0-bin-hadoop3 spark

RUN cd /opt/spark/jars && \
    wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar && \
    wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.298/aws-java-sdk-bundle-1.12.298.jar

# Set Spark runtime options
ENV SPARK_HOME /opt/spark

# Add Spark Rapids
# https://rapids.ai/start.html#get-rapids
RUN mkdir -p /opt/sparkRapidsPlugin
RUN cd /opt/sparkRapidsPlugin && \
 wget https://repo1.maven.org/maven2/com/nvidia/rapids-4-spark_2.12/22.08.0/rapids-4-spark_2.12-22.08.0.jar && \
 wget https://github.com/apache/spark/blob/master/examples/src/main/scripts/getGpusResources.sh

# Set Spark runtime options
# https://rapids.ai/start.html#get-rapids
ENV SPARK_RAPIDS_DIR=/opt/sparkRapidsPlugin
ENV SPARK_RAPIDS_PLUGIN_JAR=${SPARK_RAPIDS_DIR}/rapids-4-spark_2.12-22.08.0.jar

# Add all python packages  needed for jupyter notebook
RUN pip install \
    jupyterhub \
    jupyterlab \
    wheel \
    ipywidgets \
    ipykernel \
    nbformat \
    notebook==6.4.2 \
    ipynb==0.5.1 \
    sparkmonitor==2.1.1 \
    pyspark==3.3.0 \
    jupyter_contrib_nbextensions \
    jupyter_nbextensions_configurator \
    tensorflow==2.9.2 \
    tensorflow-datasets

# install extension to monitor spark as root
RUN \
jupyter nbextension install sparkmonitor --py --system --symlink && \
jupyter nbextension enable  sparkmonitor --py --system && \
ln -s /usr/local/lib/python3.10/dist-packages/sparkmonitor/listener_2.12.jar /opt/spark/jars/listener_2.12.jar

# Start Jupyter Lab Service as root
RUN mkdir -p /home/joyvan/
CMD jupyter lab --port=8888 --ip=0.0.0.0 --no-browser --allow-root \
    --NotebookApp.token='' --notebook-dir=/home/joyvan/  \
    --LabApp.token='' --LabApp.disable_check_xsrf=True 

# Add regular user with sudo privilliges
RUN useradd -ms /bin/bash joyvan && usermod -aG sudo joyvan
RUN echo "joyvan     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chown -R joyvan:users /home/joyvan
EXPOSE 8888 4040 7777 2222

# Switch to regular user
USER joyvan
WORKDIR /home/joyvan

# Create profile for regular user and enable sparkmonitor extension
# https://pypi.org/project/jupyterlab-sparkmonitor/
RUN ipython profile create  && \
echo "c.InteractiveShellApp.extensions.append('sparkmonitor.kernelextension')" >> $(ipython profile locate default)/ipython_config.py && \
echo "c.InteractiveShellApp.extensions.append('sparkmonitor.kernelextension')" >>  $(ipython profile locate default)/ipython_kernel_config.py
