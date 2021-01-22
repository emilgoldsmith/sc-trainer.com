FROM node:15.5.1-buster

USER node

WORKDIR /home/node

RUN yarn global add \
    elm@0.19.1 \
    elm-test@0.19.1 \
    elm-format@0.8.4 \
    elm-live@4.0.2 \
    uglify-js@3.12.4 \
    elm-verify-examples@5.0.0 \
    # Create the elm cache directory where we can mount a volume. If we don't create it like this
    # it is auto created by docker on volume creation but with root as owner which makes it unusable.
    && mkdir .elm

ENV PATH "$PATH:/home/node/.yarn/bin"

RUN echo 'PATH="$PATH:/home/node/.yarn/bin"' >> .bashrc
