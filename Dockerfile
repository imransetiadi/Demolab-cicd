# Create Custom Docker Image
FROM tomcat:9.0-jdk8

# Maintainer
MAINTAINER "Ran"

# copy war file on to container
COPY ./iwayq.war /usr/local/tomcat/webapps

