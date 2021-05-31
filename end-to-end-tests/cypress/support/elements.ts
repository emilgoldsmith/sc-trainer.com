export type Element = {
  get: ReturnType<typeof buildGetter>;
  waitFor: ReturnType<typeof buildWaiter>;
  assertShows: ReturnType<typeof buildAsserter>;
  assertDoesntExist: ReturnType<typeof buildNotExistAsserter>;
  assertContainedByWindow: ReturnType<typeof buildContainedByWindowAsserter>;
  assertConsumableViaScroll: ReturnType<
    typeof buildConsumableViaScrollAsserter
  >;
  isContainedByWindow: ReturnType<typeof buildContainedByWindow>;
  testId: string | string[];
};

export function buildElementsCategory<keys extends string>(
  testIds: { container: string | string[] } & {
    [key in keys]: string | string[];
  }
): {
  container: Element;
  assertAllShow: () => void;
} & {
  [key in keys]: Element;
} {
  const getContainer = buildGetter(testIds.container);
  function buildWithinContainer<T>(
    builder: (
      testId: string | string[]
    ) => (options?: {
      log?: boolean;
      withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
    }) => Cypress.Chainable<T>,
    testId: string | string[]
  ): (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) => Cypress.Chainable<T> {
    const fn = builder(testId);
    return function (...args: Parameters<ReturnType<typeof buildGetter>>) {
      return getContainer({ log: false }).then((containerElement) => {
        let options = args[0];
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
      testId: string | string[]
    ) => (
      scrollableContainerTestId: string | string[],
      options?: {
        log?: boolean;
        withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
      }
    ) => Cypress.Chainable<T>,
    testId: string | string[]
  ): (
    scrollableContainerTestId: string | string[],
    options?: {
      log?: boolean;
      withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
    }
  ) => Cypress.Chainable<T> {
    const fn = builder(testId);
    return function (
      ...args: Parameters<ReturnType<typeof buildConsumableViaScrollAsserter>>
    ) {
      return getContainer({ log: false }).then((containerElement) => {
        let options = args[1];
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
    testIds,
    (testId: string | string[], key: string) => {
      if (key === "container") {
        return buildElement(testId);
      }
      return {
        get: buildWithinContainer(buildGetter, testId),
        waitFor: buildWithinContainer(buildWaiter, testId),
        assertShows: buildWithinContainer(buildAsserter, testId),
        assertDoesntExist: buildWithinContainer(buildNotExistAsserter, testId),
        assertContainedByWindow: buildWithinContainer(
          buildContainedByWindowAsserter,
          testId
        ),
        assertConsumableViaScroll: buildWithinContainer2(
          buildConsumableViaScrollAsserter,
          testId
        ),
        isContainedByWindow: buildWithinContainer(
          buildContainedByWindow,
          testId
        ),
        testId,
      };
    }
  );

  return {
    ...elements,
    assertAllShow() {
      Cypress._.forEach(elements, (elem) => elem.assertShows());
    },
  };
}

export function buildGlobalsCategory<keys extends string>(
  testIds: {
    [key in keys]: string;
  }
): {
  [key in keys]: Element;
} {
  return Cypress._.mapValues(testIds, buildElement);
}

function buildElement(testId: string | string[]): Element {
  return {
    get: buildGetter(testId),
    waitFor: buildWaiter(testId),
    assertShows: buildAsserter(testId),
    assertDoesntExist: buildNotExistAsserter(testId),
    assertContainedByWindow: buildContainedByWindowAsserter(testId),
    assertConsumableViaScroll: buildConsumableViaScrollAsserter(testId),
    isContainedByWindow: buildContainedByWindow(testId),
    testId,
  };
}

function buildAsserter(testId: string | string[]) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return cy.getByTestId(testId, options).should("be.visible");
  };
}

function buildNotExistAsserter(testId: string | string[]) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return cy.getByTestId(testId, options).should("not.exist");
  };
}

function buildWaiter(testId: string | string[]) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return cy.getByTestId(testId, options);
  };
}

function buildGetter(testId: string | string[]) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return cy.getByTestId(testId, options);
  };
}

function buildContainedByWindow(testId: string | string[]) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return cy.getByTestId(testId, options).then((instructionsElement) => {
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

function buildContainedByWindowAsserter(testId: string | string[]) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return cy.getByTestId(testId, options).then((instructionsElement) => {
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

function buildConsumableViaScrollAsserter(testId: string | string[]) {
  return function (
    scrollableContainerTestId: string | string[],
    options?: {
      log?: boolean;
      withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
    }
  ) {
    function getContainer() {
      // We don't want the within here as it's usually used on the container
      // and getting the container within the container fails
      const optionsWithoutWithin = Cypress._.omit(options, "withinSubject");
      return cy.getByTestId(scrollableContainerTestId, optionsWithoutWithin);
    }

    function getElement() {
      return cy.getByTestId(testId, options);
    }

    return cy.getByTestId(testId, options).then((ourElement) => {
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
