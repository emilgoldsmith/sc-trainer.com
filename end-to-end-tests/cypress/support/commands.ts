// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add("login", (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })

import { isCanvasBlank } from "./html-helpers";
import { getCode, getKeyCode, getKeyValue, Key } from "./keys";
import {
  AUF,
  aufToAlgorithmString,
  parseAUFString,
  parsePLLString,
  PLL,
  pllToPLLLetters,
} from "./pll";
import { register } from "@cypress/snapshot";

register();

type UnwrapChainable<T> = T extends Cypress.Chainable<infer U> ? U : T;

function cyNow<Name extends keyof Cypress.Chainable<unknown>>(
  name: Name,
  ...args: Parameters<Cypress.Chainable<unknown>[Name]>
) {
  const fn:
    | Promise<UnwrapChainable<ReturnType<Cypress.Chainable<unknown>[Name]>>>
    | ((
        subject: unknown
      ) => UnwrapChainable<ReturnType<Cypress.Chainable<unknown>[Name]>>) =
    cy.now(name, ...args);
  if (fn instanceof Promise)
    throw new Error(`${name}Fn is not supposed to be a promise`);
  return fn;
}
/** OVERWRITES */
Cypress.Commands.overwrite("tick", (originalFn, milliseconds, options) => {
  originalFn(milliseconds, options);
  // We need this cy.wait in order to let requestAnimationFrame trigger
  // which we use sometimes in the app, specifically for the timer when the
  // test is running
  // eslint-disable-next-line cypress/no-unnecessary-waiting
  cy.wait(50, { log: false });
  return cy.clock({ log: false });
});

Cypress.Commands.overwrite(
  "visit",
  function (this: Mocha.Context & Cypress.CypressThis, originalFn, ...args) {
    if (this.clock) {
      throw new Error("Elm breaks if visit is called while time is mocked");
    }
    // The return here is very important, see https://github.com/cypress-io/cypress/issues/23108
    return originalFn(...args);
  }
);

/** CUSTOM COMMANDS */

const getByTestId: Cypress.QueryFn<"getByTestId"> = (testId, options) => {
  if (testId === null && options?.testType === undefined) {
    throw new Error(
      "Can't get an element with neither testId or testType specified"
    );
  }
  const getFn = (() => {
    if (options?.testType !== undefined) {
      if (testId === null) {
        return cyNow("get", `[data-test-type=${options.testType}]`, options);
      }
      return cyNow(
        "get",
        `[data-testid=${testId}][data-test-type=${options.testType}]`,
        options
      );
    }
    return cyNow("get", `[data-testid=${testId}]`, options);
  })();
  return () => getFn(undefined);
};
Cypress.Commands.addQuery("getByTestId", getByTestId);

const getAliases: Cypress.CommandFn<"getAliases"> = function <
  Aliases extends Record<string, unknown>
>(this: Aliases & Mocha.Context) {
  /**
   * We are saving the aliases on Mocha Context which is passed around as `this`
   * so that's what we return here
   */
  return cy.wrap(this as Aliases, { log: false });
};
Cypress.Commands.add("getAliases", getAliases);

const getSingleAlias: Cypress.CommandFn<"getSingleAlias"> = function <
  Aliases extends Record<string, unknown>,
  Key extends keyof Aliases
>(alias: Key) {
  return (
    cy
      .getAliases<Aliases>()
      // Sadly it seems the best thing to do here is to just type cast
      // as Typescript isn't liking these complex types
      // It should hopefully work though and it's pretty simple code!
      .then((aliases) => {
        const value = aliases[alias];
        if (value === undefined) {
          throw new Error(
            `Alias ${alias.toString()} was undefined when fetched with getSingleAlias`
          );
        }
        return value;
      }) as Cypress.Chainable<Aliases[Key]>
  );
};
Cypress.Commands.add("getSingleAlias", getSingleAlias);

Cypress.Commands.overwriteQuery("as", () => {
  throw new Error(
    "Do not use this 'cy.as' command. Instead use the custom typed command .setAlias"
  );
});

const setAlias: Cypress.CommandFnWithSubject<"setAlias", unknown> = function (
  this: Record<string, unknown>,
  subject: unknown,
  alias: string
) {
  this[alias] = subject;
};
Cypress.Commands.add("setAlias", { prevSubject: true }, setAlias);

Cypress.Commands.add("setSystemTimeWithLastFrameTicked", (now) => {
  cy.clock().invoke("setSystemTime", now - 60);
  cy.tick(60);
  // We have previously experienced problems with this not going into effect properly
  // so we're experimenting with a wait here
  //
  // eslint-disable-next-line cypress/no-unnecessary-waiting
  cy.wait(0, { log: false });
});

