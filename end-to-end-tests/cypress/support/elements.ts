type TestType = "error-message" | "cube";

type ElementMeta = {
  optional: boolean;
  testType?: TestType;
};

type ElementSpecifier = string | { meta: ElementMeta; testId: string | null };

export type Element = {
  get: ReturnType<typeof buildGetter>;
  waitFor: ReturnType<typeof buildWaiter>;
  assertShows: ReturnType<typeof buildVisibleAsserter>;
  assertDoesntExist: ReturnType<typeof buildNotExistAsserter>;
  assertContainedByWindow: ReturnType<typeof buildContainedByWindowAsserter>;
  assertConsumableViaScroll: ReturnType<
    typeof buildConsumableViaScrollAsserter
  >;
  isContainedByWindow: ReturnType<typeof buildContainedByWindow>;
  assertIsFocused: ReturnType<typeof buildAssertIsFocused>;
  specifier: ElementSpecifier;
};

type InternalElement = Element & { meta: ElementMeta };

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
      meta: { optional: true },
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
  container: Element;
  assertAllShow: () => void;
} & {
  [key in keys]: Element;
} {
  const getContainer = buildGetter(specifiers.container);
  function buildWithinContainer<T>(
    builder: (
      specifier: ElementSpecifier
    ) => (options?: {
      log?: boolean;
      withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
    }) => Cypress.Chainable<T>,
    specifier: ElementSpecifier
  ): (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) => Cypress.Chainable<T> {
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
      options?: {
        log?: boolean;
        withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
      }
    ) => Cypress.Chainable<T>,
    specifier: ElementSpecifier
  ): (
    scrollableContainerSpecifier: ElementSpecifier,
    options?: {
      log?: boolean;
      withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
    }
  ) => Cypress.Chainable<T> {
    const fn = builder(specifier);
    return function (
      ...args: Parameters<ReturnType<typeof buildConsumableViaScrollAsserter>>
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
        assertConsumableViaScroll: buildWithinContainer2(
          buildConsumableViaScrollAsserter,
          specifier
        ),
        isContainedByWindow: buildWithinContainer(
          buildContainedByWindow,
          specifier
        ),
        assertIsFocused: buildWithinContainer(buildAssertIsFocused, specifier),
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
  };
}

export function buildGlobalsCategory<keys extends string>(
  specifiers: {
    [key in keys]: ElementSpecifier;
  }
): {
  [key in keys]: Element;
} {
  return Cypress._.mapValues(specifiers, buildElement);
}

function buildElement(specifier: ElementSpecifier): InternalElement {
  return {
    get: buildGetter(specifier),
    waitFor: buildWaiter(specifier),
    assertShows: buildVisibleAsserter(specifier),
    assertDoesntExist: buildNotExistAsserter(specifier),
    assertContainedByWindow: buildContainedByWindowAsserter(specifier),
    assertConsumableViaScroll: buildConsumableViaScrollAsserter(specifier),
    isContainedByWindow: buildContainedByWindow(specifier),
    assertIsFocused: buildAssertIsFocused(specifier),
    specifier,
    meta: getMeta(specifier),
  };
}

function getSpecifier(
  specifier: ElementSpecifier,
  options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }
) {
  return cy.getByTestId(getTestId(specifier), {
    ...options,
    testType: getMeta(specifier).testType,
  });
}

function buildVisibleAsserter(specifier: ElementSpecifier) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return getSpecifier(specifier, options).should("be.visible");
  };
}

function buildNotExistAsserter(specifier: ElementSpecifier) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return getSpecifier(specifier, options).should("not.exist");
  };
}

function buildWaiter(specifier: ElementSpecifier) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return getSpecifier(specifier, options);
  };
}

function buildGetter(specifier: ElementSpecifier) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return getSpecifier(specifier, options);
  };
}

function buildAssertIsFocused(specifier: ElementSpecifier) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    const assertIsFocused = () =>
      getSpecifier(specifier, { ...options, log: false })
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

function buildContainedByWindow(specifier: ElementSpecifier) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return getSpecifier(specifier, options).then((instructionsElement) => {
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
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return getSpecifier(specifier, options).then((instructionsElement) => {
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

function buildConsumableViaScrollAsserter(specifier: ElementSpecifier) {
  return function (
    scrollableContainerSpecifier: ElementSpecifier,
    options?: {
      log?: boolean;
      withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
    }
  ) {
    function getContainer() {
      // We don't want the within here as it's usually used on the container
      // and getting the container within the container fails
      const optionsWithoutWithin = Cypress._.omit(options, "withinSubject");
      return getSpecifier(scrollableContainerSpecifier, optionsWithoutWithin);
    }

    function getElement() {
      return getSpecifier(specifier, options);
    }

    return getSpecifier(specifier, options).then((ourElement) => {
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
