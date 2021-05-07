export function handleHtmlCypressModifications(html: string): string {
  return html
    .replace(/false\/\*IS_CYPRESS_TEST\*\//g, "true")
    .replace("() => {}/*HANDLE_ERROR_CYPRESS*/", "x => {throw new Error(x)}");
}
