## Hadoop NameNode

TODO - docs :-)

#### How to start

1) Start primary name node ( format to prepare volume )

    docker run -tidP --publish 0.0.0.0:50070:50070 --name nn1 andlaz/hadoop-hdfs-namenode \
    namenode --format

http://localhost:50070 - name node web console

2) Start secondary name node

    docker run -tidP --name nn2 --link nn1:namenode \
    andlaz/hadoop-hdfs-namenode namenodesecondary

3) Verify HDFS access

    docker run -ti --rm andlaz/hadoop-base hdfs dfs -ls hdfs://nn1/