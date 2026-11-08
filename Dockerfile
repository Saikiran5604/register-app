FROM tomcat:10.1-jdk21-temurin-jammy

RUN rm -rf /usr/local/tomcat/webapps/*

COPY webapp/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

CMD ["catalina.sh", "run"]
