#!/bin/bash
# Get the IPs of the JMeter Slave Pods
# IPS=$(dig +noall +answer +short $6.${APP_POD_NAMESPACE}.svc.cluster.local | awk -vORS=, '{ print $1 }' | sed 's/,$/\n/')

# Run JMeter test
# echo "apache-jmeter-3.1/bin/jmeter -n -t tests/Async/$2.jmx -l results/$2ResultsIP.jtl -R$IPS $7"
# apache-jmeter-3.1/bin/jmeter -n -t tests/Async/$2.jmx -l results/$2ResultsIP.jtl -R$IPS $7
# cat results/$2ResultsIP.jtl

echo "apache-jmeter-3.1/bin/jmeter -n -t tests/Async/$2.jmx -l results/$2Results.jtl $7"
apache-jmeter-3.1/bin/jmeter -n -t tests/Async/$2.jmx -l results/$2Results.jtl $7
cat results/$2Results.jtl

curl -X POST --user $3:$4 \
  --form file0=@results/$2Results.jtl \
  --form json='{"parameter": [{"name":'\"$2-$5\"', "file":"file0"}]}' \
  --form proceed=Proceed \
  $1
