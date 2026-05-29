FROM ubuntu:24.04


ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$JAVA_HOME/bin:$PATH

RUN apt-get update -y && \
    apt-get install -y openjdk-21-jdk wget openssl && \
    apt-get clean

RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-11/v11.0.2/bin/apache-tomcat-11.0.2.tar.gz \
    -O /tmp/tomcat.tar.gz && \
    tar -xzf /tmp/tomcat.tar.gz -C /opt && \
    mv /opt/apache-tomcat-11.0.2 /opt/tomcat && \
    rm /tmp/tomcat.tar.gz

RUN mkdir -p /opt/tomcat/webapps2

COPY config/server.xml /opt/tomcat/conf/server.xml
COPY config/tomcat-users.xml /opt/tomcat/conf/tomcat-users.xml
COPY config/context.xml /opt/tomcat/webapps/manager/META-INF/context.xml

RUN openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout /tmp/tomcat.key \
    -out /tmp/tomcat.crt \
    -days 365 \
    -subj '/C=ES/ST=Madrid/O=TomcatLocal/CN=localhost' && \
    openssl pkcs12 -export \
    -in /tmp/tomcat.crt \
    -inkey /tmp/tomcat.key \
    -out /opt/tomcat/conf/keystore.p12 \
    -passout pass:tomcat2025 && \
    rm /tmp/tomcat.key /tmp/tomcat.crt

COPY sitio1/target/sitio1.war /opt/tomcat/webapps/sitio1.war
COPY sitio2/target/sitio2.war /opt/tomcat/webapps2/sitio2.war

EXPOSE 8080 8081 8443 8009

CMD ["/opt/tomcat/bin/catalina.sh", "run"]

