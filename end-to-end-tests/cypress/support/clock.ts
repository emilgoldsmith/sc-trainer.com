import { Clock, withGlobal } from "@sinonjs/fake-timers";

let clock: Clock | null = null;

function getClock(): NonNullable<typeof clock> {
  if (clock === null) {
    throw new Error("Can't call a clock method before you called install");
  }
  return clock;
}
export function installClock(): void {
  cy.window({ log: false }).then((window) => {
    clock = withGlobal(window).install();
  });
}
export function tick(ms: number): void {
  cy.wrap(undefined, { log: false }).then(() => getClock().tick(ms));
}

export function setTimeTo(now: number): void {
  cy.wrap(undefined, { log: false }).then(() => {
    const clock = getClock();
    clock.setSystemTime(now);
    clock.next();
  });
}
