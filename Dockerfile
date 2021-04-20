
############################
# SHARED DEPENDENCIES STAGE
############################

FROM node:12 as dependency-builder

ENV ELM_VERSION=0.19.1
ENV UGLIFY_JS_VERSION=3.12.4

WORKDIR /dependencies

# Taken from https://github.com/elm/compiler/blob/master/installers/linux/README.md
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/$ELM_VERSION/binary-for-linux-64-bit.gz \
    && gunzip elm.gz \
    && chmod +x elm \
    # Smoke test
    && ./elm --version \
    && echo "Installed Elm Successfully" \
    # Install uglifyJS
    && yarn add uglify-js@$UGLIFY_JS_VERSION \
    # Smoke test
    && yarn run uglifyjs --version \
    && echo "Installed Uglify JS Successfully"


############################
# PROD BUILDER STAGE
############################


FROM node:12 AS prod-builder

COPY --from=dependency-builder /dependencies/elm /usr/local/bin
COPY --from=dependency-builder /dependencies/node_modules /node_modules

RUN ln -s /node_modules/.bin/uglifyjs /usr/local/bin/uglifyjs

WORKDIR /workdir

COPY elm.json scripts/optimize.sh ./
COPY src src

# Outputs main.min.js
RUN ./optimize.sh src/Main.elm


############################
# PRODUCTION STAGE
############################


FROM node:12-alpine as production

WORKDIR /app

RUN yarn add serve

COPY --from=prod-builder /workdir/main.min.js public/main.js
COPY public/index.html public/index.html
COPY public/sentry.js public/sentry.js
COPY scripts/run-production.sh run-production.sh

EXPOSE $PORT

ENTRYPOINT ["/app/run-production.sh"]

############################
# CI STAGE
############################

# We need buster for high enough glibc version for elm-format
FROM node:12-buster as ci

#### IMPORTANT: To have any changes actually take effect in CI, you have
#### to go change the version number in the yaml file too

ENV ELM_TEST_VERSION 0.19.1
ENV ELM_FORMAT_VERSION 0.8.4
ENV ELM_VERIFY_EXAMPLES_VERSION 5.0.0
ENV ELM_ANALYSE_VERSION 0.16.5

RUN cd / && mkdir dependencies && cd dependencies && \
    yarn add \
        elm-test@$ELM_TEST_VERSION \
        elm-format@$ELM_FORMAT_VERSION \
        elm-verify-examples@$ELM_VERIFY_EXAMPLES_VERSION \
        elm-analyse@$ELM_ANALYSE_VERSION

ENV PATH "$PATH:/dependencies/node_modules/.bin"

WORKDIR /ci-home

COPY --from=dependency-builder /dependencies/elm /usr/local/bin

############################
# CI WITH BROWSERS STAGE
############################

FROM node:12 AS ci-browsers

#### IMPORTANT: To have any changes actually take effect in CI, you have
#### to go change the version number in the yaml file too

# All the Cypress dependencies
# Taken from https://github.com/cypress-io/cypress-docker-images/blob/master/base/12.8.1/Dockerfile
# and also https://github.com/cypress-io/cypress-docker-images/blob/master/browsers/node12.18.3-chrome87-ff82/Dockerfile
RUN apt-get update && \
  apt-get install --no-install-recommends -y \
  libgtk2.0-0 \
  libgtk-3-0 \
  libnotify-dev \
  libgconf-2-4 \
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
  # Chrome specific dependencies
  fonts-liberation  \
  libappindicator3-1 \
  xdg-utils \
  # add codecs needed for video playback in firefox
  # https://github.com/cypress-io/cypress-docker-images/issues/150
  mplayer \
  # clean up
  && rm -rf /var/lib/apt/lists/*

# check https://chromium.cypress.io/
# and https://caniuse.com/usage-table for lowest versions that are widely used
ENV CHROME_VERSION 88.0.4324.96
ENV FIREFOX_VERSION 87.0
# "fake" dbus address to prevent errors
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# install Chrome browser
RUN wget -O /usr/src/google-chrome-stable_current_amd64.deb "http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}-1_amd64.deb" && \
  dpkg -i /usr/src/google-chrome-stable_current_amd64.deb ; \
  apt-get install -f -y && \
  rm -f /usr/src/google-chrome-stable_current_amd64.deb

# install Firefox browser
RUN wget --no-verbose -O /tmp/firefox.tar.bz2 https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2 \
  && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
  && rm /tmp/firefox.tar.bz2 \
  && ln -fs /opt/firefox/firefox /usr/bin/firefox


############################
# LOCAL DEVELOPMENT STAGE
############################


# The `unsafe-html-cube-devcontainer` is built in the
# initializeCommand for the devcontainer from base.dockerfile
# which is located in the .devcontainer directory
FROM unsafe-html-cube-devcontainer:12 AS local-development

ENV ELM_LIVE_VERSION 4.0.2

USER $USERNAME

WORKDIR /home/$USERNAME

ENV HISTFILE /home/$USERNAME/bash_history/bash_history.txt

# Install the development specific ones
RUN yarn global add \
        elm-live@$ELM_LIVE_VERSION \
    # Create the elm cache directory where we can mount a volume. If we don't create it like this
    # it is auto created by docker on volume creation but with root as owner which makes it unusable.
    && mkdir .elm \
    # Similar story here with the bash history we store in a volume
    && mkdir -p $(dirname $HISTFILE)

ENV PATH "$PATH:/home/$USERNAME/.yarn/bin"

RUN echo 'PATH="$PATH:/home/$USERNAME/.yarn/bin"' >> .bashrc

# Add in the dependencies shared between stages
COPY --from=dependency-builder /dependencies/elm /usr/local/bin
COPY --from=dependency-builder /dependencies/node_modules /uglifyjs/node_modules
COPY --from=ci /dependencies/node_modules /test-and-linters/node_modules

USER root

RUN ln -s /uglifyjs/node_modules/.bin/uglifyjs /usr/local/bin/uglifyjs
RUN ln -s /test-and-linters/node_modules/.bin/elm-test /usr/local/bin/elm-test
RUN ln -s /test-and-linters/node_modules/.bin/elm-format /usr/local/bin/elm-format
RUN ln -s /test-and-linters/node_modules/.bin/elm-verify-examples /usr/local/bin/elm-verify-examples
RUN ln -s /test-and-linters/node_modules/.bin/elm-analyse /usr/local/bin/elm-analyse

USER $USERNAME
