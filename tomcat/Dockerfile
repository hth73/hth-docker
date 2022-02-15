FROM tomcat:9.0

MAINTAINER email@domain.com

## Base Environment variables
ENV CATALINA_BASE=/usr/local/tomcat
ENV CATALINA_HOME=/usr/local/tomcat
ENV CATALINA_TMPDIR=/usr/local/tomcat/temp
ENV JRE_HOME=/usr
ENV CLASSPATH=/usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar

## Amazon Corretto JDK 
WORKDIR /tmp
RUN wget --quiet --no-cookies https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.deb -O /tmp/amazon-corretto-8-x64-linux-jdk.deb 
RUN apt update && apt install -y java-common vim net-tools && apt install -y /tmp/amazon-corretto-8-x64-linux-jdk.deb
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto

## Access to webapp and host-manager
RUN mv /usr/local/tomcat/webapps /usr/local/tomcat/webapps2
RUN mv /usr/local/tomcat/webapps.dist /usr/local/tomcat/webapps
RUN rm -rf /usr/local/tomcat/webapps2

## Configuration files for the manager/host-manager access
ADD tomcat-users.xml /usr/local/tomcat/conf/
ADD context.xml /usr/local/tomcat/webapps/manager/META-INF/
ADD context.xml /usr/local/tomcat/webapps/host-manager/META-INF/

## Deploy Apache Tomcat sample Application
WORKDIR /usr/local/tomcat/webapps
RUN curl -O -L https://tomcat.apache.org/tomcat-9.0-doc/appdev/sample/sample.war

EXPOSE 8080

WORKDIR /usr/local/tomcat/bin
CMD ["catalina.sh", "run"]