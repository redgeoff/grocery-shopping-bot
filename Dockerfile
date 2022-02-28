FROM ppodgorsek/robot-framework

COPY . /opt/robotframework/tests

ENV ROBOT_OPTIONS "--variablefile /opt/robotframework/tests/env.robot.yml"