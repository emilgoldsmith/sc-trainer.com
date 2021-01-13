FROM node:15.5.1-buster

USER node

WORKDIR /home/node

RUN yarn global add \
    elm@0.19.1 \
    elm-test@0.19.1 \
    elm-format@0.8.4 \
    elm-live@4.0.2 \
    uglify-js@3.12.4

ENV PATH "$PATH:/home/node/.yarn/bin"

RUN echo 'PATH="$PATH:/home/node/.yarn/bin"' >> .bashrc
