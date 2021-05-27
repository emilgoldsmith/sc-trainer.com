export function addElmModelObserversAndModifiersToHtml(previousHtml: {
  type: "html";
  value: string;
}): string {
  return addToDocumentHead({
    toAdd: addE2ETestHelpersToWindow,
    htmlString: previousHtml.value,
  });
}

export function addElmModelObserversAndModifiersToJavascript(previousJavascript: {
  type: "js";
  value: string;
}): string {
  return addObserversAndModifiers(previousJavascript.value);
}

function addToDocumentHead({
  toAdd,
  htmlString,
}: {
  toAdd: () => void;
  htmlString: string;
}): string {
  return htmlString.replace(
    "<head>",
    `<head><script>(${toAdd.toString()}())</script>`
  );
}

export function fixRandomnessSeedInJavascript(
  previousJavascript: { type: "js"; value: string },
  seed = 0
): string {
  const toTry = [
    fixSeedUnminimized,
    fixSeedTerserMinimized,
    fixSeedUglifyJsMinified,
  ];
  const errors: Error[] = [];
  for (const fixer of toTry) {
    try {
      return fixer(previousJavascript, seed);
    } catch (e) {
      if (e instanceof Error) errors.push(e);
      else errors.push(new Error(e));
    }
  }
  const errorMessage = errors.reduce(
    (curMessage, nextError) =>
      (curMessage += `ErrorMessage: ${nextError.message}\n\nStacktrace: ${nextError.stack}\n\n`),
    ""
  );
  throw new Error(errorMessage);
}

function fixSeedUnminimized(
  previousJavascript: { type: "js"; value: string },
  seed: number
) {
  /**
   * Here we are aiming to match the following line:
   * _Platform_effectManagers['Random'] = _Platform_createManager($elm$random$Random$init, $elm$random$Random$onEffects, $elm$random$Random$onSelfMsg, $elm$random$Random$cmdMap);
   */
  const initExtractorRegex = buildRegex(
    [
      // The identifier
      String.raw`\['Random'\]`,
      // Assignment and function name
      String.raw`\s*=\s*\w+\s*\(`,
      // Get the first argument which is the function Random.init
      `(.+?),`,
    ],
    "g"
  );
  const matches = applyGlobalRegex(
    initExtractorRegex,
    previousJavascript.value
  );
  const initFunctionName = getOrThrow(
    1,
    ensureSingletonListAndExtract(matches)
  );
  /**
   * Here we are aiming to match the following code:
   *
   *
   * var $elm$random$Random$init = A2(
   * 	$elm$core$Task$andThen,
   * 	function (time) {
   * 		return $elm$core$Task$succeed(
   * 			$elm$random$Random$initialSeed(
   * 				$elm$time$Time$posixToMillis(time)));
   * 	},
   * 	$elm$time$Time$now);
   */
  const regex = buildRegex(
    [
      // Capture the prefix we just include to make sure it's a unique match
      "(",
      // The identifier
      initFunctionName.replace(/\$/g, "\\$"),
      // The assignment of that identifier
      String.raw`\b\s*=.*?\(`,
      // Go through three function openings
      String.raw`[\s\S]+?\(`,
      String.raw`[\s\S]+?\(`,
      String.raw`[\s\S]+?\(`,
      // This is where we want to replace from so we stop capturing
      ")",
      // Capture everything passed to the last function, so until the parentheses close
      String.raw`[\s\S]+?\)`,
    ],
    "g"
  );
  // Ensure there's only a single match with a capture group
  getOrThrow(
    0,
    ensureSingletonListAndExtract(
      applyGlobalRegex(regex, previousJavascript.value)
    )
  );
  // Replace the matched part with our specified seed
  const withPatchedSeedValue = previousJavascript.value.replace(
    regex,
    "$1" + seed.toString()
  );
  return withPatchedSeedValue;
}

