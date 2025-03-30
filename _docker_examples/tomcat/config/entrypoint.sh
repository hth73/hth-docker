#!/bin/bash
cp -r /usr/local/tomcat/webapps.dist/manager /usr/local/tomcat/webapps/
cp -r /usr/local/tomcat/webapps.dist/host-manager /usr/local/tomcat/webapps/
cp /usr/local/tomcat/manager-context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml
cp /usr/local/tomcat/host-manager-context.xml /usr/local/tomcat/webapps/host-manager/META-INF/context.xml
exec "$@"

