#
# Build stage
#
FROM maven:3.6.0-jdk-11-slim AS build
WORKDIR /application
COPY ./pom.xml ./pom.xml
# fetch all dependencies
RUN mvn dependency:go-offline -B
COPY src src
COPY ./.layers.xml ./.layers.xml
RUN mvn -f ./pom.xml clean package
RUN cp ./target/*.jar application.jar
RUN java -Djarmode=layertools -jar application.jar extract


FROM openjdk:11-jre-slim
WORKDIR application
COPY --from=build /application/dependencies/ ./
COPY --from=build /application/snapshot-dependencies/ ./
COPY --from=build /application/spring-boot-loader/ ./
COPY --from=build /application/wf2311-dependencies/ ./
COPY --from=build /application/application/ ./
ADD bin/docker-startup.sh bin/startup.sh

ENV JVM_OPTS '-Xmx256m -Xms64m -Xss256k'
ENV JVM_AGENT ''
ENV SERVER_PORT 3040
ENV WAKATIME_APP_KEY ''
ENV WAKATIME_PROXY_URL 'false'
ENV WAKATIME_FTQQ_KEY ''
ENV WAKATIME_DINGDING_KEY ''
ENV START_DAY '2016-01-01'
ENV MYSQL_URL 'jdbc:mysql://127.0.0.1:3306/wakatime?characterEncoding=utf8&useUnicode=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=PRC'
ENV MYSQL_USERNAME 'wakatime'
ENV MYSQL_PASSWORD '123456'
EXPOSE ${SERVER_PORT}

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' >/etc/timezone \
    && mkdir logs \
    && cd logs \
    && touch start.out \
    && ln -sf /dev/stdout start.out \
    && ln -sf /dev/stderr start.out

RUN chmod +x bin/startup.sh
ENTRYPOINT [ "sh", "-c", "sh bin/startup.sh"]
