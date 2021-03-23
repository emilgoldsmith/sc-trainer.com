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
  selector,
  ...args
) => cy.get(`[data-testid=${selector}]`, ...args);
Cypress.Commands.add("getByTestId", getByTestId);

const pressKey: Cypress.Chainable<undefined>["pressKey"] = function (
  key,
  options
) {
  const event = buildKeyboardEvent(key);
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
  key: Key
): KeyboardEventInit &
  Partial<Cypress.TriggerOptions> & { constructor: typeof KeyboardEvent } {
  return {
    key: getKeyValue(key),
    code: getCode(key),
    keyCode: getKeyCode(key),
    constructor: KeyboardEvent,
  };
}

const longPressKey: Cypress.Chainable<undefined>["longPressKey"] = function (
  key,
  options
) {
  // A somewhat arbitrary number that just is long enough for a very long press
  const LONG_TIME_MS = 3000;
  const KEY_REPEAT_DELAY = 500;
  const KEY_REPEAT_INTERVAL = 35;
  const stringDisplayableKey = "'" + getKeyValue(key) + "'";
  const event = buildKeyboardEvent(key);
  const handleKeyPress = () => {
    cy.document({ log: false })
      .trigger("keydown", { ...event, log: false })
      .trigger("keypress", { ...event, log: false });
    if (options?.log !== false) cy.log(`Pressed down ${stringDisplayableKey}`);
    let previous = 0;
    let current: number;
    for (
      current = KEY_REPEAT_DELAY;
      current < LONG_TIME_MS;
      previous = current, current += KEY_REPEAT_INTERVAL
    ) {
      cy.tick(current - previous);
      cy.document({ log: false })
        .trigger("keydown", { ...event, repeat: true, log: false })
        .trigger("keypress", { ...event, repeat: true, log: false });
    }
    const remainingTime = LONG_TIME_MS - previous;
    remainingTime > 0 && cy.tick(remainingTime);
    cy.document({ log: false }).trigger("keyup", { ...event, log: false });
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
        event,
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
        cy.tick(timeUntilPress);
        curTime += timeUntilPress;
      }
      const event = buildKeyboardEvent(key);
      cy.document({ log: false })
        .trigger("keydown", { ...event, log: false })
        .trigger("keypress", { ...event, log: false });
    });
    const remainingTime = BUTTON_MASH_DURATION - curTime;
    if (remainingTime > 0) {
      cy.tick(remainingTime);
      curTime += remainingTime;
    }
    keys.forEach((key) => {
      const event = buildKeyboardEvent(key);
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
        cy.tick(timeUntilPress);
        curTime += timeUntilPress;
      }
      const event = buildKeyboardEvent(key);
      cy.document({ log: false })
        .trigger("keydown", { ...event, log: false })
        .trigger("keypress", { ...event, log: false });
    });
    const LONG_TIME_MS = 3000;
    const KEY_REPEAT_DELAY = 500;
    const KEY_REPEAT_INTERVAL = 35;
    let previous = 0;
    let current: number;
    for (
      current = KEY_REPEAT_DELAY;
      current < LONG_TIME_MS;
      previous = current, current += KEY_REPEAT_INTERVAL
    ) {
      cy.tick(current - previous);
      keys.forEach((key) => {
        const event = buildKeyboardEvent(key);
        cy.document({ log: false })
          .trigger("keydown", { ...event, repeat: true, log: false })
          .trigger("keypress", { ...event, repeat: true, log: false });
      });
    }
    const remainingTime = LONG_TIME_MS - previous;
    remainingTime > 0 && cy.tick(remainingTime);
    cy.tick(LONG_TIME_MS);
    keys.forEach((key) => {
      const event = buildKeyboardEvent(key);
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
Cypress.Commands.add("longButtonMash", longButtonMash);

const getCustomWindow: Cypress.Chainable<undefined>["getCustomWindow"] = function (
  options = {}
) {
  const getWindow = () =>
    cy.window(options).then((window) => {
      const customWindow = window as Cypress.CustomWindow;
      if (customWindow.END_TO_END_TEST_HELPERS === undefined) {
        throw new Error(
          "Not a populated custom window, doesn't have END_TO_END_TEST_HELPERS property"
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
  cy.getCustomWindow().should((window) => {
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