Cypress.Commands.add(
  "pressKey",
  { prevSubject: ["optional", "element"] },
  (subject, key, options) => {
    const event = buildKeyboardEvent(key, false);
    const handleKeyPress = () => {
      (subject ?? cy.document({ log: false }))
        .trigger("keydown", { ...event, log: false })
        .trigger("keypress", { ...event, log: false })
        .trigger("keyup", { ...event, log: false });

      // We need it here as otherwise the event loop doesn't fire
      // properly which makes things such as asserting that a keypress
      // did NOT trigger an event fail as it doesn't wait for the event
      // loop without this.
      // This for example has incorrectly passed when a transition actually
      // was happening, which this fixes:
      // cy.pressKey(keyThatShouldHaveNoEffect);
      // pllTrainerElements.originalPage.assertShows();
      //
      // eslint-disable-next-line cypress/no-unnecessary-waiting
      cy.wait(0, { log: false });
    };
    if (options?.log === false) {
      handleKeyPress();
      return;
    }
    cy.withOverallNameLogged(
      {
        name: "pressKey",
        displayName: "PRESS KEY",
        message: `'${getKeyValue(key)}' ${
          subject ? "with target" : "without any dom target"
        }`,
        consoleProps: () => ({ event, subject }),
      },
      handleKeyPress
    );
  }
);

function buildKeyboardEvent(
  key: Key,
  isRepeated: boolean
): KeyboardEventInit & Partial<Cypress.TriggerOptions> {
  return {
    key: getKeyValue(key),
    code: getCode(key),
    keyCode: getKeyCode(key),
    repeat: isRepeated,
    eventConstructor: "KeyboardEvent",
  };
}

const longPressKey: Cypress.CommandFn<"longPressKey"> = function (
  key,
  options
) {
  // A somewhat arbitrary number that just is long enough for a very long press
  const LONG_TIME_MS = 1500;
  const KEY_REPEAT_DELAY = 500;
  const KEY_REPEAT_INTERVAL = 35;
  const stringDisplayableKey = "'" + getKeyValue(key) + "'";
  const nonRepeatedEvent = buildKeyboardEvent(key, false);
  const repeatedEvent = buildKeyboardEvent(key, true);
  const handleKeyPress = () => {
    cy.document({ log: false })
      .trigger("keydown", { ...nonRepeatedEvent, log: false })
      .trigger("keypress", { ...nonRepeatedEvent, log: false });
    if (options?.log !== false) cy.log(`Pressed down ${stringDisplayableKey}`);
    let previous = 0;
    let current: number;
    for (
      current = KEY_REPEAT_DELAY;
      current < LONG_TIME_MS;
      previous = current, current += KEY_REPEAT_INTERVAL
    ) {
      cy.tick(current - previous, { log: false });
      cy.document({ log: false })
        .trigger("keydown", { ...repeatedEvent, log: false })
        .trigger("keypress", { ...repeatedEvent, log: false });
    }
    const remainingTime = LONG_TIME_MS - previous;
    if (remainingTime > 0) {
      cy.tick(remainingTime, { log: false });
    }
    if (options?.log !== false) cy.log(`${LONG_TIME_MS}ms passed`);
    cy.document({ log: false }).trigger("keyup", {
      ...nonRepeatedEvent,
      log: false,
    });
    if (options?.log !== false) cy.log(`Released ${stringDisplayableKey}`);
  };

  if (options?.log === false) {
    handleKeyPress();
    return;
  }
  cy.withOverallNameLogged(
    {
      name: "longPressKey",
      displayName: "LONG PRESS KEY",
      message: `${stringDisplayableKey} without any dom target`,
      consoleProps: () => ({
        event: nonRepeatedEvent,
        "Key Press Duration In Millisecond": LONG_TIME_MS,
      }),
    },
    handleKeyPress
  );
};
Cypress.Commands.add("longPressKey", longPressKey);

const buttonMash: Cypress.CommandFn<"buttonMash"> = (keys, options) => {
  if (keys.length === 0) {
    throw new Error("You must pass in at least one key to mash");
  }
  const handleButtonMash = () => {
    const BUTTON_MASH_DURATION = 20;
    const numKeys = keys.length;
    let curTime = 0;
    keys.forEach((key, index) => {
      const timeToPress = (index / numKeys) * BUTTON_MASH_DURATION;
      const timeUntilPress = timeToPress - curTime;
      if (timeUntilPress > 0) {
        cy.tick(timeUntilPress, { log: false });
        curTime += timeUntilPress;
      }
      const event = buildKeyboardEvent(key, false);
      cy.document({ log: false })
        .trigger("keydown", { ...event, log: false })
        .trigger("keypress", { ...event, log: false });
    });
    const remainingTime = BUTTON_MASH_DURATION - curTime;
    if (remainingTime > 0) {
      cy.tick(remainingTime, { log: false });
      curTime += remainingTime;
    }
    keys.forEach((key) => {
      const event = buildKeyboardEvent(key, false);
      cy.document({ log: false }).trigger("keyup", { ...event, log: false });
    });
  };
  if (options?.log === false) {
    handleButtonMash();
    return;
  }
  cy.withOverallNameLogged(
    {
      name: "buttonMash",
      displayName: "MASH BUTTONS",
      message: keys.map((key) => "'" + getKeyValue(key) + "'").join(", "),
      consoleProps: () => ({
        keys,
      }),
    },
    handleButtonMash
  );
};
Cypress.Commands.add("buttonMash", buttonMash);

