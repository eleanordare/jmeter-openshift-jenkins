#!/bin/bash

apache-jmeter-3.1/bin/jmeter -n -t tests/Async/$2.jmx -l results/$2Results.jtl
cat results/$2Results.jtl

curl -X POST --user $3:$4 \
  --form file0=@results/$2Results.jtl \
  --form json='{"parameter": [{"name":'\"$2\"', "file":"file0"}]}' \
  --form proceed=Proceed \
  $1
