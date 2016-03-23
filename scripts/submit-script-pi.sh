#!/bin/sh

spark-submit \
--class de.codecentric.SparkPi \
--master spark://192.168.33.100:7077  \
--conf spark.eventLog.enabled=true \
/vagrant/jars/spark-pi-example-1.0.jar 10

#--class org.apache.spark.examples.SparkPi \
#$SPARK_HOME/lib/spark-examples-1.6.0-hadoop2.6.0.jar 10
