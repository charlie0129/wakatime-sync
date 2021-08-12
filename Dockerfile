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
WORKDIR /application
COPY --from=build /application/dependencies/ ./
COPY --from=build /application/snapshot-dependencies/ ./
COPY --from=build /application/spring-boot-loader/ ./
COPY --from=build /application/wf2311-dependencies/ ./
COPY --from=build /application/application/ ./

EXPOSE ${SERVER_PORT}

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' >/etc/timezone 


ENTRYPOINT [ "java" ]
