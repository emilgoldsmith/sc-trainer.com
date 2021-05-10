export function handleHtmlCypressModifications(html: {
  type: "html";
  value: string;
}): string {
  return replaceMany(html.value, [
    {
      key: "HANDLE_ERROR",
      value: handleError.toString(),
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
  const endIndex = html.indexOf(endIdentifier) + endIdentifier.length;
  return html.substring(0, startIndex) + value + html.substring(endIndex);
}