function fixSeedUglifyJsMinified(
  previousJavascript: { type: "js"; value: string },
  seed: number
) {
  /**
   * Here we are trying to match the following line:
   * Bn.Random={b:O,c:Oc,d:zn,e:U,f:void 0}
   */
  const initExtractorRegex = buildRegex(
    [
      // The identifier
      String.raw`\.Random`,
      // expecting an assignment, we don't have to care about whitespace
      // since it's minimized
      String.raw`=`,
      // We grab up until the value of the first property of the object
      String.raw`\{.*?:`,
      // Capture that first property name which is the Random.init function name
      String.raw`(\w+),`,
    ],
    "g"
  );
  const matches = applyGlobalRegex(
    initExtractorRegex,
    previousJavascript.value
  );
  const initFunctionName = getOrThrow(
    1,
    ensureSingletonListAndExtract(matches)
  );
  /**
   * Here we are trying to match the following line:
   * O=N(Pe,function(n){return ze((r=ou(n),n=fu(N(Lc,0,1013904223)),fu(N(Lc,n.a+r>>>0,n.b))))
   */
  const regex = buildRegex(
    [
      // Capture the prefix for the replace. Since it's minimized several
      // places can use this variable name so we need a lot of context for it to be unique
      "(",
      String.raw`\b${initFunctionName}\b`,
      // The asignment of our function name which value is the result of a function call
      String.raw`=\w+\(`,
      // Which has the first argument as an identifier, and the second a function with one argument that directly returns something
      String.raw`\w+,function\(\w+\){return `,
      // A function call with a leading open paranthesis for a comma operator syntax
      String.raw`\w+\(\(`,
      // Which is an assignment to an identifier
      String.raw`\w+=`,
      // We want to replace the rest from here so no more capturing
      ")",
      // get up until the next part of the comma operator
      "[^,]+",
      // Ensure a comma shows up and capture it as we don't want to change it
      "(",
      ",",
      ")",
    ],
    "g"
  );
  // Ensure there's only a single match with a capture group
  getOrThrow(
    0,
    ensureSingletonListAndExtract(
      applyGlobalRegex(regex, previousJavascript.value)
    )
  );
  const withPatchedSeed = previousJavascript.value.replace(
    regex,
    "$1" + seed.toString() + "$2"
  );
  return withPatchedSeed;
}

function fixSeedTerserMinimized(
  previousJavascript: { type: "js"; value: string },
  seed: number
) {
  /**
   * Here we are trying to match the following line:
   * An.Random=En(Ni,zi,Ri,t((function(n,r){return i(_i,n,r)})));
   */
  const initExtractorRegex = buildRegex(
    [
      // The identifier
      String.raw`\.Random`,
      // expecting an assignment, we don't have to care about whitespace
      // since it's minimized
      String.raw`=`,
      // We pass by the function name
      String.raw`\w+\(`,
      // Capture that first argument which is the Random.init function name
      String.raw`(\w+),`,
    ],
    "g"
  );
  const matches = applyGlobalRegex(
    initExtractorRegex,
    previousJavascript.value
  );
  const initFunctionName = getOrThrow(
    1,
    ensureSingletonListAndExtract(matches)
  );
  /**
   * Here we are trying to match the following line:
   * O=N(Pe,function(n){return ze((r=ou(n),n=fu(N(Lc,0,1013904223)),fu(N(Lc,n.a+r>>>0,n.b))))
   */
  const regex = buildRegex(
    [
      // Capture the prefix for the replace. Since it's minimized code, several
      // places can use this variable name so we need a lot of context for it to be unique
      "(",
      String.raw`\b${initFunctionName}\b`,
      // The asignment of our function name which value is the result of a function call
      String.raw`=\w+\(`,
      // Which has the first argument as an identifier, and the second a function with one argument that directly returns something
      String.raw`\w+,\(function\(\w+\)\{return `,
      // A function call where the first parameter is a temporary function closure with one argument
      String.raw`\w+\(function\(\w+\)\{.+?\}`,
      // The value passed to the temporary function closure
      String.raw`\(`,
      // We want to replace the rest from here so no more capturing
      ")",
      // get up until the end of the value passed to the closure
      "[^)]+",
      // Ensure a closing parenthesis shows up and capture it as we don't want to change it
      "(",
      String.raw`\)`,
      ")",
    ],
    "g"
  );
  // Ensure there's only a single match with a capture group
  getOrThrow(
    0,
    ensureSingletonListAndExtract(
      applyGlobalRegex(regex, previousJavascript.value)
    )
  );
  const withPatchedSeed = previousJavascript.value.replace(
    regex,
    "$1" + seed.toString() + "$2"
  );
  return withPatchedSeed;
}

