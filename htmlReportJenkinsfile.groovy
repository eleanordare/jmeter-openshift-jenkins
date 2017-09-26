/*

Inside JMeter container, run with reports dashboard turned on:
apache-jmeter-3.1/bin/jmeter -n -t tests/Async/fileName.jmx -l results/$1Results.jtl -e -o fileName-reports

This will create a folder of HTML reports at fileName-reports,
which you can pull into Jenkins with "oc rsync" and then use the
HTML Publisher Plugin to parse them

*/


podResults = sh (
  script:"""
      oc get pods -l job-name=jmeter-master-${fileNameLowerCase} \
        -n ${project} --output=name
    """,
  returnStdout: true
)

print podResults

// get job logs and exit upon job completion
// if job pod hasn't spun up yet, waits 5s and tries again
// if job pod hasn't spun up after 10 tries, fails
numTry = 0
podList = podResults.split('\n')
for (int x = 0; x < podList.size(); x++){
 String pod = podList[x]
 if(pod.contains("jmeter-master-${fileNameLowerCase}-${index}") && !pod.contains("build")){
   while(numTry < 30){
     try {
       sh """
         sleep 5s
         oc logs ${pod} -n ${project}
       """
       numTry = 31
     } catch(e) {
         print e
         numTry++
         print "Checking if job container is up and running..."
     }
   }
   if(numTry == 30) {
     error("Job did not spin up in ${project}.")
   }
   jobPod = pod
 }
}

jobPod = jobPod.replaceAll("pod/","")
jobPod = jobPod.replaceAll("pods/","")

sh """
  oc rsync ${jobPod}:/jmeter/${fileName}-reports . -n ${project}
"""

// publish html
publishHTML (target: [
    allowMissing: false,
    alwaysLinkToLastBuild: false,
    keepAll: true,
    reportDir: "${workspace}/${fileName}-reports",
    reportFiles: "index.html",
    reportName: "${fileName} ${index} Report"
  ])
