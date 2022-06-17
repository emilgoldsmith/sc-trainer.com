import { canvasOrThrow, isCanvasBlank } from "./html-helpers";

type TestType = "error-message" | "cube";

type ElementMeta = {
  optional: boolean;
  testType?: TestType;
};

type ElementSpecifier = string | { meta: ElementMeta; testId: string | null };

export type OurElement = {
  get: ReturnType<typeof buildGetter>;
  waitFor: ReturnType<typeof buildWaiter>;
  assertShows: ReturnType<typeof buildVisibleAsserter>;
  assertDoesntExist: ReturnType<typeof buildNotExistAsserter>;
  assertContainedByWindow: ReturnType<typeof buildContainedByWindowAsserter>;
  assertConsumableViaVerticalScroll: ReturnType<
    typeof buildConsumableViaVerticalScrollAsserter
  >;
  assertConsumableViaHorizontalScroll: ReturnType<
    typeof buildConsumableViaHorizontalScrollAsserter
  >;
  isContainedByWindow: ReturnType<typeof buildContainedByWindow>;
  assertIsFocused: ReturnType<typeof buildAssertIsFocused>;
  getStringRepresentationOfCube: ReturnType<
    typeof buildGetStringRepresentationOfCube
  >;
  specifier: ElementSpecifier;
};

type InternalElement = OurElement & { meta: ElementMeta };

type Options = {
  log?: boolean;
  withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
};

function getTestId(specifier: ElementSpecifier): string | null {
  if (typeof specifier === "object") {
    return specifier.testId;
  }
  return specifier;
}

function getMeta(specifier: ElementSpecifier): ElementMeta {
  if (typeof specifier === "object") {
    return specifier.meta;
  }
  return { optional: false };
}

function getFullSpecifier(
  specifier: ElementSpecifier
): { meta: ElementMeta; testId: string | null } {
  if (typeof specifier === "string") {
    return {
      meta: { optional: false },
      testId: specifier,
    };
  }
  return specifier;
}
export function optionalElement(specifier: ElementSpecifier): ElementSpecifier {
  const fullSpecifier = getFullSpecifier(specifier);
  return { ...fullSpecifier, meta: { ...fullSpecifier.meta, optional: true } };
}

export function cubeElement(specifier: ElementSpecifier): ElementSpecifier {
  const fullSpecifier = getFullSpecifier(specifier);
  return {
    ...fullSpecifier,
    meta: { ...fullSpecifier.meta, testType: "cube" },
  };
}

export function errorMessageElement(
  specifier: ElementSpecifier
): ElementSpecifier {
  const fullSpecifier = getFullSpecifier(specifier);
  return {
    ...fullSpecifier,
    meta: { ...fullSpecifier.meta, testType: "error-message" },
  };
}

export function anyErrorMessage(): ElementSpecifier {
  return { meta: { optional: false, testType: "error-message" }, testId: null };
}

