import { OurElement } from "./elements";

export function assertNonFalsyStringsEqual(
  first: string | undefined | null,
  second: string | undefined | null,
  msg: string
): void {
  if (first === undefined || first === null) {
    throw new Error(
      "First string in `" + msg + "` was " + JSON.stringify(first)
    );
  }
  if (second === undefined || second === null) {
    throw new Error(
      "Second string in `" + msg + "` was " + JSON.stringify(first)
    );
  }
  if (first !== second) {
    console.log(msg);
    console.log("It failed so we are logging the strings here:");
    console.log("First:");
    console.log(first);
    console.log("Second:");
    console.log(second);
  }
  // Don't do a expect().equal as the diff isn't useful anyway
  // and it takes a long time to generate it due to the large strings
  // We just deal with a boolean and a custom message instead
  expect(first === second, msg).to.be.true;
}

export function assertNonFalsyStringsDifferent(
  first: string | undefined | null,
  second: string | undefined | null,
  msg: string
): void {
  if (first === undefined || first === null) {
    throw new Error(
      "First string in `" + msg + "` was " + JSON.stringify(first)
    );
  }
  if (second === undefined || second === null) {
    throw new Error(
      "Second string in `" + msg + "` was " + JSON.stringify(first)
    );
  }
  if (first === second) {
    console.log(msg);
    console.log("It failed so we are logging the strings here:");
    console.log("First:");
    console.log(first);
    console.log("Second:");
    console.log(second);
  }
  // Don't do a expect().equal as the diff isn't useful anyway
  // and it takes a long time to generate it due to the large strings
  // We just deal with a boolean and a custom message instead
  expect(first !== second, msg).to.be.true;
}

export function assertCubeMatchesAlias<
  Aliases extends Record<string, unknown>,
  Key extends keyof Aliases
>(alias: Key, element: OurElement): void {
  return buildCubeAndAliasMatcher<Aliases, Key>(
    assertNonFalsyStringsEqual,
    false
  )(alias, element);
}

export function assertCubeIsDifferentFromAlias<
  Aliases extends Record<string, unknown>,
  Key extends keyof Aliases
>(alias: Key, element: OurElement): void {
  return buildCubeAndAliasMatcher<Aliases, Key>(
    assertNonFalsyStringsDifferent,
    true
  )(alias, element);
}

export function assertCubeMatchesStateString(
  stateString: string,
  element: OurElement
): void {
  element.getStringRepresentationOfCube().then((actualCubeString) => {
    assertNonFalsyStringsEqual(
      actualCubeString,
      stateString,
      "cube string (first) should equal expected cube string (second)"
    );
  });
}

export function assertCubeIsDifferentFromStateString(
  stateString: string,
  element: OurElement
): void {
  element.getStringRepresentationOfCube().then((actualCubeString) => {
    assertNonFalsyStringsDifferent(
      actualCubeString,
      stateString,
      "cube string (first) should not equal expected cube string (second)"
    );
  });
}

function buildCubeAndAliasMatcher<
  Aliases extends Record<string, unknown>,
  Key extends keyof Aliases
>(
  matcher: typeof assertNonFalsyStringsDifferent,
  shouldDiffer: boolean
): (alias: Key, element: OurElement) => void {
  return function (alias, element) {
    cy.getSingleAlias<Aliases, Key>(alias).then((wronglyTypedArg) => {
      if (typeof wronglyTypedArg !== "string") {
        throw new Error(
          "Alias was not a string. Alias name was " + alias.toString()
        );
      }
      const expectedCubeString: string = wronglyTypedArg;
      element.getStringRepresentationOfCube().should((actualCubeString) => {
        matcher(
          actualCubeString,
          expectedCubeString,
          "cube string (first) should " +
            (shouldDiffer ? "not " : "") +
            "equal " +
            alias.toString() +
            " (second) string representation"
        );
      });
    });
  };
}
