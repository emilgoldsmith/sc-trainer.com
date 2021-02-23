export function interceptAddingElmModelObserversAndModifiers(): void {
  cy.intercept(
    new RegExp(String.raw`^${Cypress.config().baseUrl}/?$`),
    (req) => {
      req.reply((res) => {
        const withE2eHelpers = addToDocumentHead({
          toAdd: `<script>
                    (${addE2ETestHelpersToWindow.toString()}())
                  </script>`,
          body: res.body,
        });
        const withEverything = addObserversAndModifiers(withE2eHelpers);
        res.send(withEverything);
      });
    }
  );
}

function addToDocumentHead({ toAdd, body }: { toAdd: string; body: string }) {
  return body.replace("<head>", "<head>" + toAdd);
}

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

function addObserversAndModifiers(htmlString: string) {
  const parsedJs = parseTheJavascript(htmlString);
  // Gotten by adding a console.log(JSON.stringify(initPair.b)) while the initial command was Cmd.None in app code
  const cmdDotNone = '{"$":3,"o":{"$":2,"m":{"$":"[]"}}}';
  const modifiedParsedJs = {
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
  return joinParsedJs(modifiedParsedJs);
}

function parseTheJavascript(htmlString: string) {
  const {
    beforeSendToApp,
    sendToAppDefinition,
    afterSendToApp,
    modelVariableName,
    updaterFunctionName,
    enqueueEffectsFunctionName,
    managersVariableName,
    subscriptionsFunctionName,
  } = parseSendToAppFunction(htmlString);

  let initializeStartIndex = beforeSendToApp.length;
  let startLevel = 0;
  while (
    !(
      startLevel === -1 &&
      htmlString.substr(initializeStartIndex, "function".length) === "function"
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

  const beforeInitialize = beforeSendToApp.substring(0, initializeStartIndex);
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

function parseSendToAppFunction(htmlString: string) {
  const regex = new RegExp(
    [
      // function keyword + function name + possible whitespace after
      /function \w+\s*/,
      // variable amount of function argument definitions
      /\([,\w\s]*\)/,
      // Any amount of whitespace including newlines
      /[\s\n]*/,
      // Start of function body
      /\{/,
      // Pass through as few lines of code as possible until the next pattern matches
      // is pretty much equivalent to [\s\S]+? but will just fail a bit more accurately
      // as we for example don't expect any curly braces, this specifically specifies variable
      // names as \w, and different operators such as , ) ; = (
      /[\s\n\w(),;=]*?/,
      // The next few lines we are intending to capture this line (shown unminimized): `stepper(model = pair.a, viewMetadata);`
      // Here we first capture the function name, as we need to call this when the model updates
      /(\w+)/,
      // Start argument specification
      /\(/,
      // Capture the model variable name in the first argument `model = pair.a` (unminimized version)
      /(\w+)\s*=\s*\w+\.a\s*,/,
      /\s*\w+\)[\s;,\n]*(\w+)\s*\(\s*(\w+),[^,]+,\s*(\w+)\s*\([\s\S]+?\}/,
    ]
      .map((x) => x.toString().substring(1, x.toString().length - 1))
      .concat([])
      .join(""),
    "g"
  );
  const candidates: RegExpExecArray[] = [];
  let result = regex.exec(htmlString);
  while (result) {
    candidates.push(result);
    result = regex.exec(htmlString);
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
  const endIndex = finalResult.index + getOrThrow(0, finalResult).length;
  const beforeSendToApp = htmlString.substring(0, startIndex);
  const sendToAppDefinition = htmlString.substring(startIndex, endIndex);
  const afterSendToApp = htmlString.substring(endIndex);
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

function addObserversToModel(
  modelVariableName: string,
  someJavascript: string
): string {
  return someJavascript.replace(
    new RegExp(String.raw`(\b${modelVariableName}\b\s*=\s*)([\w.]+)`),
    "$1(window.END_TO_END_TEST_HELPERS.internal.setModel($2),$2)"
  );
}

function joinParsedJs(parsed: ReturnType<typeof parseTheJavascript>): string {
  return (
    parsed.beforeInitialize +
    parsed.beforeSendToAppInInitialize +
    parsed.sendToAppDefinition +
    parsed.afterSendToAppInInitialize +
    parsed.afterInitialize
  );
}
