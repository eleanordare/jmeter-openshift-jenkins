#!/bin/bash

# set TESTFILES variable to array of test files in testsToRun.txt
IFS=$'\r\n' GLOBIGNORE='*' command eval 'TESTFILES=($(cat tests/Sync/testsToRun.txt))'
NUMFILES=${#TESTFILES[@]}

# need to pass in these args in order
# jenkins return URL
# username/password for curl
# cluster name
URL=$1
USER=$2
PASS=$3
CLUSTER=$4
DURATION=$5

# runs tests with specified JMX file
# curls results with user/pass back to Jenkins url
runTest()
{
  URL=$1
  USER=$2
  PASS=$3
  CLUSTER=$4
  FILE=$5
  NUM=$6
  DURATION=$7

  echo "apache-jmeter-3.1/bin/jmeter -n -t tests/Sync/$FILE.jmx -l results/$FILE-Results.jtl $DURATION"
  apache-jmeter-3.1/bin/jmeter -n -t tests/Sync/$FILE.jmx -l results/$FILE-Results.jtl $DURATION
  cat results/$FILE-Results.jtl

  curl -X POST --user $USER:$PASS \
    --form file0=@results/$FILE-Results.jtl \
    --form json='{"parameter": [{"name":'\"$FILE-$CLUSTER\"', "file":"file0"}]}' \
    --form proceed=Proceed \
    $URL-$NUM/submit

  sleep 10s

}

# loop through all files in list above
for (( i=0; i<${NUMFILES}; i++ )); do
  FILE=${TESTFILES[$i]}
  NUM=$i
  IFS=',' read -ra FULL <<< "$FILE"
  NUMPARAMS=${#FULL[@]}
  NAME=${FULL[0]}
  echo "Name: $NAME"
  if (( $NUMPARAMS == 2 )) ; then
    DURATION="${FULL[1]}"
    echo "Duration: $DURATION"
  else
    DURATION=""
  fi
  # Get the IPs of the JMeter Slave Pods
  # IPS=$(dig +noall +answer +short jmeter-slave-$NUM.${APP_POD_NAMESPACE}.svc.cluster.local | awk -vORS=, '{ print $1 }' | sed 's/,$/\n/')
  runTest $URL $USER $PASS $CLUSTER $NAME $NUM $DURATION
done
