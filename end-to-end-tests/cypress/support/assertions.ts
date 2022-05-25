import { Element } from "./elements";

export function assertNonFalsyStringsEqual(
  first: string | undefined | null,
  second: string | undefined | null,
  msg: string
): void {
  if (first === undefined || first === null) {
    expect.fail("First string in `" + msg + "` was " + JSON.stringify(first));
  }
  if (second === undefined || second === null) {
    expect.fail("Second string in `" + msg + "` was " + JSON.stringify(first));
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
    expect.fail("First string in `" + msg + "` was " + JSON.stringify(first));
  }
  if (second === undefined || second === null) {
    expect.fail("Second string in `" + msg + "` was " + JSON.stringify(first));
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
>(alias: Key, element: Element): void {
  element.getStringRepresentationOfCube().should((actualCubeString) => {
    cy.getSingleAlias<Aliases, Key>(alias).then((wronglyTypedArg) => {
      if (typeof wronglyTypedArg !== "string") {
        throw new Error("Alias was not a string. Alias name was " + alias);
      }
      const expectedCubeString: string = wronglyTypedArg;
      assertNonFalsyStringsEqual(
        actualCubeString,
        expectedCubeString,
        "cube string (first) should equal " +
          alias +
          " (second) string representation"
      );
    });
  });
}
