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

import { getCode, getKeyCode, getKeyValue, Key } from "./keys";

const getByTestId: Cypress.Chainable<undefined>["getByTestId"] = (
  testId,
  ...args
) => cy.get(`[data-testid=${testId}]`, ...args);
Cypress.Commands.add("getByTestId", getByTestId);

const pressKey: Cypress.Chainable<undefined>["pressKey"] = function (
  key,
  options
) {
  const event = buildKeyboardEvent(key, false);
  const handleKeyPress = () => {
    cy.document({ log: false })
      .trigger("keydown", { ...event, log: false })
      .trigger("keypress", { ...event, log: false })
      .trigger("keyup", { ...event, log: false });
  };
  if (options?.log === false) {
    handleKeyPress();
    return;
  }
  cy.withOverallNameLogged(
    {
      name: "pressKey",
      displayName: "PRESS KEY",
      message: `'${getKeyValue(key)}' without any dom target`,
      consoleProps: () => ({ event }),
    },
    handleKeyPress
  );
};
Cypress.Commands.add("pressKey", pressKey);

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

const longPressKey: Cypress.Chainable<undefined>["longPressKey"] = function (
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
    remainingTime > 0 && cy.tick(remainingTime, { log: false });
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

const buttonMash: Cypress.Chainable<undefined>["buttonMash"] = (
  keys,
  options
) => {
  if (keys === []) {
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

const longButtonMash: Cypress.Chainable<undefined>["longButtonMash"] = (
  keys,
  options
) => {
  if (keys === []) {
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
    remainingTime > 0 && cy.tick(remainingTime, { log: false });
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

const getCustomWindow: Cypress.Chainable<undefined>["getCustomWindow"] = function (
  options = {}
) {
  const getWindow = () =>
    cy.window(options).then((window) => {
      const customWindow = window as Cypress.CustomWindow;
      if (customWindow.END_TO_END_TEST_HELPERS === undefined) {
        throw new Error(
          "We expected a populated custom window, but didn't find END_TO_END_TEST_HELPERS property"
        );
      }
      return customWindow;
    });
  return getWindow();
  // You can try uncommenting this if we are interested in adding in retries to this command later
  // Seemed to maybe retry forever?
  // const withRetries = () => {
  //   getWindow().then((window) =>
  //     cy.verifyUpcomingAssertions(window, {}, { onRetry: withRetries })
  //   );
  // };
  // return withRetries();
};
Cypress.Commands.add("getCustomWindow", getCustomWindow);

const getApplicationState: Cypress.Chainable<undefined>["getApplicationState"] = function (
  name,
  options
) {
  const handleGettingApplicationState = (
    consolePropsSetter: (props: Cypress.ObjectLike) => void
  ): Cypress.Chainable<Cypress.OurApplicationState> =>
    cy.getCustomWindow({ log: false }).then((window) => {
      const state = window.END_TO_END_TEST_HELPERS.getModel();
      consolePropsSetter({ name, appState: state });
      return state;
    });
  if (options?.log === false) {
    return handleGettingApplicationState(() => void 0);
  }
  return cy.withOverallNameLogged(
    {
      name: "getApplicationState",
      displayName: "GET APPLICATION STATE",
      message: name === undefined ? "current" : `current ${name} state`,
      consoleProps: () => ({ name }),
    },
    handleGettingApplicationState
  );
};
Cypress.Commands.add("getApplicationState", getApplicationState);

const setApplicationState: Cypress.Chainable<undefined>["setApplicationState"] = function (
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

const withOverallNameLogged: Cypress.Chainable<undefined>["withOverallNameLogged"] = function (
  logConfig,
  commandsCallback
) {
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
    }) as typeof callbackReturnValue;
  } else {
    cy.wrap(undefined, { log: false }).then(handleEndOfCommand);
    return callbackReturnValue;
  }
};
Cypress.Commands.add("withOverallNameLogged", withOverallNameLogged);

const waitForDocumentEventListeners: Cypress.Chainable<undefined>["waitForDocumentEventListeners"] = function (
  ...eventNames
): void {
  cy.getCustomWindow({ log: false }).should((window) => {
    const actualEventNames = window.END_TO_END_TEST_HELPERS.getDocumentEventListeners();
    eventNames.forEach((name) => {
      expect(actualEventNames.has(name), `has expected event listener ${name}`)
        .to.be.true;
    });
  });
};
Cypress.Commands.add(
  "waitForDocumentEventListeners",
  waitForDocumentEventListeners
);

const assertNoHorizontalScrollbar: Cypress.Chainable<undefined>["assertNoHorizontalScrollbar"] = function () {
  cy.withOverallNameLogged(
    {
      name: "assertNoHorizontalScrollbar",
      displayName: "ASSERT SCROLLBAR",
      message: `no horizontal allowed`,
    },
    (consolePropsSetter) => {
      cy.document({ log: false }).then((document) =>
        cy.window({ log: false }).should((window) => {
          const windowWidth = Cypress.$(window).width();
          if (windowWidth === undefined)
            throw new Error("Window width is undefined");

          expect(
            Cypress.$(document).width(),
            "document width at most window width"
          ).to.be.at.most(windowWidth);
        })
      );
      // The previous check won't necessarily work for elements with position fixed or absolute
      // this handles those cases. Inspired by https://stackoverflow.com/a/11670559
      cy.window({ log: false }).then((window) => {
        const windowWidth = Cypress.$(window).width();
        if (windowWidth === undefined)
          throw new Error("Window width is undefined");

        cy.get(":not(style,script)").should((allDomNodes) => {
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
        });
      });
    }
  );
};

Cypress.Commands.add(
  "assertNoHorizontalScrollbar",
  assertNoHorizontalScrollbar
);

const assertNoVerticalScrollbar: Cypress.Chainable<undefined>["assertNoVerticalScrollbar"] = function () {
  cy.withOverallNameLogged(
    {
      name: "assertNoVerticalScrollbar",
      displayName: "ASSERT SCROLLBAR",
      message: `no vertical allowed`,
    },
    (consolePropsSetter) => {
      // Initial simple check
      cy.document({ log: false }).then((document) =>
        cy.window({ log: false }).should((window) => {
          const windowHeight = Cypress.$(window).height();
          if (windowHeight === undefined)
            throw new Error("Window height is undefined");
          expect(
            Cypress.$(document).height(),
            "document height at most window height"
          ).to.be.at.most(windowHeight);
        })
      );
      // The previous check won't necessarily work for elements with position fixed or absolute
      // this handles those cases. Inspired by https://stackoverflow.com/a/11670559
      cy.window({ log: false }).then((window) => {
        const windowHeight = Cypress.$(window).height();
        if (windowHeight === undefined)
          throw new Error("Window height is undefined");

        cy.get(":not(style,script)").should((allDomNodes) => {
          const minMax = { top: 0, bottom: 0 };
          const consoleProps = {
            "Furthest Up": allDomNodes.get(0),
            "Furthest Down": allDomNodes.get(0),
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
            if (nodeTop < minMax.top) {
              minMax.top = nodeTop;
              consoleProps["Furthest Up"] = curNode;
            }
            if (nodeBottom > minMax.bottom) {
              minMax.bottom = nodeBottom;
              consoleProps["Furthest Down"] = curNode;
            }
          });
          consolePropsSetter(consoleProps);
          expect(
            minMax.top,
            "furthest up element should be within window"
          ).to.be.at.least(0);
          expect(
            minMax.bottom,
            "furthest down element should be within window"
          ).to.be.at.most(windowHeight);
        });
      });
    }
  );
};

Cypress.Commands.add("assertNoVerticalScrollbar", assertNoVerticalScrollbar);

const touchScreen: Cypress.Chainable<undefined>["touchScreen"] = function (
  position
) {
  cy.withOverallNameLogged(
    {
      name: "touchScreen",
      displayName: "TOUCH",
      message: `on body element`,
      consoleProps: () => ({ event }),
    },
    () => {
      const event: { eventConstructor: "TouchEvent" } & TouchEventInit &
        Partial<Cypress.TriggerOptions> = {
        eventConstructor: "TouchEvent",
      };
      cy.get("body", { log: false })
        .trigger("touchstart", position, { ...event })
        .trigger("touchend", position, { ...event, log: false });
    }
  );
};
Cypress.Commands.add("touchScreen", touchScreen);

const mouseClickScreen: Cypress.Chainable<undefined>["mouseClickScreen"] = function (
  position
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
      cy.get("body", { log: false }).click(position);
    }
  );
};
Cypress.Commands.add("mouseClickScreen", mouseClickScreen);