function addE2ETestHelpersToWindow() {
  "use strict";
  const documentEventListeners = trackDocumentEventListeners();
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
      clearAllTimers();
      model = newModel;
    },
    getDocumentEventListeners() {
      return new Set(documentEventListeners.values());
    },
    internal: {
      setModel: (newModel) => (model = newModel),
      registerModelUpdater: (updater) => (modelUpdater = updater),
    },
  };

  function trackDocumentEventListeners(): Set<keyof DocumentEventMap> {
    const eventListeners = new Set<keyof DocumentEventMap>();
    const add = document.addEventListener;
    const remove = document.removeEventListener;
    const documentCreationTime = Date.now();

    document.addEventListener = function (
      eventName: keyof DocumentEventMap,
      eventListener: EventListenerOrEventListenerObject,
      c?: boolean | AddEventListenerOptions
    ) {
      eventListeners.add(eventName);
      /**
       * We do this because otherwise it won't respect our time mocking as the event timestamp
       * seems to be created in native code not using Date.now() etc.
       */
      const listenerWithTimestampOverriding = function (e: Event) {
        const modifiedEvent: Event & { timeStampModified?: boolean } = e;
        if (!modifiedEvent.timeStampModified) {
          modifiedEvent.timeStampModified = true;
          const newTimestamp = Date.now() - documentCreationTime;
          Object.defineProperty(modifiedEvent, "timeStamp", {
            get() {
              return newTimestamp;
            },
          });
          if ("handleEvent" in eventListener) {
            eventListener.handleEvent(e);
          } else {
            eventListener(e);
          }
        }
      };
      add.call(this, eventName, listenerWithTimestampOverriding, c);
    };
    document.removeEventListener = function (
      eventName: keyof DocumentEventMap,
      b: EventListenerOrEventListenerObject,
      c?: boolean | AddEventListenerOptions
    ) {
      eventListeners.delete(eventName);
      remove.call(this, eventName, b, c);
    };
    return eventListeners;
  }

  let timeoutIds: number[] = [];
  let intervalIds: number[] = [];

  function clearAllTimers(): void {
    timeoutIds.forEach(clearTimeout);
    timeoutIds = [];
    intervalIds.forEach(clearInterval);
    intervalIds = [];
  }

  const originalSetTimeout = window.setTimeout;
  window.setTimeout = function (
    ...args: Parameters<typeof window.setTimeout>
  ): ReturnType<typeof window.setTimeout> {
    const id = originalSetTimeout(...args);
    timeoutIds.push(id);
    return id;
  };

  const originalSetInterval = window.setInterval;
  window.setInterval = function (
    ...args: Parameters<typeof window.setInterval>
  ): ReturnType<typeof window.setInterval> {
    const id = originalSetInterval(...args);
    intervalIds.push(id);
    return id;
  };
}

function addObserversAndModifiers(htmlString: string) {
  const parsedJs = parseTheJavascript(htmlString);
  // Gotten by adding a console.log(JSON.stringify(initPair.b)) while the initial command was Cmd.None in app code
  const cmdDotNone = '{"$":3,"o":{"$":2,"m":{"$":"[]"}}}';
  return joinParsedJs({
    ...parsedJs,
    // We want to add listeners to any model assignments anywhere in the initialize function
    beforeSendToAppInInitialize: addListenersToAnyModelAssignments({
      modelVariableName: parsedJs.modelVariableName,
      htmlString: parsedJs.beforeSendToAppInInitialize,
      onlyReplaceFirst: true,
    }),
    sendToAppDefinition:
      addListenersToAnyModelAssignments({
        modelVariableName: parsedJs.modelVariableName,
        htmlString: parsedJs.sendToAppDefinition,
      }) +
      // We define the function to be called when we manually overwrite the elm application state.
      // It is just convenient placing it here as we know it's right after a function definition
      // so it won't be in the middle of a comma operator or var assignment with commas in the
      // minified code
      //
      // By trial and error / reverse engineering we discovered what is needed, in order of actions
      // in the below function, is:
      // 1. Set the model to our new model
      // 2. Call the updater function (in the unminimized, this is called stepper).
      // The second argument is the isSync argument which can be seen in the return value
      // of _Browser_makeAnimator in the unminimized Elm code. It is simply a qualified guess
      // that we always want sync updates, the non sync version uses requestAnimationFrame
      // so is probably related to making games or animations
      // 3. Call enqueue effects with
      //   a) The managers variable that is in scope (we don't change this ever)
      //   b) A Cmd.None value
      //   c) The subscriptions specified by the applications pure function subscriptions
      // We do this not to have any effects happen, but this is what registers subscriptions
      // such as event listeners, and they often need changing
      `;window.END_TO_END_TEST_HELPERS.internal.registerModelUpdater((newModel) => {
                ${parsedJs.modelVariableName} = newModel;
                ${parsedJs.updaterFunctionName}(newModel, true);
                ${parsedJs.enqueueEffectsFunctionName}(
                    ${parsedJs.managersVariableName},
                    ${cmdDotNone},
                    ${parsedJs.subscriptionsFunctionName}(newModel),
                )
              });`,
    afterSendToAppInInitialize: addListenersToAnyModelAssignments({
      modelVariableName: parsedJs.modelVariableName,
      htmlString: parsedJs.afterSendToAppInInitialize,
    }),
  });
}