const longButtonMash: Cypress.CommandFn<"longButtonMash"> = (keys, options) => {
  if (keys.length === 0) {
    throw new Error("You must pass in at least one key to mash");
  }
  const handleButtonMash = () => {
    const BUTTON_MASH_DURATION = 20;
    const numKeys = keys.length;
    let curTime = 0;
    keys.forEach((key, index) => {
      const timeToPress = (index / numKeys) * BUTTON_MASH_DURATION;
      const timeUntilPress = timeToPress - curTime;
      if (timeUntilPress > 0) {
        cy.tick(timeUntilPress, { log: false });
        curTime += timeUntilPress;
      }
      const nonRepeatedEvent = buildKeyboardEvent(key, false);
      cy.document({ log: false })
        .trigger("keydown", { ...nonRepeatedEvent, log: false })
        .trigger("keypress", { ...nonRepeatedEvent, log: false });
    });
    if (options?.log !== false) cy.log("All buttons pressed down");
    const LONG_TIME_MS = 1500;
    const KEY_REPEAT_DELAY = 500;
    const KEY_REPEAT_INTERVAL = 35;
    let previous = 0;
    let current: number;
    for (
      current = KEY_REPEAT_DELAY;
      current < LONG_TIME_MS;
      previous = current, current += KEY_REPEAT_INTERVAL
    ) {
      cy.tick(current - previous, { log: false });
      keys.forEach((key) => {
        const repeatedEvent = buildKeyboardEvent(key, true);
        cy.document({ log: false })
          .trigger("keydown", { ...repeatedEvent, log: false })
          .trigger("keypress", { ...repeatedEvent, log: false });
      });
    }
    const remainingTime = LONG_TIME_MS - previous;
    if (remainingTime > 0) {
      cy.tick(remainingTime, { log: false });
    }
    cy.tick(LONG_TIME_MS, { log: false });
    if (options?.log !== false) cy.log(`${LONG_TIME_MS}ms passed`);
    keys.forEach((key) => {
      const nonRepeatedEvent = buildKeyboardEvent(key, false);
      cy.document({ log: false }).trigger("keyup", {
        ...nonRepeatedEvent,
        log: false,
      });
    });
    if (options?.log !== false) cy.log("All keys released");
  };
  if (options?.log === false) {
    handleButtonMash();
    return;
  }
  cy.withOverallNameLogged(
    {
      name: "buttonMash",
      displayName: "MASH BUTTONS",
      message: keys.map((key) => "'" + getKeyValue(key) + "'").join(", "),
      consoleProps: () => ({
        keys,
      }),
    },
    handleButtonMash
  );
};
Cypress.Commands.add("longButtonMash", longButtonMash);

const getCustomWindow: Cypress.QueryFn<"getCustomWindow"> = function (options) {
  const windowFn = cyNow("window", options);
  return () => {
    const window = windowFn(undefined);
    const customWindow = window as Cypress.CustomWindow;
    if (customWindow.END_TO_END_TEST_HELPERS === undefined) {
      throw new Error(
        "We expected a populated custom window, but didn't find END_TO_END_TEST_HELPERS property"
      );
    }
    return customWindow;
  };
};
Cypress.Commands.addQuery("getCustomWindow", getCustomWindow);

const getApplicationState: Cypress.QueryFn<"getApplicationState"> = function (
  name,
  options
) {
  const log = options?.log
    ? Cypress.log({
        name: "getApplicationState",
        displayName: "GET APPLICATION STATE",
        message: name === undefined ? "current" : `current "${name}" state`,
        consoleProps: () => ({ name }),
      })
    : undefined;

  const getCustomWindowFn = cyNow("getCustomWindow", { log: false });

  return () =>
    withOverallNameLoggedForQuery(
      (
        consolePropsSetter: (props: Cypress.ObjectLike) => void
      ): Cypress.OurApplicationState => {
        const window = getCustomWindowFn(undefined);
        const state = window.END_TO_END_TEST_HELPERS.getModel();
        if (state === undefined) {
          throw new Error(
            `${name} state which was attempted gotten was found to be undefined`
          );
        }
        consolePropsSetter({ name, appState: state });
        return state;
      },
      log
    );
};
Cypress.Commands.addQuery("getApplicationState", getApplicationState);