export function buildElementsCategory<keys extends string>(
  specifiers: { container: ElementSpecifier } & {
    [key in keys]: ElementSpecifier;
  }
): {
  container: OurElement;
  assertAllShow: () => void;
  assertAllConsumableViaVerticalScroll: (
    scrollableContainerSpecifier: ElementSpecifier
  ) => void;
} & {
  [key in keys]: OurElement;
} {
  const getContainer = buildGetter(specifiers.container);
  function buildWithinContainer<T>(
    builder: (
      specifier: ElementSpecifier
    ) => (options?: Options) => Cypress.Chainable<T>,
    specifier: ElementSpecifier
  ): (options?: Options) => Cypress.Chainable<T> {
    const fn = builder(specifier);
    return function (...args: Parameters<ReturnType<typeof buildGetter>>) {
      return getContainer({ log: false }).then((containerElement) => {
        let options = { ...args[0] };
        if (!options) {
          options = { withinSubject: containerElement };
        } else if (options.withinSubject === undefined) {
          options.withinSubject = containerElement;
        }
        return fn(options);
      });
    };
  }
  function buildWithinContainer2<T>(
    builder: (
      specifier: ElementSpecifier
    ) => (
      scrollableContainerSpecifier: ElementSpecifier,
      options?: Options
    ) => Cypress.Chainable<T>,
    specifier: ElementSpecifier
  ): (
    scrollableContainerSpecifier: ElementSpecifier,
    options?: Options
  ) => Cypress.Chainable<T> {
    const fn = builder(specifier);
    return function (
      ...args: Parameters<
        ReturnType<typeof buildConsumableViaVerticalScrollAsserter>
      >
    ) {
      return getContainer({ log: false }).then((containerElement) => {
        let options = { ...args[1] };
        if (!options) {
          options = { withinSubject: containerElement };
        } else if (options.withinSubject === undefined) {
          options.withinSubject = containerElement;
        }
        return fn(args[0], options);
      });
    };
  }

  const elements = Cypress._.mapValues(
    specifiers,
    (specifier: ElementSpecifier, key: string): InternalElement => {
      if (key === "container") {
        return buildElement(specifier);
      }
      return {
        get: buildWithinContainer(buildGetter, specifier),
        waitFor: buildWithinContainer(buildWaiter, specifier),
        assertShows: buildWithinContainer(buildVisibleAsserter, specifier),
        assertDoesntExist: buildWithinContainer(
          buildNotExistAsserter,
          specifier
        ),
        assertContainedByWindow: buildWithinContainer(
          buildContainedByWindowAsserter,
          specifier
        ),
        assertConsumableViaVerticalScroll: buildWithinContainer2(
          buildConsumableViaVerticalScrollAsserter,
          specifier
        ),
        assertConsumableViaHorizontalScroll: buildWithinContainer2(
          buildConsumableViaHorizontalScrollAsserter,
          specifier
        ),
        isContainedByWindow: buildWithinContainer(
          buildContainedByWindow,
          specifier
        ),
        assertIsFocused: buildWithinContainer(buildAssertIsFocused, specifier),
        getStringRepresentationOfCube: buildWithinContainer(
          buildGetStringRepresentationOfCube,
          specifier
        ),
        specifier,
        meta: getMeta(specifier),
      };
    }
  );

  return {
    ...elements,
    assertAllShow() {
      Cypress._.forEach(
        elements,
        (elem) => elem.meta.optional === false && elem.assertShows()
      );
    },
    assertAllConsumableViaVerticalScroll(
      scrollableContainerSpecifier: ElementSpecifier
    ) {
      Cypress._.forEach(
        elements,
        (elem) =>
          elem.meta.optional === false &&
          elem.assertConsumableViaVerticalScroll(scrollableContainerSpecifier)
      );
    },
  };
}

export function buildGlobalsCategory<keys extends string>(
  specifiers: {
    [key in keys]: ElementSpecifier;
  }
): {
  [key in keys]: OurElement;
} {
  return Cypress._.mapValues(specifiers, buildElement);
}

export function buildRootCategory<
  StateValues extends Record<string, string>
>(statesAndId: {
  testId: ElementSpecifier;
  stateAttributeValues: StateValues;
}): {
  getStateAttributeValue: (
    options?: Options
  ) => Cypress.Chainable<StateValues[keyof StateValues]>;
  waitForStateChangeAwayFrom: (
    stateValue: StateValues[keyof StateValues],
    options?: Options
  ) => void;
  stateAttributeValues: StateValues;
} {
  const { testId, stateAttributeValues } = statesAndId;
  const stateAttributeName = "__test-helper__state";
  function getStateAttributeValue(
    options?: Options
  ): Cypress.Chainable<StateValues[keyof StateValues]> {
    return getBySpecifier(testId, options).invoke("attr", stateAttributeName);
  }
  return {
    getStateAttributeValue,
    waitForStateChangeAwayFrom(
      stateValue: StateValues[keyof StateValues],
      options?: Options
    ) {
      getStateAttributeValue(options).should("not.equal", stateValue);
    },
    stateAttributeValues,
  };
}

function buildElement(specifier: ElementSpecifier): InternalElement {
  return {
    get: buildGetter(specifier),
    waitFor: buildWaiter(specifier),
    assertShows: buildVisibleAsserter(specifier),
    assertDoesntExist: buildNotExistAsserter(specifier),
    assertContainedByWindow: buildContainedByWindowAsserter(specifier),
    assertConsumableViaVerticalScroll: buildConsumableViaVerticalScrollAsserter(
      specifier
    ),
    assertConsumableViaHorizontalScroll: buildConsumableViaHorizontalScrollAsserter(
      specifier
    ),
    isContainedByWindow: buildContainedByWindow(specifier),
    assertIsFocused: buildAssertIsFocused(specifier),
    getStringRepresentationOfCube: buildGetStringRepresentationOfCube(
      specifier
    ),
    specifier,
    meta: getMeta(specifier),
  };
}

function getBySpecifier(specifier: ElementSpecifier, options?: Options) {
  const testType = getMeta(specifier).testType;
  return cy.getByTestId(
    getTestId(specifier),
    testType !== undefined
      ? {
          ...options,
          testType,
        }
      : options
  );
}

