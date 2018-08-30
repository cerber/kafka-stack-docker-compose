#!/bin/bash
set -x

export file=$1

kafka_connect_es_test(){
    echo "Testing Kafka Connect Elasticsearch Sink"
    topic="test-elasticsearch-sink"
    topic_exists=`kafka-topics --list --topic $topic --zookeeper zoo1:2181`
    if [ x$topic_exists != x ]; then kafka-topics --delete --topic $topic --zookeeper zoo1:2181; fi
    if grep -q kafka3 $1; then replication_factor="3"; else replication_factor="1"; fi
    for i in {1..5}; do echo "trying to create test topic" && kafka-topics --create --topic $topic --replication-factor $replication_factor --partitions 12 --zookeeper zoo1:2181 && break || sleep 5; done
    for i in {1..5}; do echo "trying to create kafka-connect elasticsearch connector" && cat ./config/kafka-connect/elasticsearch-sink.json | curl -s -XPOST -H "Content-Type: application/json" --data @- "http://kafka-connect:8083/connectors" && break || sleep 10; done
    for x in {1..100}; do echo "{\"f1\": \"value$x\", \"f2\": $x}"; done | kafka-avro-console-producer --broker-list kafka1:9092 --topic $topic \
        --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"f1","type":"string"}, {"name":"f2","type":"int"}]}'
    rows=$(curl -s -XGET 'http://elasticsearch:9200/test-elasticsearch-sink/_count' | python -c "import sys, json; print json.load(sys.stdin)['count']")
    if [ "$rows" != "100" ]; then
        echo "Test failed"
    else
        echo "Kafka + Elasticsearch Test Success"
    fi
}

kafka_connect_ts_test(){
    echo "Testing Kafka Connect Timeseries Data"
    topic="test-elasticsearch-ts-sink"
    topic_exists=`kafka-topics --list --topic $topic --zookeeper zoo1:2181`
    if [ x$topic_exists != x ]; then kafka-topics --delete --topic $topic --zookeeper zoo1:2181; fi
    if grep -q kafka3 $1; then replication_factor="3"; else replication_factor="1"; fi
    for i in {1..5}; do echo "trying to create test topic" && kafka-topics --create --topic $topic --replication-factor $replication_factor --partitions 12 --zookeeper zoo1:2181 && break || sleep 5; done
    for i in {1..5}; do echo "trying to create kafka-connect elasticsearch connector" && cat ./config/kafka-connect/elasticsearch-ts-sink.json | curl -s -XPOST -H "Content-Type: application/json" --data @- "http://kafka-connect:8083/connectors" && break || sleep 10; done
    awk -F\, 'FNR>1 { split($2, t, ":"); print "{\"number_of_tweets\": "$1", \"time_of_day_GMT\": \""(t[1] * 60 * 60 + t[2] * 60)*1000"\"}" }' ./config/test/tweets_by_minute.csv | \
    kafka-avro-console-producer --broker-list kafka1:9092 --topic test-elasticsearch-ts-sink \
        --property value.schema='{"type": "record", "name": "tweets", "fields": [{"name":"number_of_tweets","type":"int"}, {"name":"time_of_day_GMT","type": {"type": "string", "logicalType": "timestamp-millis"}}]}'
}

kafka_connect_airbnb_test(){
    echo "Testing Kafka Connect Airbnb Dataset"
    dataset="./config/test/airbnb_session_data.txt"
    topic="test-elasticsearch-airbnb-sink"

    key_schema=$(cat ./config/test/airbnb_session_data_key.json)
    value_schema=$(cat ./config/test/airbnb_session_data_value.json)

    topic_exists=`kafka-topics --list --topic $topic --zookeeper zoo1:2181`
    if [ x$topic_exists != x ]; then kafka-topics --delete --topic $topic --zookeeper zoo1:2181; fi
    if grep -q kafka3 $1; then replication_factor="3"; else replication_factor="1"; fi
    for i in {1..5}; do echo "trying to create test topic" && kafka-topics --create --topic $topic --replication-factor $replication_factor --partitions 12 --zookeeper zoo1:2181 && break || sleep 5; done
    for i in {1..5}; do echo "trying to create kafka-connect elasticsearch connector" && cat ./config/kafka-connect/elasticsearch-airbnb-sink.json | curl -s -XPOST -H "Content-Type: application/json" --data @- "http://kafka-connect:8083/connectors" && break || sleep 10; done

    producer_cmd="kafka-avro-console-producer --broker-list kafka1:9092 --topic $topic --property parse.key=true --property key.schema='$key_schema' --property value.schema='$value_schema'"

    ./config/test/airbnb_session_data.py | eval $producer_cmd
}

kafka_connect_airbnb_test_produce(){
    dataset="./config/test/airbnb_session_data.txt"
    topic="test-elasticsearch-airbnb-sink"
    key_schema=$(cat ./config/test/airbnb_session_data_key.json)
    value_schema=$(cat ./config/test/airbnb_session_data_value.json)
    producer_cmd="kafka-avro-console-producer --broker-list kafka1:9092 --topic $topic --property parse.key=true --property key.schema='$key_schema' --property value.schema='$value_schema'"

    ./config/test/airbnb_session_data.py | eval $producer_cmd
}


# kafka_connect_es_test $1
# kafka_connect_ts_test $1
kafka_connect_airbnb_test $1
# kafka_connect_airbnb_test_produce $1
echo "Success!"
