
# This is built in the initializeCommand for the devcontainer
# from base.dockerfile which is located here in this directory
FROM unsafe-html-cube-devcontainer

ENV ELM_VERSION 0.19.1
ENV ELM_TEST_VERSION 0.19.1
ENV ELM_FORMAT_VERSION 0.8.4
ENV ELM_LIVE_VERSION 4.0.2
ENV UGLIFY_JS_VERSION 3.12.4
ENV ELM_VERIFY_EXAMPLES_VERSION 5.0.0

USER $USERNAME

WORKDIR /home/$USERNAME

RUN yarn global add \
        elm@$ELM_VERSION \
        elm-test@$ELM_TEST_VERSION \
        elm-format@$ELM_FORMAT_VERSION \
        elm-live@$ELM_LIVE_VERSION \
        uglify-js@$UGLIFY_JS_VERSION \
        elm-verify-examples@$ELM_VERIFY_EXAMPLES_VERSION \
    # Create the elm cache directory where we can mount a volume. If we don't create it like this
    # it is auto created by docker on volume creation but with root as owner which makes it unusable.
    && mkdir .elm

ENV PATH "$PATH:/home/$USERNAME/.yarn/bin"

RUN echo 'PATH="$PATH:/home/$USRENAME/.yarn/bin"' >> .bashrc
