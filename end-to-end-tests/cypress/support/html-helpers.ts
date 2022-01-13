export function canvasOrThrow(
  jqueryElement: JQuery<HTMLElement>
): HTMLCanvasElement {
  if (jqueryElement[0]?.tagName !== "CANVAS") {
    throw new Error(
      "Only supported cube elements right now are canvas elements"
    );
  }
  return jqueryElement[0] as HTMLCanvasElement;
}

/** Modified from https://stackoverflow.com/questions/17386707/how-to-check-if-a-canvas-is-blank */
export function isCanvasBlank(canvas: HTMLCanvasElement): boolean {
  const blank = document.createElement("canvas");

  blank.width = canvas.width;
  blank.height = canvas.height;
  blank.style.width = canvas.style.width;
  blank.style.height = canvas.style.height;

  const canvasUrl = canvas.toDataURL();
  const blankUrl = blank.toDataURL();
  // This is 100% a hack but sometimes we get blank canvases that have different PNG
  // representations, and this works. Better solutions very welcome though
  return canvasUrl.length < blankUrl.length * 2;
}
