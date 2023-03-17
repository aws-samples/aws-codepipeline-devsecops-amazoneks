FROM public.ecr.aws/docker/library/amazoncorretto:11-alpine
ARG AWS_CODEGURU_PROFILER_GROUP_NAME
ARG AWS_REGION
ENV CG_PF_GNAME=$AWS_CODEGURU_PROFILER_GROUP_NAME
ENV AWS_REGION=$AWS_REGION
#https://docs.aws.amazon.com/codeguru/latest/profiler-ug/enabling-the-agent-with-command-line.html
ENV CODEGURU_PROFILER_AGENT_DOWNLOAD_URL 'https://d1osg35nybn3tt.cloudfront.net/com/amazonaws/codeguru-profiler-java-agent-standalone/1.2.2/codeguru-profiler-java-agent-standalone-1.2.2.jar'
RUN mkdir -p /opt/target
RUN apk update && apk add wget && wget $CODEGURU_PROFILER_AGENT_DOWNLOAD_URL -O /opt/target/codeguru-profiler-java-agent-standalone.jar
RUN apk add libcrypto3=3.0.8-r0 libssl3=3.0.8-r0
EXPOSE 8080 5005
COPY target/aws-proserve-java-greeting.war /opt/target/
WORKDIR /opt/target
USER nobody
ENV _JAVA_OPTIONS '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005'
CMD ["sh", "-c", "java -javaagent:codeguru-profiler-java-agent-standalone.jar=profilingGroupName:${CG_PF_GNAME},region:${AWS_REGION},heapSummaryEnabled:true -jar aws-proserve-java-greeting.war --debug"]
HEALTHCHECK CMD curl --fail http://localhost:8080/hello || exit 1