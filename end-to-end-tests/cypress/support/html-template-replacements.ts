export function handleHtmlCypressModifications(html: {
  type: "html";
  value: string;
}): string {
  return replaceMany(html.value, [
    {
      key: "HANDLE_ERROR",
      value: handleError.toString(),
    },
    {
      key: "CUBE_VIEW_OPTIONS",
      value:
        JSON.stringify({
          useDebugViewForVisualTesting: true,
          extraAlgToApplyToAllCubes: "",
        }) + ",",
    },
  ]);

  function handleError(errorString: string) {
    throw new Error(errorString);
  }
}

function replaceMany(
  html: string,
  replacements: { key: string; value: string }[]
): string {
  return replacements.reduce(
    (currentTemplateState, { key: nextKey, value: nextValue }) =>
      replaceForKey({
        html: currentTemplateState,
        key: nextKey,
        value: nextValue,
      }),
    html
  );
}

function replaceForKey({
  html,
  key,
  value,
}: {
  html: string;
  key: string;
  value: string;
}): string {
  const startIdentifier = `/** CYPRESS_REPLACE_${key}_START **/`;
  const endIdentifier = `/** CYPRESS_REPLACE_${key}_END **/`;
  const startIndex = html.indexOf(startIdentifier);
  if (startIndex === -1) {
    throw new Error(
      "Start identifier " +
        startIdentifier +
        " could not be found\n\nHtml was:\n\n" +
        html
    );
  }
  const endIndex = html.indexOf(endIdentifier) + endIdentifier.length;
  if (endIndex - endIdentifier.length === -1) {
    throw new Error(
      "End identifier " +
        endIdentifier +
        " could not be found\n\nHtml was:\n\n" +
        html
    );
  }
  return html.substring(0, startIndex) + value + html.substring(endIndex);
}
