FROM amazoncorretto:11-alpine
ARG AWS_CODEGURU_PROFILER_GROUP_NAME
ENV CG_PF_GNAME=$AWS_CODEGURU_PROFILER_GROUP_NAME

#https://docs.aws.amazon.com/codeguru/latest/profiler-ug/enabling-the-agent-with-command-line.html
ENV CODEGURU_PROFILER_AGENT_DOWNLOAD_URL 'https://d1osg35nybn3tt.cloudfront.net/com/amazonaws/codeguru-profiler-java-agent-standalone/1.2.1/codeguru-profiler-java-agent-standalone-1.2.1.jar'
RUN mkdir -p /opt/target
RUN apk update && apk add wget && wget $CODEGURU_PROFILER_AGENT_DOWNLOAD_URL -O /opt/target/codeguru-profiler-java-agent-standalone.jar
EXPOSE 8080 5005
COPY target/aws-proserve-java-greeting.war /opt/target/
WORKDIR /opt/target
ENV _JAVA_OPTIONS '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005'
CMD ["sh", "-c", "java -javaagent:codeguru-profiler-java-agent-standalone.jar=profilingGroupName:${CG_PF_GNAME},heapSummaryEnabled:true -jar aws-proserve-java-greeting.war"]