function buildVisibleAsserter(specifier: ElementSpecifier) {
  return function (options?: Options) {
    return getBySpecifier(specifier, options).should("be.visible");
  };
}

function buildNotExistAsserter(specifier: ElementSpecifier) {
  return function (options?: Options) {
    return getBySpecifier(specifier, options).should("not.exist");
  };
}

function buildWaiter(specifier: ElementSpecifier) {
  return function (options?: Options) {
    return getBySpecifier(specifier, options);
  };
}

function buildGetter(specifier: ElementSpecifier) {
  return function (options?: Options) {
    return getBySpecifier(specifier, options);
  };
}

function buildAssertIsFocused(specifier: ElementSpecifier) {
  return function (options?: Options) {
    const assertIsFocused = () =>
      getBySpecifier(specifier, { ...options, log: false })
        .invoke("attr", "id")
        .then((expectedId) => {
          if (expectedId === undefined) {
            throw new Error(
              "Any programatically focused element should always have an id"
            );
          }
          cy.focused({ ...options, log: false })
            .invoke("attr", "id")
            .should("equal", expectedId);
        });

    if (options?.log === false) {
      return assertIsFocused();
    }
    return cy.withOverallNameLogged(
      {
        displayName: "ASSERT FOCUSED",
        message: specifier,
        consoleProps: () => ({ specifier }),
      },
      assertIsFocused
    );
  };
}

function buildGetStringRepresentationOfCube(
  specifier: ElementSpecifier
): (options?: Options) => Cypress.Chainable<string> {
  return function (options?: Options) {
    if (typeof specifier === "string" || specifier.meta.testType !== "cube") {
      throw new Error(
        "You can only call getStringRepresentationOfCube on a cube element"
      );
    }

    // Standardize the size of the canvas so that string representations are comparable
    cy.setCubeSizeOverride(50);
    return getBySpecifier(specifier, options)
      .find("canvas")
      .should((jqueryElement) => {
        expect(
          isCanvasBlank(canvasOrThrow(jqueryElement)),
          "canvas not to be blank"
        ).to.be.false;
      })
      .then((jqueryElement) => {
        const canvasElement: HTMLCanvasElement = canvasOrThrow(jqueryElement);

        const dataUrl = canvasElement.toDataURL();

        cy.setCubeSizeOverride(null);
        return cy.wrap(dataUrl);
      });
  };
}

function buildContainedByWindow(specifier: ElementSpecifier) {
  return function (options?: Options) {
    return getBySpecifier(specifier, options).then((instructionsElement) => {
      const instructionsTop = instructionsElement.offset()?.top;
      if (instructionsTop === undefined) {
        throw new Error("Element has no offset");
      }
      const instructionsBottom =
        instructionsTop + (instructionsElement.height() as number);
      if (instructionsBottom === undefined) {
        throw new Error("Element has no height");
      }
      return cy.window(options).then((window) => {
        const windowTop = 0;
        const windowBottom = Cypress.$(window).height();
        if (windowBottom === undefined) {
          throw new Error("Window has no height");
        }

        return (
          instructionsTop >= windowTop && instructionsBottom <= windowBottom
        );
      });
    });
  };
}

function buildContainedByWindowAsserter(specifier: ElementSpecifier) {
  return function (options?: Options) {
    return getBySpecifier(specifier, options).then((instructionsElement) => {
      const instructionsTop = instructionsElement.offset()?.top;
      if (instructionsTop === undefined) {
        throw new Error("Element has no offset");
      }
      const instructionsBottom =
        instructionsTop + (instructionsElement.height() as number);
      if (instructionsBottom === undefined) {
        throw new Error("Element has no height");
      }
      cy.window(options).should((window) => {
        const windowTop = 0;
        const windowBottom = Cypress.$(window).height();
        if (windowBottom === undefined) {
          throw new Error("Window has no height");
        }
        expect(
          instructionsTop,
          "element shouldn't poke over top of window"
        ).to.be.at.least(windowTop);
        expect(
          instructionsBottom,
          "element shouldn't poke under bottom of window"
        ).to.be.at.most(windowBottom);
      });
    });
  };
}

