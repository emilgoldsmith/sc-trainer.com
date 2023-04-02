
############################
# SHARED DEPENDENCIES STAGE
############################

FROM node:16 as dependency-builder

ENV ELM_VERSION=0.19.1

WORKDIR /dependencies

# Taken from https://github.com/elm/compiler/blob/master/installers/linux/README.md
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/$ELM_VERSION/binary-for-linux-64-bit.gz \
    && gunzip elm.gz \
    && chmod +x elm \
    # Smoke test
    && ./elm --version \
    && echo "Installed Elm Successfully"


############################
# PROD BUILDER STAGE
############################


FROM node:16 AS prod-builder


WORKDIR /workdir

COPY package.json package.json
COPY yarn.lock yarn.lock

RUN yarn --ignore-optional

COPY elm.json ./
COPY scripts/build-production-js.sh scripts/build-production-js.sh
COPY src src
COPY --from=dependency-builder /dependencies/elm /usr/local/bin

# Outputs main.min.js
RUN ./scripts/build-production-js.sh

RUN rm -rf node_modules \
    && yarn --production \
    && mv node_modules production_only_node_modules


############################
# PRODUCTION STAGE
############################


FROM node:16-alpine as production

WORKDIR /app

COPY public/index.template.html public/index.template.html
COPY public/sentry.js public/sentry.js
COPY scripts/run-production.sh scripts/run-production.sh
COPY scripts/build-html.js scripts/build-html.js
COPY config/feature-flags.json config/feature-flags.json
COPY --from=prod-builder /workdir/main.min.js public/main.js
COPY --from=prod-builder /workdir/production_only_node_modules node_modules

EXPOSE $PORT

ENTRYPOINT ["./scripts/run-production.sh"]

############################
# CI STAGE
############################

# We need buster for high enough glibc version for elm-format
FROM node:16-buster as ci

#### IMPORTANT: To have any changes actually take effect in CI, you have
#### to go change the version number in the yaml file too

WORKDIR /ci-home

COPY --from=dependency-builder /dependencies/elm /usr/local/bin

############################
# CI WITH BROWSERS STAGE
############################

FROM node:16 AS ci-browsers-base

#### IMPORTANT: To have any changes actually take effect in CI, you have
#### to go change the version number of all dockerfile stages that depend
#### on this one in the CI yaml file too

# All the Cypress dependencies
# Taken from https://github.com/cypress-io/cypress-docker-images/blob/master/base/12.18.3/Dockerfile
# and also https://github.com/cypress-io/cypress-docker-images/blob/master/browsers/node12.18.3-chrome89-ff86/Dockerfile

RUN apt-get update && \
  apt-get install --no-install-recommends -y \
  libgtk2.0-0 \
  libgtk-3-0 \
  libnotify-dev \
  libgconf-2-4 \
  libgbm-dev \
  libnss3 \
  libxss1 \
  libasound2 \
  libxtst6 \
  xauth \
  xvfb \
  # install Chinese fonts
  # this list was copied from https://github.com/jim3ma/docker-leanote
  fonts-arphic-bkai00mp \
  fonts-arphic-bsmi00lp \
  fonts-arphic-gbsn00lp \
  fonts-arphic-gkai00mp \
  fonts-arphic-ukai \
  fonts-arphic-uming \
  ttf-wqy-zenhei \
  ttf-wqy-microhei \
  xfonts-wqy \
  # clean up
  && rm -rf /var/lib/apt/lists/*

FROM ci-browsers-base as ci-chrome

#### IMPORTANT: To have any changes actually take effect in CI, you have
#### to go change the version number in the yaml file too

# All taken from https://github.com/cypress-io/cypress-docker-images/blob/master/browsers/node12.18.3-chrome89-ff86/Dockerfile

# Chrome dependencies
RUN apt-get update
RUN apt-get install -y fonts-liberation libappindicator3-1 xdg-utils

# install Chrome browser
ENV CHROME_VERSION 89.0.4389.72
RUN wget -O /usr/src/google-chrome-stable_current_amd64.deb "http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}-1_amd64.deb" && \
  dpkg -i /usr/src/google-chrome-stable_current_amd64.deb ; \
  apt-get install -f -y && \
  rm -f /usr/src/google-chrome-stable_current_amd64.deb
RUN google-chrome --version

# "fake" dbus address to prevent errors
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

############################
# LOCAL DEVELOPMENT STAGE
############################


# The `unsafe-html-cube-devcontainer` is built in the
# initializeCommand for the devcontainer from base.dockerfile
# which is located in the .devcontainer directory
FROM emilgoldsmith/unsafe-dev-container:node-16-latest AS local-development

USER $USERNAME

WORKDIR /home/$USERNAME

ENV HISTFILE /home/$USERNAME/bash_history/bash_history.txt

# Create the elm cache directory where we can mount a volume. If we don't create it like this
# it is auto created by docker on volume creation but with root as owner which makes it unusable.
RUN mkdir .elm \
    # Similar story here with the bash history we store in a volume
    && mkdir -p $(dirname $HISTFILE)

# Install all the dependencies
RUN yarn

# Add in the dependencies shared between stages
COPY --from=dependency-builder /dependencies/elm /usr/local/bin

USER root

USER $USERNAME
