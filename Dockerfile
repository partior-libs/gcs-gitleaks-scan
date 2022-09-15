FROM zricethezav/gitleaks:v8.12.0

LABEL "com.github.actions.name"="gitleaks-action"
LABEL "com.github.actions.description"="runs gitleaks on push and pull request events"
LABEL "com.github.actions.icon"="shield"
LABEL "com.github.actions.color"="purple"
LABEL "repository"="https://github.com/zricethezav/gitleaks-action"

USER root
RUN apk update
RUN apk add git

USER gitleaks
RUN git config --global --add safe.directory '*'

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