function buildConsumableViaVerticalScrollAsserter(specifier: ElementSpecifier) {
  return function (
    scrollableContainerSpecifier: ElementSpecifier,
    options?: Options
  ) {
    function getContainer() {
      // We don't want the within here as it's usually used on the container
      // and getting the container within the container fails
      const optionsWithoutWithin = Cypress._.omit(options, "withinSubject");
      return getBySpecifier(scrollableContainerSpecifier, optionsWithoutWithin);
    }

    function getElement() {
      return getBySpecifier(specifier, options);
    }

    return getBySpecifier(specifier, options).then((ourElement) => {
      getContainer().then((container) => {
        if (getHeight(ourElement) <= getHeight(container)) {
          if (
            getTop(ourElement) >= getTop(container) &&
            getBottom(ourElement) <= getBottom(container)
          ) {
            cy.wrap(undefined, { log: false }).should(() => {
              expect(
                getTop(ourElement),
                "element shouldn't overflow over top of container"
              ).to.be.at.least(getTop(container));
              expect(
                getBottom(ourElement),
                "element shouldn't overflow under bottom of container"
              ).to.be.at.most(getBottom(container));
            });
          } else {
            getElement()
              .scrollIntoView()
              .should(() => {
                expect(
                  getTop(ourElement),
                  "element shouldn't overflow over top of container"
                ).to.be.at.least(getTop(container));
                expect(
                  getBottom(ourElement),
                  "element shouldn't overflow under bottom of container"
                ).to.be.at.most(getBottom(container));
              });
          }
        } else {
          getElement().scrollIntoView().should("be.visible");
          getContainer().scrollTo("top");
          cy.wrap(undefined, { log: false }).should(() => {
            expect(getTop(ourElement)).to.be.at.least(getTop(container));
          });
          getContainer().scrollTo("bottom");
          cy.wrap(undefined, { log: false }).should(() => {
            expect(getBottom(ourElement)).to.be.at.most(getBottom(container));
          });
        }
      });
    });
  };
}
function buildConsumableViaHorizontalScrollAsserter(
  specifier: ElementSpecifier
) {
  return function (
    scrollableContainerSpecifier: ElementSpecifier,
    options?: Options
  ) {
    function getContainer() {
      // We don't want the within here as it's usually used on the container
      // and getting the container within the container fails
      const optionsWithoutWithin = Cypress._.omit(options, "withinSubject");
      return getBySpecifier(scrollableContainerSpecifier, optionsWithoutWithin);
    }

    function getElement() {
      return getBySpecifier(specifier, options);
    }

    return getElement().then((ourElement) => {
      getContainer().then((container) => {
        if (getWidth(ourElement) <= getWidth(container)) {
          if (
            getLeft(ourElement) >= getLeft(container) &&
            getRight(ourElement) <= getRight(container)
          ) {
            cy.wrap(undefined, { log: false }).should(() => {
              expect(
                getLeft(ourElement),
                "element shouldn't overflow to the left of container"
              ).to.be.at.least(getLeft(container));
              expect(
                getRight(ourElement),
                "element shouldn't overflow to the right of container"
              ).to.be.at.most(getRight(container));
            });
          } else {
            getElement()
              .scrollIntoView()
              .should(() => {
                expect(
                  getLeft(ourElement),
                  "element shouldn't overflow to the left of container"
                ).to.be.at.least(getLeft(container));
                expect(
                  getRight(ourElement),
                  "element shouldn't overflow to the right of container"
                ).to.be.at.most(getRight(container));
              });
          }
        } else {
          getElement().scrollIntoView().should("be.visible");
          getContainer().scrollTo("top");
          cy.wrap(undefined, { log: false }).should(() => {
            expect(getLeft(ourElement)).to.be.at.least(getLeft(container));
          });
          getContainer().scrollTo("bottom");
          cy.wrap(undefined, { log: false }).should(() => {
            expect(getRight(ourElement)).to.be.at.most(getRight(container));
          });
        }
      });
    });
  };
}
function getTop(elem: JQuery<HTMLElement>) {
  const top = elem.offset()?.top;
  if (top === undefined) {
    throw new Error("Element has no offset");
  }
  return Math.round(top);
}
function getHeight(elem: JQuery<HTMLElement>) {
  const height = elem.outerHeight();
  if (height === undefined) {
    throw new Error("Element has no height");
  }
  return Math.round(height);
}
function getBottom(elem: JQuery<HTMLElement>) {
  return getTop(elem) + getHeight(elem);
}
function getLeft(elem: JQuery<HTMLElement>) {
  const left = elem.offset()?.left;
  if (left === undefined) {
    throw new Error("Element has no offset");
  }
  return Math.round(left);
}
function getWidth(elem: JQuery<HTMLElement>) {
  const width = elem.outerWidth();
  if (width === undefined) {
    throw new Error("Element has no height");
  }
  return Math.round(width);
}
function getRight(elem: JQuery<HTMLElement>) {
  return getLeft(elem) + getWidth(elem);
}