/**
 * This function is intending to find and parse the initialize function
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

  const [
    initializeStartIndex,
    initializeEndIndex,
  ] = getIndiciesForSurroundingFunction({
    curStartIndex: beforeSendToApp.length,
    curEndIndex: htmlString.length - afterSendToApp.length + 1,
    htmlString,
  });

  const beforeInitialize = beforeSendToApp.substring(0, initializeStartIndex);
  const beforeSendToAppInInitialize = beforeSendToApp.substring(
    initializeStartIndex
  );
  const afterSendToAppInInitialize = htmlString.substring(
    htmlString.length - afterSendToApp.length,
    initializeEndIndex
  );
  const afterInitialize = htmlString.substring(initializeEndIndex);
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
  curEndIndex,
  htmlString,
}: {
  curStartIndex: number;
  curEndIndex: number;
  htmlString: string;
}): [number, number] {
  let surroundingStart = curStartIndex;
  let startLevel = 0;
  // If we ever enter new functions or scopes we continue until they are done and we
  // are one level lower than we are at the moment
  while (
    !(
      startLevel === -1 &&
      // And also ensure we include the function definition, so this function
      // currently doesn't support arrow functions
      htmlString.substr(surroundingStart, "function".length) === "function"
    )
  ) {
    // An opening brace is actually going out a scope because we are going backwards
    if (htmlString[surroundingStart] === "{") startLevel--;
    if (htmlString[surroundingStart] === "}") startLevel++;
    surroundingStart--;
  }

  let surroundingEnd = curEndIndex;
  let endLevel = 0;
  while (endLevel !== -1) {
    // We use -1 as by convention the endIndex is one after the last element it includes
    if (htmlString[surroundingEnd - 1] === "{") endLevel++;
    if (htmlString[surroundingEnd - 1] === "}") endLevel--;
    if (endLevel !== -1) surroundingEnd++;
  }
  return [surroundingStart, surroundingEnd];
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
  let finalResult: RegExpExecArray;
  try {
    finalResult = ensureSingletonListAndExtract(candidates);
  } catch (e) {
    if (!(e instanceof Error)) {
      throw e;
    }
    e.message =
      "Our regular expression for patching elm to be able to programatically modify state found a wrong amount of candidates it seems. " +
      "This should not happen, maybe the elm version or our minifying setup changed?\n" +
      e.message +
      "\n\nFor debugging purposes here is the whole htmlString:\n\n" +
      htmlString;
    throw e;
  }

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

function addListenersToAnyModelAssignments({
  modelVariableName,
  htmlString,
  onlyReplaceFirst = false,
}: {
  modelVariableName: string;
  htmlString: string;
  onlyReplaceFirst?: boolean;
}): string {
  const regex = buildRegex(
    [
      // CAPTURE NUMBER 1:
      // Start capture of first part of assignment of model
      "(",
      // Include wordbreaks to make sure we aren't matching other variables
      // that include this variable name as a substring
      String.raw`\b${modelVariableName}\b`,
      // Match the assignment operator and any whitespace on either side
      /\s*=\s*/,
      // End capture number 1
      ")",
      // CAPTURE NUMBER 2:
      // Capture the value being assigned to the model including any `.`s
      // as we also want property accesses to be included
      /([\w.]+)/,
    ],
    onlyReplaceFirst ? "" : "g"
  );
  return htmlString.replace(
    regex,
    [
      // Retain the assignment of the model variable
      "$1",
      // Start parentheses as we are going to be using the comma operator
      // to neatly add a second effect here.
      "(",
      // As the model is being assigned we want to keep track of this in our
      // cache too, so we add this effect
      "window.END_TO_END_TEST_HELPERS.internal.setModel($2)",
      // Comma operator
      // See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Comma_Operator
      ",",
      // Return the value to set, which will then be assigned to the model
      "$2",
      // End parentheses as we are done with our comma operator
      ")",
    ].join("")
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

function buildRegex(regexParts: (RegExp | string)[], flags = ""): RegExp {
  return new RegExp(
    regexParts
      .map((x) => {
        if (typeof x === "string") {
          return x;
        }
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

function ensureSingletonListAndExtract<T>(list: T[]): T {
  const finalResult = list[0];
  if (finalResult === undefined || list.length !== 1) {
    throw new Error(
      "The list was expected to contain exactly one element. The list being checked was: " +
        JSON.stringify(list)
    );
  }
  return finalResult;
}

function applyGlobalRegex(regex: RegExp, string: string): RegExpExecArray[] {
  const candidates: RegExpExecArray[] = [];
  let result = regex.exec(string);
  while (result) {
    candidates.push(result);
    result = regex.exec(string);
  }
  return candidates;
}