const setApplicationState: Cypress.CommandFn<"setApplicationState"> = function (
  state,
  name,
  options
) {
  if (state === undefined) {
    throw new Error(
      "setApplicationState called with undefined state, which is not allowed"
    );
  }

  const stateDescription = name || "unknown";
  const handleSettingState = () => {
    cy.getCustomWindow({ log: false }).then((window) =>
      window.END_TO_END_TEST_HELPERS.setModel(state)
    );
    // Force us to wait for a render loop as otherwise the update won't
    // necessarily render for commands made right after, and there isn't
    // really anything we can wait for as we don't know the target page
    // eslint-disable-next-line cypress/no-unnecessary-waiting
    cy.wait(0);
  };

  if (options?.log === false) {
    handleSettingState();
  } else {
    cy.withOverallNameLogged(
      {
        name: "setApplicationState",
        displayName: "SET APPLICATION STATE",
        message: `to ${stateDescription} state`,
        consoleProps: () => ({ appState: state, name: stateDescription }),
      },
      handleSettingState
    );
  }
};
Cypress.Commands.add("setApplicationState", setApplicationState);

const withOverallNameLogged: Cypress.CommandFn<"withOverallNameLogged"> =
  function (logConfig, commandsCallback) {
    const log = Cypress.log({
      ...logConfig,
      ...(logConfig.autoEnd === true ? {} : { autoEnd: false }),
    });
    const consolePropsSetter = (consoleProps: Cypress.ObjectLike): void => {
      log.set({ consoleProps: () => consoleProps });
    };
    const handleEndOfCommand = () => {
      log.snapshot("after");
      if (logConfig.autoEnd !== true) {
        log.end();
      }
    };

    log.snapshot("before");
    const callbackReturnValue = commandsCallback(consolePropsSetter);
    if (Cypress.isCy(callbackReturnValue)) {
      return callbackReturnValue.then((returnValue) => {
        handleEndOfCommand();
        return returnValue;
      });
    }
    cy.wrap(undefined, { log: false }).then(handleEndOfCommand);
    return callbackReturnValue;
  };
Cypress.Commands.add("withOverallNameLogged", withOverallNameLogged);

function withOverallNameLoggedForQuery<T>(
  queryCallback: (
    consolePropsSetter: (
      props: ReturnType<Cypress.LogConfig["consoleProps"]>
    ) => void
  ) => T,
  log: Cypress.Log | undefined
) {
  if (log === undefined) return queryCallback(() => undefined);
  const consolePropsSetter = (consoleProps: Cypress.ObjectLike): void => {
    log.set({ consoleProps: () => consoleProps });
  };

  log.snapshot("before");
  const callbackReturnValue = queryCallback(consolePropsSetter);
  log.snapshot("after");
  if (!log.get("autoEnd")) {
    log.end();
  }
  return callbackReturnValue;
}

const waitForDocumentEventListeners: Cypress.QueryFn<"waitForDocumentEventListeners"> =
  function (...eventNames) {
    const getCustomWindowFn = cyNow("getCustomWindow", { log: false });

    return () => {
      const window = getCustomWindowFn(undefined);
      const actualEventNames =
        window.END_TO_END_TEST_HELPERS.getDocumentEventListeners();
      eventNames.forEach((name) => {
        expect(
          actualEventNames.has(name),
          `has expected event listener ${name}`
        ).to.be.true;
      });
    };
  };
Cypress.Commands.addQuery(
  "waitForDocumentEventListeners",
  waitForDocumentEventListeners
);

