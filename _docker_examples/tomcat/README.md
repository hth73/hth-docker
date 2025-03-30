# Apache-Tomcat

[Back to home](https://github.com/hth73/hth-docker)

---

## Description
Deploy Apache-Tomcat via Dockerfile.

## Preparation

```bash
vi ~/docker/tomcat/Dockerfile
```

```dockerfile
# --- Dockerfile --- #

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

# --- Dockerfile --- #
```

```bash
vi ~/docker/tomcat/context.xml
```

```xml
<Context privileged="true" antiResourceLocking="false"
         docBase="${CATALINA_HOME}/webapps/manager">
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|<REMOTE IP-ADDRESS - DOCKER HOST>" />
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
```

```bash
vi ~/docker/tomcat/tomcat-users.xml
```

```xml
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
  <role rolename="manager-gui"/>
  <role rolename="manager-status"/>
  <role rolename="manager-script"/>
  <role rolename="admin-gui"/>
  <role rolename="admin-script"/>
  <user name="<username>" password="<SecurePaSSw0rd>" roles="manager-gui,manager-status,manager-script,admin-gui,admin-script"/>
</tomcat-users>
```

## Execution

```bash
docker build -t image/apache-tomcat .
docker run -it -d -p 8080:8080 image/apache-tomcat
```

## Result

```html
http://localhost:8080
http://localhost:8080/sample
```