FROM rhel-jmeter

# Ports to be exposed from the container for JMeter Master
EXPOSE 60000

RUN yum --enablerepo=rhel-server-rhscl-7-rpms -y install bind-utils

COPY jmeter /jmeter/tests
COPY runjob.sh /jmeter/runjob.sh
RUN chmod 777 -R /jmeter