const assertNoHorizontalScrollbar: Cypress.QueryFn<"assertNoHorizontalScrollbar"> =
  function () {
    const documentFn = cyNow("document", { log: false });
    const windowFn = cyNow("window", { log: false });
    const getAllDomNodesFn = getGetAllDomNodesFn();
    const log = Cypress.log({
      name: "assertNoHorizontalScrollbar",
      displayName: "ASSERT SCROLLBAR",
      message: `no horizontal allowed`,
    });

    return () =>
      withOverallNameLoggedForQuery((consolePropsSetter) => {
        const document = documentFn(undefined);
        const window = windowFn(undefined);
        const windowWidth = Cypress.$(window).width();
        if (windowWidth === undefined)
          throw new Error("Window width is undefined");

        expect(
          Cypress.$(document).width(),
          "document width at most window width"
        ).to.be.at.most(windowWidth);
        // The previous check won't necessarily work for elements with position fixed or absolute
        // this handles those cases. Inspired by https://stackoverflow.com/a/11670559

        const allDomNodes = getAllDomNodesFn(undefined);
        const minMax = { left: 0, right: 0 };
        const consoleProps = {
          "Furthest Left": allDomNodes.get(0),
          "Furthest Right": allDomNodes.get(0),
        };
        allDomNodes.each((_, curNode) => {
          const nodeLeft = Cypress.$(curNode).offset()?.left;
          if (nodeLeft === undefined) {
            throw new Error("node had no offset");
          }
          const nodeWidth = Cypress.$(curNode).width();
          if (nodeWidth === undefined) {
            throw new Error("Node had no width");
          }
          const nodeRight = nodeLeft + nodeWidth;
          if (nodeLeft < minMax.left) {
            minMax.left = nodeLeft;
            consoleProps["Furthest Left"] = curNode;
          }
          if (nodeRight > minMax.right) {
            minMax.right = nodeRight;
            consoleProps["Furthest Right"] = curNode;
          }
          minMax.left = Math.min(minMax.left, nodeLeft);
        });
        consolePropsSetter(consoleProps);
        expect(
          minMax.left,
          "furthest left element should be within window"
        ).to.be.at.least(0);
        expect(
          minMax.right,
          "furthest right element should be within window"
        ).to.be.at.most(windowWidth);
      }, log);
  };

Cypress.Commands.addQuery(
  "assertNoHorizontalScrollbar",
  assertNoHorizontalScrollbar
);

const assertNoVerticalScrollbar: Cypress.QueryFn<"assertNoVerticalScrollbar"> =
  function () {
    const documentFn = cyNow("document", { log: false });
    const windowFn = cyNow("window", { log: false });
    const getAllDomNodesFn = getGetAllDomNodesFn();
    const log = Cypress.log({
      name: "assertNoVerticalScrollbar",
      displayName: "ASSERT SCROLLBAR",
      message: `no vertical allowed`,
    });
    return () =>
      withOverallNameLoggedForQuery((consolePropsSetter) => {
        // Initial simple check
        const document = documentFn(undefined);
        const window = windowFn(undefined);
        const windowHeight = Cypress.$(window).height();
        if (windowHeight === undefined)
          throw new Error("Window height is undefined");
        expect(
          Cypress.$(document).height(),
          "document height at most window height"
        ).to.be.at.most(windowHeight);
        // The previous check won't necessarily work for elements with position fixed or absolute
        // this handles those cases. Inspired by https://stackoverflow.com/a/11670559
        const allDomNodes = getAllDomNodesFn(undefined);
        const { positions, elements } =
          getTopAndBottomElementsFromAllDomNodes(allDomNodes);
        consolePropsSetter({
          "Furthest Up": elements.top,
          "Furthest Down": elements.bottom,
        });
        expect(
          positions.top,
          "furthest up element should be within window"
        ).to.be.at.least(0);
        expect(
          positions.bottom,
          "furthest down element should be within window"
        ).to.be.at.most(windowHeight);
      }, log);
  };

Cypress.Commands.addQuery(
  "assertNoVerticalScrollbar",
  assertNoVerticalScrollbar
);

const assertThereIsVerticalScrollbar: Cypress.QueryFn<"assertThereIsVerticalScrollbar"> =
  function () {
    const documentFn = cyNow("document", { log: false });
    const windowFn = cyNow("window", { log: false });
    const getAllDomNodesFn = getGetAllDomNodesFn();
    const log = Cypress.log({
      name: "assertThereIsVerticalScrollbar",
      displayName: "ASSERT SCROLLBAR",
      message: "vertical required",
    });
    return () =>
      withOverallNameLoggedForQuery((consolePropsSetter) => {
        // Initial simple check
        const document = documentFn(undefined);
        const window = windowFn(undefined);
        const windowHeight = Cypress.$(window).height();
        if (windowHeight === undefined)
          throw new Error("Window height is undefined");
        if (Cypress.$(document).height() ?? -1 > windowHeight) {
          // Document is higher than window so we don't need to do a more thorough check there
          // should be a vertical scrollbar
          return;
        }
        // The previous check won't necessarily work for elements with position fixed or absolute
        // this handles those cases. Inspired by https://stackoverflow.com/a/11670559

        const allDomNodes = getAllDomNodesFn(undefined);
        const { positions, elements } =
          getTopAndBottomElementsFromAllDomNodes(allDomNodes);
        consolePropsSetter({
          "Furthest Up": elements.top,
          "Furthest Down": elements.bottom,
        });
        expect(
          positions.top < 0 || positions.bottom > windowHeight,
          "furthest up element should be above window or furthest down below window"
        ).to.be.true;
      }, log);
  };

