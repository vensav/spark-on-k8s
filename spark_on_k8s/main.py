import os
from pyspark import SparkContext
from pyspark.sql import SparkSession


spark = SparkSession.builder \
        .appName("spark-test") \
        .getOrCreate()

def load_config(spark_context: SparkContext):

    S3_HOST_URL = os.environ['S3_HOST_URL']
    S3_ACCESS_KEY = os.environ['AWS_ACCESS_KEY_ID']
    S3_SECRET_KEY = os.environ['AWS_SECRET_ACCESS_KEY']
    spark_context._jsc.hadoopConfiguration().set('spark.executor.extraJavaOptions=-Dcom.amazonaws.services.s3.enableV4', 'true')
    spark_context._jsc.hadoopConfiguration().set('spark.driver.extraJavaOptions=-Dcom.amazonaws.services.s3.enableV4', 'true')
    spark_context._jsc.hadoopConfiguration().set('spark.hadoop.com.amazonaws.services.s3.enableV4', 'true')
    spark_context._jsc.hadoopConfiguration().set('fs.s3a.impl', 'org.apache.hadoop.fs.s3a.S3AFileSystem')
    spark_context._jsc.hadoopConfiguration().set('fs.s3a.multipart.size', '104857600')
    spark_context._jsc.hadoopConfiguration().set('fs.s3a.path.style.access', 'true')
    #spark_context._jsc.hadoopConfiguration().set('spark.hadoop.fs.s3a.aws.credentials.provider', 'org.apache.hadoop.fs.s3a.AnonymousAWSCredentialsProvider')
    spark_context._jsc.hadoopConfiguration().set('fs.s3a.endpoint', S3_HOST_URL)
    spark_context._jsc.hadoopConfiguration().set('fs.s3a.access.key', S3_ACCESS_KEY)
    spark_context._jsc.hadoopConfiguration().set('fs.s3a.secret.key', S3_SECRET_KEY)
    spark_context._jsc.hadoopConfiguration().set('fs.s3a.connection.ssl.enabled', 'false')

load_config(spark.sparkContext)

dataFrame = spark.read.json('s3a://test-bucket/*')

average = dataFrame.groupBy("id").agg({'amount': 'avg'})

average.show()


