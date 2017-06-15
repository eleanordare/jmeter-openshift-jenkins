print "----------------------------------------------------"
print "                 JMeter Testing"
print "----------------------------------------------------"

node('jenkins-agent'){

  workspace = pwd()   // Set the main workspace in your Jenkins agent

  authToken = ""  // Get your user auth token for OpenShift
  apiURL = ""     // URL for your OpenShift cluster API

  gitUser = ""    // Set your Git username
  gitPass = ""    // Set your Git password
  gitURL = ""     // Set the URL of your test suite repo
  gitName = ""    // Set the name of your test suite repo
  gitBranch = ""  // Set the branch of your test suite repo

  jenkinsUser = ""    // Set username for Jenkins
  jenkinsPass = ""    // Set API token for Jenkins

  // Set location of OpenShift objects in workspace
  buildConfigPath = "${workspace}/${gitName}/ocp/build-config.yaml"
  imageStreamPath = "${workspace}/${gitName}/ocp/image-stream.yaml"
  jobTemplatePath = "${workspace}/${gitName}/ocp/job-template.yaml"

  project = ""    // Set the OpenShift project you're working in
  testSuiteName = "jmeter-test-suite"   // Name of the job/build/imagestream

  // Login to the OpenShift cluster
  sh """
      set +x
      oc login --insecure-skip-tls-verify=true --token=${authToken} ${apiURL}
  """

  // Checkout the test suite repo into your Jenkins agent workspace
  int slashIdx = gitURL.indexOf("://")
  String urlWithCreds = gitURL.substring(0, slashIdx + 3) +
          "\"${gitUser}:${gitPass}\"@" + gitURL.substring(slashIdx + 3);

  sh """
    rm -rf ${workspace}/${gitName}
    git clone -b ${gitBranch} ${urlWithCreds} ${gitName}
    echo `pwd && ls -l`
  """

  // Create your ImageStream and BuildConfig in OpenShift
  // Then start the build for the test suite image
  sh """
    oc apply -f ${imageStreamPath} -n ${project}
    oc apply -f ${buildConfigPath} -n ${project}
    oc start-build ${testSuiteName} -n ${project} --follow
  """

  // Get latest JMeter image from project to assign to job template
  String imageURL = sh (
    script:"""
      oc get is/rhel-${testSuiteName} -n ${project} --output=jsonpath={.status.dockerImageRepository}
      """,
    returnStdout: true
  )

  // Get all JMX files from JMeter directory
  // Pipeline Utility Steps Plugin --> findFiles
  String files = findFiles(glob: 'jmeter/*.jmx')

  // Split file names into testFileNames array
  testFileNames = files.split('\n')

  // For every test file, run job and get results back
  for (int i=0; i<testFileNames.size(); i++) {

    // Get file name without .jmx
    file = testFileNames[i]
    fileName = file.replaceAll('.jmx','')

    print "Running JMeter tests: ${fileName}"

    // Set the return URL for the Jenkins input step
    inputURL = env.BUILD_URL + "input/Jmeter-${fileName}/submit"

    // Delete existing test suite job for previous JMX file
    // Create new test suite job with current file
    // Pass in input URL, Jenkins username/password, and image
    sh """
      oc delete job/${testSuiteName} -n ${project} --ignore-not-found=true

      oc process -f ${jobTemplatePath} -p \
      JENKINS_PIPELINE_RETURN_URL=${inputURL} \
      FILE_NAME=${fileName} \
      USER_NAME=${jenkinsUser} \
      PASSWORD=${jenkinsPass} \
      IMAGE=${imageURL}:latest \
      -n ${project} | oc create -f - -n ${project}
    """

    // Block and wait for job to return with results file
    // The input ID is what creates the unique return URL for curling back
    print "Waiting for results from JMeter test job..."
    def inputFile = input id: "Jmeter-${fileName}",
      message: 'Waiting for JMeter results...',
      parameters: [
        file(description: 'Performance Test Results',
        name: "${fileName}")  // This must match the name param in runjob.sh
      ]

    // Running Performance Plugin with JMeter to show results
    // The results JTL file is saved on the master Jenkins node,
    // inputFile.toString() gives you the absolute path of the file to parse
    //
    // These threshold values can be whatever you like
    performanceReport compareBuildPrevious: false,
      configType: 'ART',
      errorFailedThreshold: 0,
      errorUnstableResponseTimeThreshold: '',
      errorUnstableThreshold: 0,
      failBuildIfNoResultFile: false,
      ignoreFailedBuild: false,
      ignoreUnstableBuild: true,
      modeOfThreshold: false,
      modePerformancePerTestCase: true,
      modeThroughput: true,
      nthBuildNumber: 0,
      parsers: [[$class: 'JMeterParser', glob: inputFile.toString()]],
      relativeFailedThresholdNegative: 0,
      relativeFailedThresholdPositive: 0,
      relativeUnstableThresholdNegative: 0,
      relativeUnstableThresholdPositive: 0
  } // for loop
} // node