Cypress.Commands.addQuery(
  "assertThereIsVerticalScrollbar",
  assertThereIsVerticalScrollbar
);

const touchScreen: Cypress.CommandFn<"touchScreen"> = function (position) {
  cy.withOverallNameLogged(
    {
      name: "touchScreen",
      displayName: "TOUCH",
      message: `on body element`,
      consoleProps: () => ({ event }),
    },
    () => {
      /** Firefox doesn't support TouchEvent, so we have to fall back to MouseEvent in this case */
      const event: {
        eventConstructor: "TouchEvent" | "MouseEvent";
      } & TouchEventInit &
        Partial<Cypress.TriggerOptions> = {
        eventConstructor: "TouchEvent" in window ? "TouchEvent" : "MouseEvent",
      };
      cy.get("body", { log: false })
        .trigger("touchstart", position, { ...event })
        .trigger("touchend", position, { ...event, log: false });
    }
  );
};
Cypress.Commands.add("touchScreen", touchScreen);

const mouseClickScreen: Cypress.CommandFn<"mouseClickScreen"> = function (
  position,
  options
) {
  const event = {
    eventConstructor: "MouseEvent",
  };
  cy.withOverallNameLogged(
    {
      name: "mouseClickScreen",
      displayName: "CLICK",
      message: `on body element`,
      consoleProps: () => ({ event }),
    },
    () => {
      cy.get("body", { log: false }).click(position, options);
    }
  );
};
Cypress.Commands.add("mouseClickScreen", mouseClickScreen);

const percySnapshotWithProperName: Cypress.CommandFn<"percySnapshotWithProperName"> =
  function (name, options) {
    // Wait for all canvases to fully render before snapshotting
    cy.get("canvas").should((elements) => {
      elements.each((_, canvas) => {
        expect(isCanvasBlank(canvas), "canvas not to be blank").to.be.false;
      });
    });
    const width = Cypress.config().viewportWidth;
    const properName = `${name}-${width}`;
    cy.percySnapshot(properName, options);
  };
Cypress.Commands.add(
  "percySnapshotWithProperName",
  percySnapshotWithProperName
);

const getCurrentTestCase: Cypress.CommandFn<"getCurrentTestCase"> =
  function () {
    return cy
      .getCustomWindow({ log: false })
      .then(function (this: Cypress.CypressThis, window) {
        if (this.clock) {
          throw new Error(
            "getCurrentTestCase doesn't work while time is mocked"
          );
        }
        const ports = window.END_TO_END_TEST_HELPERS.getPorts();
        const sendMeCurrentTestCasePort = ports.sendMeCurrentTestCasePort;
        if (!sendMeCurrentTestCasePort)
          throw new Error(
            `sendMeCurrentTestCase port is not exposed for some reason. The port keys are: ${JSON.stringify(
              Object.keys(ports)
            )}`
          );
        const receiveCurrentTestCasePort = ports.receiveCurrentTestCasePort;
        if (!receiveCurrentTestCasePort)
          throw new Error(
            `receiveCurrentTestCase port is not exposed for some reason. The port keys are: ${JSON.stringify(
              Object.keys(ports)
            )}`
          );

        return { sendMeCurrentTestCasePort, receiveCurrentTestCasePort };
      })
      .then(
        ({ sendMeCurrentTestCasePort, receiveCurrentTestCasePort }) =>
          new Cypress.Promise<[AUF, PLL, AUF]>((resolve) => {
            receiveCurrentTestCasePort.subscribe(receiveTestCase);
            sendMeCurrentTestCasePort.send(null);
            function receiveTestCase(testCase: [string, string, string]) {
              receiveCurrentTestCasePort.unsubscribe(receiveTestCase);
              resolve([
                parseAUFString(testCase[0]),
                parsePLLString(testCase[1]),
                parseAUFString(testCase[2]),
              ]);
            }
          })
      );
  };
Cypress.Commands.add("getCurrentTestCase", getCurrentTestCase);

const setCurrentTestCase: Cypress.CommandFn<"setCurrentTestCase"> = function ([
  preAuf,
  pll,
  postAuf,
]) {
  const jsonValue = [
    aufToAlgorithmString[preAuf],
    pllToPLLLetters[pll],
    aufToAlgorithmString[postAuf],
  ];
  cy.withOverallNameLogged(
    { displayName: "SET TEST CASE", message: JSON.stringify(jsonValue) },
    () => {
      cy.getCustomWindow({ log: false }).then((window) => {
        const ports = window.END_TO_END_TEST_HELPERS.getPorts();
        const setCurrentTestCasePort = ports.setCurrentTestCasePort;
        if (!setCurrentTestCasePort)
          throw new Error(
            `setCurrentTestCase port is not exposed for some reason. The port keys are: ${JSON.stringify(
              Object.keys(ports)
            )}`
          );
        setCurrentTestCasePort.send(jsonValue);
      });
      // Force us to wait for a render loop as otherwise the update won't
      // necessarily render for commands made right after, and there isn't
      // really anything we can wait for as it's still the same page, and
      // we don't know which page it is which is what determines what might
      // change on the page
      // eslint-disable-next-line cypress/no-unnecessary-waiting
      cy.wait(0);
    }
  );
};
Cypress.Commands.add("setCurrentTestCase", setCurrentTestCase);

