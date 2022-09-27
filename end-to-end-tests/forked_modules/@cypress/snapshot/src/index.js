"use strict";

const itsName = require("its-name");
const { initStore } = require("snap-shot-store");
const la = require("lazy-ass");
const is = require("check-more-types");
const compare = require("snap-shot-compare");
const path = require("path");

const doDebugLogs = false;

const {
  serializeDomElement,
  serializeReactToHTML,
  identity,
  countSnapshots,
} = require("./utils");

function compareValues({ expected, value }) {
  const noColor = true;
  const json = true;
  return compare({ expected, value, noColor, json });
}

function registerCypressSnapshot() {
  la(is.fn(global.before), "missing global before function");
  la(is.fn(global.after), "missing global after function");
  la(is.object(global.Cypress), "missing Cypress object");

  if (doDebugLogs) console.log("registering @cypress/snapshot");

  let storeSnapshot;
  let snapshotsThatHaventBeenSeenYet;

  // for each full test name, keeps number of snapshots
  // allows using multiple snapshots inside single test
  // without confusing them
  // eslint-disable-next-line immutable/no-let
  let counters = {};

  function getSnapshotIndex(key) {
    if (key in counters) {
      // eslint-disable-next-line immutable/no-mutation
      counters[key] += 1;
    } else {
      // eslint-disable-next-line immutable/no-mutation
      counters[key] = 1;
    }
    return counters[key];
  }

  let relative = Cypress.spec.relative;
  if (Cypress.platform === "win32") {
    relative = relative.replace(/\\/g, path.sep);
  }

  const snapshotFileName = path.join(
    path.dirname(relative),
    "__snapshots__",
    Cypress.spec.name.split(".")[0] + ".snapshot"
  );

  function nameListToName(names) {
    return names.join(" // ");
  }

  function getAllNameLists(store) {
    if (store === null || typeof store !== "object") return [];
    const { __version, ...nonMetaDataStore } = store;
    const ret = [];
    Cypress._.forEach(nonMetaDataStore, (value, key) => {
      const childrenNames = getAllNameLists(value);
      if (childrenNames.length === 0) ret.push([key]);
      else {
        childrenNames.forEach((name) => {
          ret.push([key].concat(name));
        });
      }
    });
    return ret;
  }

  function recursivelyBuildTestTree(currentRoot) {
    const ret = {};
    currentRoot.suites.forEach((suite) => {
      ret[suite.title] = recursivelyBuildTestTree(suite);
    });
    currentRoot.tests.forEach((test) => {
      ret[test.title] = {};
    });
    return ret;
  }

  function buildTestTree(mochaContext) {
    let root = mochaContext.test;
    while (root.parent) root = root.parent;
    return recursivelyBuildTestTree(root);
  }

  function detectIfDotOnlyIsUsed(mochaContext) {
    let root = mochaContext.test;
    while (root.parent) root = root.parent;
    return root.hasOnly();
  }

  function evaluateLoadedSnapShots(js) {
    let store = {};

    if (js !== null) {
      if (doDebugLogs) console.log(js);
      la(is.string(js), "expected JavaScript snapshot source", js);
      if (doDebugLogs) console.log("read snapshots.js file");
      store = eval(js);
      if (doDebugLogs)
        console.log("have %d snapshot(s)", countSnapshots(store));
    }

    storeSnapshot = initStore(store);
    const allNameLists = getAllNameLists(store);
    if (detectIfDotOnlyIsUsed(this)) {
      const testTree = buildTestTree(this);
      snapshotsThatHaventBeenSeenYet = new Set();
      allNameLists.forEach((nameList) => {
        let cur = testTree;
        const isBeingTested = nameList.slice(0, -1).every((name) => {
          // using the fact that undefined is falsy
          return (cur = cur[name]);
        });
        if (isBeingTested)
          snapshotsThatHaventBeenSeenYet.add(nameListToName(nameList));
      });
    } else {
      snapshotsThatHaventBeenSeenYet = new Set(
        allNameLists.map(nameListToName)
      );
    }
  }

  global.before(function loadSnapshots() {
    cy.task("readFileMaybe", snapshotFileName).then(
      evaluateLoadedSnapShots.bind(this)
    );
    // no way to catch an error yet
  });

  function getTestName(test) {
    const names = itsName(test);
    // la(is.strings(names), 'could not get name from current test', test)
    return names;
  }

  function getSnapshotName(test, humanName) {
    const names = getTestName(test);
    const key = names.join(" - ");
    const index = humanName || getSnapshotIndex(key);
    names.push(String(index));
    return names;
  }

  function setSnapshot(name, value, $el) {
    // snapshots were not initialized
    if (!storeSnapshot) {
      throw new Error("Snapshots should have been initialized");
    }

    // show just the last part of the name list (the index)
    const message = Cypress._.last(name);
    if (doDebugLogs) console.log("current snapshot name", name);

    snapshotsThatHaventBeenSeenYet.delete(nameListToName(name));

    const devToolsLog = {
      value,
    };
    if (Cypress.dom.isJquery($el)) {
      // only add DOM elements, otherwise "expected" value is enough
      devToolsLog.$el = $el;
    }

    const options = {
      name: "snapshot",
      message,
      consoleProps: () => devToolsLog,
    };

    if ($el) {
      options.$el = $el;
    }

    const cyRaiser = ({ value, expected }) => {
      const result = compareValues({ expected, value });
      result.orElse((json) => {
        // by deleting property and adding it at the last position
        // we reorder how the object is displayed
        // We want convenient:
        //   - message
        //   - expected
        //   - value
        devToolsLog.message = json.message;
        devToolsLog.expected = expected;
        delete devToolsLog.value;
        devToolsLog.value = value;
        throw new Error(
          `Snapshot changed for snapshot named ${Cypress._.last(
            name
          )}. To update, delete snapshot and rerun test.\n${json.message}`
        );
      });
    };

    Cypress.log(options);
    storeSnapshot({
      value,
      name,
      raiser: cyRaiser,
    });
    snapshotsThatHaventBeenSeenYet.del;
  }

  const pickSerializer = (asJson, value) => {
    if (Cypress.dom.isJquery(value)) {
      return asJson ? serializeDomElement : serializeReactToHTML;
    }
    return identity;
  };

  function snapshot(value, { name, json } = {}) {
    if (doDebugLogs) console.log("human name", name);
    const snapshotName = getSnapshotName(this.test, name);
    const serializer = pickSerializer(json, value);
    const serialized = serializer(value);
    setSnapshot(snapshotName, serialized, value);

    // always just pass value
    return value;
  }

  Cypress.Commands.add("snapshot", { prevSubject: true }, snapshot);

  function suiteHasFailedTests(suite) {
    return (
      suite.tests.some((test) => test.state === "failed") ||
      suite.suites.some(suiteHasFailedTests)
    );
  }

  function detectIfThereAreAlreadyFailedTests(mochaContext) {
    let root = mochaContext.test;
    while (root.parent) root = root.parent;
    return suiteHasFailedTests(root);
  }

  global.after(function checkIfAnySnapshotsAreMissing() {
    // If the test already failed we won't have been able to detect all the snapshots that should've run if there had been no failure
    if (detectIfThereAreAlreadyFailedTests(this)) return;
    if (snapshotsThatHaventBeenSeenYet.size > 0) {
      throw new Error(
        "Missing snapshots:\n" +
          [...snapshotsThatHaventBeenSeenYet.values()].join(",\n\n") +
          ".\n\n\nTo update, delete snapshot and rerun test."
      );
    }
  });

  global.after(function saveSnapshots() {
    const snapshots = storeSnapshot();
    const count = countSnapshots(snapshots);
    if (doDebugLogs) console.log("%d snapshot(s) on finish", count);
    if (doDebugLogs) console.log(snapshots);

    if (count) {
      snapshots.__version = Cypress.version;
      const s = JSON.stringify(snapshots, null, 2);
      const str = `module.exports = ${s}\n`;
      cy.writeFile(snapshotFileName, str, "utf-8", { log: false });
    }
  });

  return snapshot;
}

module.exports = {
  register: registerCypressSnapshot,
};
