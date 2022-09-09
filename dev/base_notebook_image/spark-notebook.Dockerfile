ARG IMAGE_TAG

FROM vensav/spark-py:${IMAGE_TAG}

USER root

RUN apt-get update && apt install -y \
    wget \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/cache/apt/*

# Install node.js 
# Using Debian, as root
RUN apt-get update && apt-get install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
RUN apt-get install -y nodejs


# Add Spark Jars
RUN cd /opt/spark/jars \
 && wget "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar"
RUN cd /opt/spark/jars \
 && wget "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.298/aws-java-sdk-bundle-1.12.298.jar"


# Install Pip
RUN apt-get update && apt-get install -y python3-pip 


# Add all python packages  needed
RUN pip install \
    notebook==6.4.2 \
    ipynb==0.5.1 \
    sparkmonitor==2.1.1 \
    pyspark==3.3.0 \
    jupyter_contrib_nbextensions \
    jupyter_nbextensions_configurator

# install extension to monitor spark as root
RUN \
jupyter nbextension install sparkmonitor --py --system --symlink && \
jupyter nbextension enable  sparkmonitor --py --system && \
ln -s /usr/local/lib/python3.9/dist-packages/sparkmonitor/listener_2.12.jar /opt/spark/jars/listener_2.12.jar

# Start Jupyter Lab Service as root
VOLUME /home/notebook/
CMD jupyter lab --port=8888 --ip=0.0.0.0 --no-browser --allow-root \
    --NotebookApp.token='' --notebook-dir=/home/notebook/  \
    --LabApp.token='' --LabApp.disable_check_xsrf=True 


# Add regular user with sudo privilliges
RUN useradd -ms /bin/bash kartik && usermod -aG sudo kartik

# Switch to regular user
USER kartik
WORKDIR /home/kartik

# Create profile for regular user and enable sparkmonitor extension
# https://pypi.org/project/jupyterlab-sparkmonitor/
RUN ipython profile create  && \
echo "c.InteractiveShellApp.extensions.append('sparkmonitor.kernelextension')" >> $(ipython profile locate default)/ipython_config.py && \
echo "c.InteractiveShellApp.extensions.append('sparkmonitor.kernelextension')" >>  $(ipython profile locate default)/ipython_kernel_config.py