const overrideNextTestCase: Cypress.CommandFn<"overrideNextTestCase"> =
  function ([preAuf, pll, postAuf]) {
    const jsonValue = [
      aufToAlgorithmString[preAuf],
      pllToPLLLetters[pll],
      aufToAlgorithmString[postAuf],
    ];
    cy.withOverallNameLogged(
      {
        displayName: "OVERRIDE NEXT TEST CASE",
        message: JSON.stringify(jsonValue),
      },
      () => {
        cy.getCustomWindow({ log: false }).then((window) => {
          const ports = window.END_TO_END_TEST_HELPERS.getPorts();
          const overrideNextTestCasePort = ports.overrideNextTestCasePort;
          if (!overrideNextTestCasePort)
            throw new Error(
              `overrideNextTestCase port is not exposed for some reason. The port keys are: ${JSON.stringify(
                Object.keys(ports)
              )}`
            );
          overrideNextTestCasePort.send(jsonValue);
        });
      }
    );
  };
Cypress.Commands.add("overrideNextTestCase", overrideNextTestCase);

const setPLLAlgorithm: Cypress.CommandFn<"setPLLAlgorithm"> = function (
  pll,
  algorithm
) {
  const jsonValue = {
    algorithm,
    pll: pllToPLLLetters[pll],
  };
  cy.withOverallNameLogged(
    {
      displayName: "SET PLL ALGORITHM",
      message: JSON.stringify(jsonValue),
    },
    () => {
      cy.getCustomWindow({ log: false }).then((window) => {
        const ports = window.END_TO_END_TEST_HELPERS.getPorts();
        const setPLLAlgorithmPort = ports.setPLLAlgorithmPort;
        if (!setPLLAlgorithmPort)
          throw new Error(
            `setPLLAlgorithm port is not exposed for some reason. The port keys are: ${JSON.stringify(
              Object.keys(ports)
            )}`
          );
        setPLLAlgorithmPort.send(jsonValue);
        // Release control of the thread to let the render loop do it's thing
        // eslint-disable-next-line cypress/no-unnecessary-waiting
        cy.wait(0);
      });
    }
  );
};
Cypress.Commands.add("setPLLAlgorithm", setPLLAlgorithm);

const setMultiplePLLAlgorithms: Cypress.CommandFn<"setMultiplePLLAlgorithms"> =
  function (toSet) {
    const jsonValue = Cypress._.mapKeys(
      toSet,
      (_, key) => pllToPLLLetters[key as unknown as PLL]
    );
    cy.withOverallNameLogged(
      {
        displayName: "SET MULTIPLE PLL ALGORITHMS",
        message: JSON.stringify(jsonValue),
      },
      () => {
        cy.getCustomWindow({ log: false }).then((window) => {
          const ports = window.END_TO_END_TEST_HELPERS.getPorts();
          const setMultiplePLLAlgorithmsPort =
            ports.setMultiplePLLAlgorithmsPort;
          if (!setMultiplePLLAlgorithmsPort)
            throw new Error(
              `setMultiplePLLAlgorithms port is not exposed for some reason. The port keys are: ${JSON.stringify(
                Object.keys(ports)
              )}`
            );
          setMultiplePLLAlgorithmsPort.send(jsonValue);
          // Release control of the thread to let the render loop do it's thing
          // eslint-disable-next-line cypress/no-unnecessary-waiting
          cy.wait(0);
        });
      }
    );
  };
Cypress.Commands.add("setMultiplePLLAlgorithms", setMultiplePLLAlgorithms);

const overrideCubeDisplayAngle: Cypress.CommandFn<"overrideCubeDisplayAngle"> =
  function (displayAngle) {
    cy.withOverallNameLogged(
      { displayName: "OVERRIDE CUBE DISPLAY ANGLE", message: displayAngle },
      () => {
        cy.getCustomWindow({ log: false }).then((window) => {
          const ports = window.END_TO_END_TEST_HELPERS.getPorts();
          const overrideCubeDisplayAnglePort =
            ports.overrideCubeDisplayAnglePort;
          if (!overrideCubeDisplayAnglePort)
            throw new Error(
              "overrideCubeDisplayAngle port is not exposed for some reason"
            );
          overrideCubeDisplayAnglePort.send(displayAngle);
        });
        // Release control of the thread to let the render loop do it's thing
        // eslint-disable-next-line cypress/no-unnecessary-waiting
        cy.wait(0);
        // Wait until canvases are finished re-rendering
        cy.get("canvas").should((elements) => {
          elements.each((_, canvas) => {
            expect(isCanvasBlank(canvas), "canvas not to be blank").to.be.false;
          });
        });
      }
    );
  };
