import { withGlobal } from "@sinonjs/fake-timers";

let clock: {
  tick: (ms: number) => number;
  setSystemTime: (now: number) => void;
  next: () => void;
} | null = null;

export function getClock(): NonNullable<typeof clock> {
  if (clock === null) {
    throw new Error("Can't call a clock method before you called install");
  }
  return clock;
}
export function installClock(): void {
  cy.window({ log: false }).then((window) => {
    clock = (withGlobal(window).install() as unknown) as NonNullable<
      typeof clock
    >;
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
