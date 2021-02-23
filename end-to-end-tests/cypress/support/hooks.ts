/* eslint-disable mocha/no-top-level-hooks, mocha/no-hooks-for-single-case */

import { interceptAddingElmModelObserversAndModifiers } from "./elm-model-monkey-patching";

beforeEach(interceptAddingElmModelObserversAndModifiers);