Cypress.Commands.add("overrideCubeDisplayAngle", overrideCubeDisplayAngle);

const overrideDisplayCubeAnnotations: Cypress.CommandFn<"overrideDisplayCubeAnnotations"> =
  function (displayAnnotations) {
    cy.withOverallNameLogged(
      {
        displayName: "OVERRIDE DISPLAY CUBE ANNOTATIONS",
        message: displayAnnotations,
      },
      () => {
        cy.getCustomWindow({ log: false }).then((window) => {
          const ports = window.END_TO_END_TEST_HELPERS.getPorts();
          const overrideDisplayCubeAnnotationsPort =
            ports.overrideDisplayCubeAnnotationsPort;
          if (!overrideDisplayCubeAnnotationsPort)
            throw new Error(
              "overrideDisplayCubeAnnotations port is not exposed for some reason"
            );
          overrideDisplayCubeAnnotationsPort.send(displayAnnotations);
        });
        // Release control of the thread to let the render loop do it's thing
        // eslint-disable-next-line cypress/no-unnecessary-waiting
        cy.wait(0);
        // Wait until canvases are finished re-rendering
        cy.get("canvas").should((elements) => {
          elements.each((_, canvas) => {
            expect(isCanvasBlank(canvas), "canvas not to be blank").to.be.false;
          });
        });
      }
    );
  };
Cypress.Commands.add(
  "overrideDisplayCubeAnnotations",
  overrideDisplayCubeAnnotations
);

const setCubeSizeOverride: Cypress.CommandFn<"setCubeSizeOverride"> = function (
  size
) {
  cy.withOverallNameLogged(
    { displayName: "SET SIZE OVERRIDE", message: JSON.stringify(size) },
    () => {
      cy.getCustomWindow({ log: false }).then((window) => {
        const ports = window.END_TO_END_TEST_HELPERS.getPorts();
        const setCubeSizeOverridePort = ports.setCubeSizeOverridePort;
        if (!setCubeSizeOverridePort)
          throw new Error(
            "setCubeSizeOverride port is not exposed for some reason"
          );
        setCubeSizeOverridePort.send(size);
      });
      // Release control of the thread to let the render loop do it's thing
      // eslint-disable-next-line cypress/no-unnecessary-waiting
      cy.wait(0);
      // Wait until canvases are finished re-rendering
      cy.get("canvas").should((elements) => {
        elements.each((_, canvas) => {
          expect(isCanvasBlank(canvas), "canvas not to be blank").to.be.false;
          if (size !== null) {
            expect(canvas.style.width).to.equal(size.toString() + "px");
            expect(canvas.style.height).to.equal(size.toString() + "px");
          }
        });
      });
    }
  );
};
Cypress.Commands.add("setCubeSizeOverride", setCubeSizeOverride);

const setLocalStorage: Cypress.CommandFn<"setLocalStorage"> = function (
  storageState
) {
  cy.clearLocalStorage().then((ls) => {
    Cypress._.forEach(storageState, (value, key) => {
      ls.setItem(key, JSON.stringify(value));
    });
  });
};
Cypress.Commands.add("setLocalStorage", setLocalStorage);

function getGetAllDomNodesFn() {
  return cyNow("get", ":not(style,script)") as (subject: unknown) => JQuery;
}
function getTopAndBottomElementsFromAllDomNodes(allDomNodes: JQuery) {
  const positions = { top: 0, bottom: 0 };
  const elements = {
    top: allDomNodes.get(0),
    bottom: allDomNodes.get(0),
  };
  allDomNodes.each((_, curNode) => {
    const nodeTop = Cypress.$(curNode).offset()?.top;
    if (nodeTop === undefined) {
      throw new Error("node had no offset");
    }
    const nodeHeight = Cypress.$(curNode).height();
    if (nodeHeight === undefined) {
      throw new Error("Node had no height");
    }
    const nodeBottom = nodeTop + nodeHeight;
    if (nodeTop < positions.top) {
      positions.top = nodeTop;
      elements.top = curNode;
    }
    if (nodeBottom > positions.bottom) {
      positions.bottom = nodeBottom;
      elements.bottom = curNode;
    }
  });
  return { elements, positions };
}
