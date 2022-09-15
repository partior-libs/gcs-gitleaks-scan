FROM zricethezav/gitleaks:v8.2.7

LABEL "com.github.actions.name"="gitleaks-action"
LABEL "com.github.actions.description"="runs gitleaks on push and pull request events"
LABEL "com.github.actions.icon"="shield"
LABEL "com.github.actions.color"="purple"
LABEL "repository"="https://github.com/zricethezav/gitleaks-action"

# USER root
# RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.14/main" >> /etc/apk/repositories
# RUN apk update && apk add git=2.32.3-r0

# USER gitleaks
RUN git config --global --add safe.directory '*'

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
