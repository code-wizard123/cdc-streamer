from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("CDCStreamer").getOrCreate()

data = [(1, "Raunak"), (2, "John"), (3, "Alice")]
df = spark.createDataFrame(data, ["id", "name"])

df.show()

spark.stop()