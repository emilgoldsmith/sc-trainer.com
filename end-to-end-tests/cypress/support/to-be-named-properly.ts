function addE2ETestHelpersToWindow() {
  "use strict";
  let model: Cypress.OurApplicationState | null = null;
  let modelUpdater:
    | ((newModel: Cypress.OurApplicationState) => void)
    | null = null;

  (window as Cypress.CustomWindow).END_TO_END_TEST_HELPERS = {
    getModel() {
      if (model === null) {
        throw new Error(
          "Model was attempted to be accessed before it has been set"
        );
      }
      return model;
    },
    setModel(newModel) {
      if (modelUpdater === null) {
        throw new Error(
          "Model attempted to be set before model has been registered"
        );
      }
      modelUpdater(newModel);
      model = newModel;
    },
    internal: {
      setModel: (newModel) => (model = newModel),
      registerModelUpdater: (updater) => (modelUpdater = updater),
    },
  };
}

export function interceptAddingElmModelObserversAndModifiers(): void {
  cy.intercept(
    new RegExp(String.raw`^${Cypress.config().baseUrl}/$`),
    (req) => {
      req.reply((res) => {
        const addToDocumentHead = (toAdd: string, body: string) =>
          body.replace("<head>", "<head>" + toAdd);

        function parseSendToApp(javascriptString: string) {
          const regex = /function \w+\([,\w\s]*?\)[\s\n]*?\{[\s\n\w(),;=]+?(\w+)\((\w+)\s*=\s*\w+\.a\s*,\s*\w+\)[\s;,\n]*(\w+)\s*\(\s*(\w+),[^,]+,\s*(\w+)\s*\([\s\S]+?\}/g;
          const candidates: RegExpExecArray[] = [];
          let result = regex.exec(javascriptString);
          while (result) {
            candidates.push(result);
            result = regex.exec(javascriptString);
          }
          const finalResult = candidates[0];
          if (finalResult === undefined || candidates.length !== 1) {
            throw new Error(
              "Our regular expression for patching elm to be able to programatically modify state found a wrong amount of candidates, which should not happen, maybe the elm version or our minifying setup changed?    " +
                JSON.stringify(candidates)
            );
          }
          function getOrThrow<T>(index: number, list: T[]): T {
            const candidate = list[index];
            if (candidate === undefined) {
              throw new Error(
                "Expected item to exist at index " +
                  index +
                  " in list " +
                  JSON.stringify(list)
              );
            }
            return candidate;
          }
          const startIndex = finalResult.index;
          const endIndex =
            finalResult.index + getOrThrow(0, finalResult).length;
          const beforeSendToApp = javascriptString.substring(0, startIndex);
          const sendToAppDefinition = javascriptString.substring(
            startIndex,
            endIndex
          );
          const afterSendToApp = javascriptString.substring(endIndex);
          const updaterFunctionName = getOrThrow(1, finalResult);
          const modelVariableName = getOrThrow(2, finalResult);
          const enqueueEffectsFunctionName = getOrThrow(3, finalResult);
          const managersVariableName = getOrThrow(4, finalResult);
          const subscriptionsFunctionName = getOrThrow(5, finalResult);
          return {
            beforeSendToApp,
            sendToAppDefinition,
            afterSendToApp,
            modelVariableName,
            updaterFunctionName,
            enqueueEffectsFunctionName,
            managersVariableName,
            subscriptionsFunctionName,
          };
        }

        function parseTheJavascript(javascriptString: string) {
          const {
            beforeSendToApp,
            sendToAppDefinition,
            afterSendToApp,
            modelVariableName,
            updaterFunctionName,
            enqueueEffectsFunctionName,
            managersVariableName,
            subscriptionsFunctionName,
          } = parseSendToApp(javascriptString);

          let initializeStartIndex = beforeSendToApp.length;
          let startLevel = 0;
          while (
            !(
              startLevel === -1 &&
              javascriptString.substr(
                initializeStartIndex,
                "function".length
              ) === "function"
            )
          ) {
            if (beforeSendToApp[initializeStartIndex] === "{") startLevel--;
            if (beforeSendToApp[initializeStartIndex] === "}") startLevel++;
            initializeStartIndex--;
          }

          let initializeEndIndex = 0;
          let endLevel = 0;
          while (endLevel !== -1) {
            if (afterSendToApp[initializeEndIndex - 1] === "{") endLevel++;
            if (afterSendToApp[initializeEndIndex - 1] === "}") endLevel--;
            initializeEndIndex++;
          }

          const beforeInitialize = beforeSendToApp.substring(
            0,
            initializeStartIndex
          );
          const beforeSendToAppInInitialize = beforeSendToApp.substring(
            initializeStartIndex
          );
          const afterSendToAppInInitialize = afterSendToApp.substring(
            0,
            initializeEndIndex
          );
          const afterInitialize = afterSendToApp.substring(initializeEndIndex);
          return {
            beforeInitialize,
            beforeSendToAppInInitialize,
            sendToAppDefinition,
            afterSendToAppInInitialize,
            afterInitialize,
            modelVariableName,
            updaterFunctionName,
            enqueueEffectsFunctionName,
            managersVariableName,
            subscriptionsFunctionName,
          };
        }
        function addObserversToModel(
          modelVariableName: string,
          someJavascript: string
        ): string {
          return someJavascript.replace(
            new RegExp(String.raw`(\b${modelVariableName}\b\s*=\s*)([\w.]+)`),
            "$1(window.END_TO_END_TEST_HELPERS.internal.setModel($2),$2)"
          );
        }
        function addObservers(parsedJs: ReturnType<typeof parseTheJavascript>) {
          // Gotten by adding a console.log(JSON.stringify(initPair.b)) while the initial command was Cmd.None
          const cmdDotNone = '{"$":3,"o":{"$":2,"m":{"$":"[]"}}}';
          return {
            ...parsedJs,
            beforeSendToAppInInitialize: addObserversToModel(
              parsedJs.modelVariableName,
              parsedJs.beforeSendToAppInInitialize
            ),
            sendToAppDefinition:
              addObserversToModel(
                parsedJs.modelVariableName,
                parsedJs.sendToAppDefinition
              ) +
              `;window.END_TO_END_TEST_HELPERS.internal.registerModelUpdater((newModel) => {
                ${parsedJs.modelVariableName} = newModel;
                ${parsedJs.updaterFunctionName}(newModel, true);
                ${parsedJs.enqueueEffectsFunctionName}(
                    ${parsedJs.managersVariableName},
                    ${cmdDotNone},
                    ${parsedJs.subscriptionsFunctionName}(newModel),
                )
              });`,
          };
        }
        function joinParsedJs(
          parsed: ReturnType<typeof parseTheJavascript>
        ): string {
          return (
            parsed.beforeInitialize +
            parsed.beforeSendToAppInInitialize +
            parsed.sendToAppDefinition +
            parsed.afterSendToAppInInitialize +
            parsed.afterInitialize
          );
        }
        const bodyWithE2eHelpers = addToDocumentHead(
          `<script>
            (${addE2ETestHelpersToWindow.toString()}())
          </script>`,
          res.body
        );
        const bodyWithModelObservers = joinParsedJs(
          addObservers(parseTheJavascript(bodyWithE2eHelpers))
        );
        res.send(bodyWithModelObservers);
      });
    }
  );
}
