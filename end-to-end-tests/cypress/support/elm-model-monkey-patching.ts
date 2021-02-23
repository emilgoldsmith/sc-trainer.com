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

/**
 * This function is intending to parse the initialize function
 * in both an unminimized and a minimized/uglified version.
 *
 * For more information about the parsing logic see the parseSendToAppFunction documentation
 * as that is where the most complex bits of the logic live
 *
 * For reference the unminimized code looks like this:
 *
 * @example
 *
 * function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
 * {
 *         var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
 *         $elm$core$Result$isOk(result) || _Debug_crash(2 , _Json_errorToString(result.a) );
 *         var managers = {};
 *         var initPair = init(result.a);
 *         var model = initPair.a;
 *         var stepper = stepperBuilder(sendToApp, model);
 *         var ports = _Platform_setupEffects(managers, sendToApp);
 *
 *         function sendToApp(msg, viewMetadata)
 *         {
 *                 var pair = A2(update, msg, model);
 *                 stepper(model = pair.a, viewMetadata);
 *                 _Platform_enqueueEffects(managers, pair.b, subscriptions(model));
 *         }
 *
 *         _Platform_enqueueEffects(managers, initPair.b, subscriptions(model));
 *
 *         return ports ? { ports: ports } : {};
 * }
 */
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

  const {
    initializeStartIndex,
    initializeEndIndex,
  } = getIndiciesForSurroundingFunction({
    curStartIndex: beforeSendToApp.length,
    htmlString,
    afterSendToApp,
  });

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

function getIndiciesForSurroundingFunction({
  curStartIndex,
  htmlString,
  afterSendToApp,
}: {
  curStartIndex: number;
  htmlString: string;
  afterSendToApp: string;
}) {
  let initializeStartIndex = curStartIndex;
  let startLevel = 0;
  while (
    !(
      startLevel === -1 &&
      htmlString.substr(initializeStartIndex, "function".length) === "function"
    )
  ) {
    if (htmlString[initializeStartIndex] === "{") startLevel--;
    if (htmlString[initializeStartIndex] === "}") startLevel++;
    initializeStartIndex--;
  }

  let initializeEndIndex = 0;
  let endLevel = 0;
  while (endLevel !== -1) {
    if (afterSendToApp[initializeEndIndex - 1] === "{") endLevel++;
    if (afterSendToApp[initializeEndIndex - 1] === "}") endLevel--;
    initializeEndIndex++;
  }
  return { initializeStartIndex, initializeEndIndex };
}

function parseSendToAppFunction(htmlString: string) {
  /**
   * We here try to create a regular expression that in a huge html/javascript string
   * can find the sendToApp function uniquely as the only match. Lots of explanation about
   * the parts below and also which parts really work for that unicity for us.
   *
   * It needs to work for both an uglified/minimized version and a development version.
   * It is obviously very brittle in the sense that if a new elm version is released there's
   * a large chance this will break.
   *
   * For reference this was built using elm 0.19.1 and the unminified version it is matching on is:
   * (hover over the regex variable to see it with syntax highlighting)
   *
   * @example
   * function sendToApp(msg, viewMetadata)
   * {
   *   var pair = A2(update, msg, model);
   *   stepper(model = pair.a, viewMetadata);
   *   _Platform_enqueueEffects(managers, pair.b, subscriptions(model));
   * }
   *
   *
   */
  const regex = buildRegex(
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
      /**
       * The next few lines we are intending to capture this line (shown unminimized): `stepper(model = pair.a, viewMetadata);`
       * The main reason this whole regex lets us find the right place in a whole html string is
       * because the structure of having an assignment and a `.a` accessing in the first argument in a
       * 2 argument expression is sufficiently unique.
       * We're also lucky that the `.a` seems to be preserved across minimizing/uglifying, though it could
       * probably work with matching towards an arbitrary property name there too
       */
      // CAPTURE NUMBER 1:
      // Here we first capture the function name, as we need to call this when the model updates
      /(\w+)/,
      // Start argument specification
      /\(/,
      // CAPTURE NUMBER 2:
      // Capture the model variable name in the first argument `model = pair.a` (unminimized version)
      /(\w+)\s*=\s*\w+\.a\s*,/,
      // Match the second argument which we don't care about
      /\s*\w+/,
      // Match any whitespace
      /\s*/,
      // Finish argument parsing
      /\)/,
      // We need to get to the next line, between here and there depending
      // on whether minified or not, there can be a combination of a semicolon,
      // a comma, whitespace or a newline
      /[\s;,\n]*/,
      /**
       * these next lines try to capture
       * (unminified version) `_Platform_enqueueEffects(managers, pair.b, subscriptions(model));`
       */
      // CAPTURE NUMBER 3:
      // Capture the function name
      /(\w+)\s*/,
      // Start argument parsing
      /\(/,
      // CAPTURE NUMBER 4:
      // Capture the managers variable
      /\s*(\w+),/,
      // Parse the next argument which we don't care about
      /[^,]+,/,
      // CAPTURE NUMBER 5:
      // Capture the subscriptions function name, as soon as we reach the function call `(`
      // We no longer care about the rest as we're confident it's the right place
      /\s*(\w+)\s*\(/,
      // Parse anything including newlines
      /[\s\S]+?/,
      // Until we reach the end of the sendToApp function to make sure the endIndex is correct
      // for our overall parsing
      /\}/,
    ],
    "g"
  );
  const candidates: RegExpExecArray[] = applyGlobalRegex(regex, htmlString);
  const finalResult = ensureSingletonListAndExtract(candidates);

  const startIndex = finalResult.index;
  const endIndex = finalResult.index + getOrThrow(0, finalResult).length;
  return {
    beforeSendToApp: htmlString.substring(0, startIndex),
    sendToAppDefinition: htmlString.substring(startIndex, endIndex),
    afterSendToApp: htmlString.substring(endIndex),
    updaterFunctionName: getOrThrow(1, finalResult),
    modelVariableName: getOrThrow(2, finalResult),
    enqueueEffectsFunctionName: getOrThrow(3, finalResult),
    managersVariableName: getOrThrow(4, finalResult),
    subscriptionsFunctionName: getOrThrow(5, finalResult),
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

function buildRegex(regexParts: RegExp[], flags: string): RegExp {
  return new RegExp(
    regexParts
      .map((x) => {
        const asString = x.toString();
        const withoutFirstForwardSlash = asString.substring(1);
        const withoutLastSlashAndFlags = withoutFirstForwardSlash.replace(
          /\/\w*$/,
          ""
        );
        return withoutLastSlashAndFlags;
      })
      .join(""),
    flags
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

function ensureSingletonListAndExtract<T>(candidates: T[]): T {
  const finalResult = candidates[0];
  if (finalResult === undefined || candidates.length !== 1) {
    throw new Error(
      "Our regular expression for patching elm to be able to programatically modify state found a wrong amount of candidates, which should not happen, maybe the elm version or our minifying setup changed?    " +
        JSON.stringify(candidates)
    );
  }
  return finalResult;
}

function applyGlobalRegex(
  regex: RegExp,
  htmlString: string
): RegExpExecArray[] {
  const candidates: RegExpExecArray[] = [];
  let result = regex.exec(htmlString);
  while (result) {
    candidates.push(result);
    result = regex.exec(htmlString);
  }
  return candidates;
}
