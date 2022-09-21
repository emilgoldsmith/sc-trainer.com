import {
  assertCubeIsDifferentFromAlias,
  assertCubeMatchesAlias,
  assertCubeMatchesStateString,
  assertNonFalsyStringsDifferent,
  assertNonFalsyStringsEqual,
} from "support/assertions";
import { OurElement } from "support/elements";
import { applyDefaultIntercepts } from "support/interceptors";
import { getKeyValue, Key } from "support/keys";
import { paths } from "support/paths";
import fullyPopulatedLocalStorage from "fixtures/local-storage/fully-populated.json";
import allPLLsPickedLocalStorage from "fixtures/local-storage/all-plls-picked.json";
import {
  allAUFs,
  AUF,
  aufToAlgorithmString,
  PLL,
  pllToAlgorithmString,
  pllToPllLetters,
} from "support/pll";
import {
  completePLLTestInMilliseconds,
  evaluateResultIgnoreTransitionsWaitTime,
  getReadyWaitTime,
  pllTrainerElements,
} from "e2e/pll-trainer/elements-and-helper-functions";

describe("PLL Trainer", function () {
  beforeEach(function () {
    applyDefaultIntercepts();
  });

  context("completely new user", function () {
    describe("different paths in the app:", function () {
      it("shows new case for new user -> solved quickly + ending test by touching screen where correct button shows up doesn't press that button -> pick algorithm -> correct with goodjob text (no driller) -> same case again on a different visit, no new case page, doesn't display picker, doesn't display good job text", function () {
        cy.visit(paths.pllTrainer);
        pickTargetParametersPageFirstThingNoSideEffects();
        pickTargetParametersPageNoSideEffectsButScroll();
        pickTargetParametersPageSideEffectsExceptNavigations();
        pickTargetParametersNavigateWithSomeDefaultValues();
        newUserStartPageBeginNavigateVariant1();
        pllTrainerElements.newCasePage.container.assertShows();
        cy.clock();
        newCasePageNavigateVariant1();
        pllTrainerElements.getReadyState.container.waitFor();
        getReadyStateNoSideEffectsButScroll();
        cy.tick(getReadyWaitTime);
        testRunningNavigateVariant1();
        pllTrainerElements.evaluateResult.container.waitFor();
        // We observed touching on mobile over the place where the button is can trigger the click event
        // on the next screen about 120ms after transition. So we just test that clicking 150ms (to be safe) after (with mocked time) doesn't
        // take us on to the "Correct Page"
        cy.tick(150);
        pllTrainerElements.evaluateResult.correctButton
          .get()
          // Force stops it from erroring on disabled button
          .click({ force: true });
        pllTrainerElements.evaluateResult.container.assertShows();
        // Continue with normal navigation
        cy.tick(evaluateResultIgnoreTransitionsWaitTime);
        cy.clock().invoke("restore");
        evaluateResultNavigateCorrectVariant1();
        pickAlgorithmPageFirstThingNoSideEffects();
        pickAlgorithmPageSideEffectsExceptNavigations();
        pickAlgorithmNavigateVariant1();
        pllTrainerElements.correctPage.goodJobText.assertShows();
        correctPageNoSideEffects();

        // Do same case again, but now pick algorithm should not be displayed
        cy.getCurrentTestCase().then((testCase) => {
          cy.visit(paths.pllTrainer);
          cy.overrideNextTestCase(testCase);
          cy.clock();
          newUserStartPageBeginNavigateVariant2();
          // No new case page here
          pllTrainerElements.getReadyState.container.waitFor();
          cy.tick(getReadyWaitTime);
          testRunningNavigateVariant2();
          // This is the same as above with correct button, now just testing it also doesn't
          // react to a fast click on the wrong button
          cy.tick(150);
          pllTrainerElements.evaluateResult.wrongButton
            .get()
            // Force stops it from erroring on disabled button
            .click({ force: true });
          pllTrainerElements.evaluateResult.container.assertShows();
          // Continue with normal navigation
          cy.tick(evaluateResultIgnoreTransitionsWaitTime);
          cy.clock().invoke("restore");
          evaluateResultNavigateCorrectVariant1();
          // No pick algorithm page here
          pllTrainerElements.correctPage.container.assertShows();
          pllTrainerElements.correctPage.goodJobText.assertDoesntExist();
        });
      });

      it("solves new case incorrectly -> goes to pick algorithm -> driller with 'wrong text' and not 'correct text' -> test driller works as expected", function () {
        type Aliases = {
          testCaseCube: string;
          solvedFront: string;
          solvedBack: string;
          evaluateResultFront: string;
          evaluateResultBack: string;
        };
        // Note that the time won't be 500 as we're using a changing clock variant
        // of the test running navigator
        completePLLTestInMilliseconds(500, {
          correct: false,
          wrongType: "nearly there",
          forceTestCase: [AUF.U, PLL.Gb, AUF.UPrime],
          startingState: "doNewVisit",
          endingState: "pickAlgorithmPage",
          startPageCallback: () => {
            newUserStartPageNoSideEffectsButScroll();
            pllTrainerElements.newUserStartPage.cubeStartState
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "solvedFront">("solvedFront");
            cy.overrideCubeDisplayAngle("ubl");
            pllTrainerElements.newUserStartPage.cubeStartState
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "solvedBack">("solvedBack");
            cy.overrideCubeDisplayAngle(null);
          },
          testRunningCallback: () =>
            pllTrainerElements.testRunning.testCase
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "testCaseCube">("testCaseCube"),
          testRunningNavigator: testRunningNavigateChangingClockVariant2,
          evaluateResultWrongNavigator: evaluateResultNavigateWrongVariant2,
        });
        pllTrainerElements.pickAlgorithmPage.container.assertShows();
        cy.getCurrentTestCase().then(([, pll]) => {
          pllTrainerElements.pickAlgorithmPage.algorithmInput
            .get()
            .type(pllToAlgorithmString[pll] + "{enter}", { delay: 0 });
        });
        pllTrainerElements.algorithmDrillerExplanationPage.wrongText.assertShows();
        pllTrainerElements.algorithmDrillerExplanationPage.correctText.assertDoesntExist();
        getVerifiedAliases<Aliases, "testCaseCube">(["testCaseCube"]).then(
          ({ testCaseCube }) =>
            algorithmDrillerExplanationPageNoSideEffectsButScroll({
              testCaseCube,
              // Ensured because we manually did it above, didn't use navigate function
              defaultAlgorithmWasUsed: true,
            })
        );

        algorithmDrillerExplanationPageNavigateVariant1();
        getVerifiedAliases<Aliases, "solvedFront" | "solvedBack">([
          "solvedFront",
          "solvedBack",
        ]).then(({ solvedFront, solvedBack }) => {
          algorithmDrillerStatusPageRightAfterExplanationPageNoSideEffects({
            solvedFront,
            solvedBack,
            // true because we used "nearly there" wrong type
            expectedCubeStateDidNotEqualSolvedJustBeforeThis: true,
          });
        });

        const time = 1530 as const;
        completePLLTestInMilliseconds(time, {
          correct: true,
          startingState: "algorithmDrillerStatusPage",
          endingState: "algorithmDrillerStatusPage",
          testRunningNavigator: testRunningNavigateVariant3,
          evaluateResultCallback: () => {
            evaluateResultTimeDependantNoSideEffects1({ timeInMs: time });
            pllTrainerElements.evaluateResult.expectedCubeFront
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "evaluateResultFront">("evaluateResultFront");
            pllTrainerElements.evaluateResult.expectedCubeBack
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "evaluateResultBack">("evaluateResultBack");
          },
          evaluateResultCorrectNavigator: evaluateResultNavigateCorrectVariant2,
        });
        getVerifiedAliases<
          Aliases,
          "evaluateResultFront" | "evaluateResultBack"
        >(["evaluateResultFront", "evaluateResultBack"]).then(
          algorithmDrillerStatusPageAfter1SuccessNoSideEffects
        );

        // Note that the time won't be 500 as we're using a changing clock variant
        // of the test running navigator
        completePLLTestInMilliseconds(500, {
          correct: false,
          wrongType: "nearly there",
          startingState: "algorithmDrillerStatusPage",
          endingState: "algorithmDrillerStatusPage",
          testRunningNavigator: testRunningNavigateChangingClockVariant3,
          evaluateResultWrongNavigator: evaluateResultNavigateWrongVariant3,
          algorithmDrillerStatusPageNavigator: algorithmDrillerStatusPageNavigateVariant1,
        });
        algorithmDrillerStatusPageAfter1Success1FailureNoSideEffects();

        // Here we just do another failure to check that doing a slow correct also counts as a failure
        completePLLTestInMilliseconds(10000, {
          correct: true,
          startingState: "algorithmDrillerStatusPage",
          endingState: "algorithmDrillerStatusPage",
        });
        pllTrainerElements.algorithmDrillerStatusPage.correctConsecutiveAttemptsLeft
          .get()
          .should("have.text", "3");

        const time2 = 600 as const;
        completePLLTestInMilliseconds(time2, {
          correct: true,
          startingState: "algorithmDrillerStatusPage",
          endingState: "algorithmDrillerStatusPage",
          testRunningNavigator: testRunningNavigateVariant4,
          evaluateResultCallback: () =>
            evaluateResultTimeDependantNoSideEffects2({ timeInMs: time2 }),
          algorithmDrillerStatusPageNavigator: algorithmDrillerStatusPageNavigateVariant2,
        });
        const time3 = 1030 as const;
        completePLLTestInMilliseconds(time3, {
          correct: true,
          startingState: "algorithmDrillerStatusPage",
          endingState: "algorithmDrillerStatusPage",
          testRunningNavigator: testRunningNavigateVariant5,
          evaluateResultCallback: () =>
            evaluateResultTimeDependantNoSideEffects3({ timeInMs: time3 }),
        });
        algorithmDrillerStatusPageAfter2SuccessesNoSideEffects();
        const time4 = 100 as const;
        completePLLTestInMilliseconds(time4, {
          correct: true,
          startingState: "algorithmDrillerStatusPage",
          endingState: "algorithmDrillerSuccessPage",
          testRunningNavigator: testRunningNavigateVariant6,
          evaluateResultCallback: () =>
            evaluateResultTimeDependantNoSideEffects4({ timeInMs: time4 }),
        });

        algorithmDrillerSuccessPageNoSideEffects();

        // Ensure it navigates away correctly
        cy.getApplicationState().then((applicationState) => {
          algorithmDrillerSuccessPageNavigateVariant1();
          pllTrainerElements.root
            .getStateAttributeValue()
            .should("be.oneOf", [
              pllTrainerElements.root.stateAttributeValues.newCasePage,
              pllTrainerElements.root.stateAttributeValues.getReadyState,
            ]);

          // And test variant 2 as well
          cy.setApplicationState(applicationState);
          pllTrainerElements.algorithmDrillerSuccessPage.container.waitFor();

          algorithmDrillerSuccessPageNavigateVariant2();
          pllTrainerElements.root
            .getStateAttributeValue()
            .should("be.oneOf", [
              pllTrainerElements.root.stateAttributeValues.newCasePage,
              pllTrainerElements.root.stateAttributeValues.getReadyState,
            ]);
        });
      });

      it("always goes to driller and displays new case page for new preAUF, and exactly if it's not none for new postAUF, even when the pll and other AUF combination have been tested before; doesn't go to driller or display new case page for new combination of seen pre and postAUF with seen pll; on a slow correct it shows correct text and not wrong text in driller explanation page", function () {
        const pll = PLL.Gc;
        const firstPreAUF = AUF.U2;
        const firstNotNonePostAUF = AUF.U;
        const differentPreAUF = AUF.UPrime;
        const differentNotNonePostAUF = AUF.U2;
        const time = 110 as const;
        completePLLTestInMilliseconds(time, {
          correct: true,
          startingState: "doNewVisit",
          forceTestCase: [firstPreAUF, pll, firstNotNonePostAUF],
          endingState: "correctPage",
          newCasePageCallback: () =>
            pllTrainerElements.newCasePage.container.assertShows(),
          testRunningNavigator: testRunningNavigateVariant8,
          evaluateResultCallback: () =>
            evaluateResultTimeDependantNoSideEffects5({ timeInMs: time }),
        });
        // We from now on very consciously switch between doing an incorrect test
        // and a slow correct test, in order to ensure this is true for both cases

        // Note that the time won't be 500 as we're using a changing clock variant
        // of the test running navigator
        completePLLTestInMilliseconds(500, {
          correct: false,
          wrongType: "nearly there",
          startingState: "correctPage",
          forceTestCase: [firstPreAUF, pll, differentNotNonePostAUF],
          endingState: "algorithmDrillerExplanationPage",
          correctPageNavigator: correctPageNavigateVariant1,
          newCasePageCallback: () =>
            pllTrainerElements.newCasePage.container.assertShows(),
          testRunningNavigator: testRunningNavigateChangingClockVariant4,
          evaluateResultWrongNavigator: evaluateResultNavigateWrongVariant1,
        });
        // Seen preAUF but new not none postAUF should go to driller
        pllTrainerElements.algorithmDrillerExplanationPage.container.assertShows();

        completePLLTestInMilliseconds(10000, {
          correct: true,
          startingState: "doNewVisit",
          forceTestCase: [differentPreAUF, pll, firstNotNonePostAUF],
          endingState: "algorithmDrillerExplanationPage",
          newCasePageCallback: () =>
            pllTrainerElements.newCasePage.container.assertShows(),
          testRunningNavigator: testRunningNavigateVariant9,
        });
        // new preAUF but seen not none postAUF should go to driller
        pllTrainerElements.algorithmDrillerExplanationPage.container.assertShows();
        // With a slow correct we should show exactly the correct text here
        pllTrainerElements.algorithmDrillerExplanationPage.correctText.assertShows();
        pllTrainerElements.algorithmDrillerExplanationPage.wrongText.assertDoesntExist();

        type Aliases = {
          testCaseFront: string;
          testCaseBack: string;
        };
        // Note that the time won't be 500 as we're using a changing clock variant
        // of the test running navigator
        completePLLTestInMilliseconds(500, {
          correct: false,
          wrongType: "nearly there",
          startingState: "doNewVisit",
          forceTestCase: [firstPreAUF, pll, AUF.none],
          endingState: "wrongPage",
          assertNewCasePageDidntDisplay: true,
          startPageNavigator: recurringUserStartPageNavigateVariant2,
          testRunningCallback: () => {
            pllTrainerElements.testRunning.testCase
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "testCaseFront">("testCaseFront");
            cy.overrideCubeDisplayAngle("ubl");
            pllTrainerElements.testRunning.testCase
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "testCaseBack">("testCaseBack");
            cy.overrideCubeDisplayAngle(null);
          },
          testRunningNavigator: testRunningNavigateChangingClockVariant5,
        });

        // We shouldn't drill if it's a known preAUF and an unknown \"none\" post-AUF this is because
        // that just means not to make a move in the end which shouldn't be considered new,
        // as learning post-AUF recognition has already been done when that preAUF was learned
        pllTrainerElements.wrongPage.container.assertShows();
        // Just run our wrong page assertions here
        getVerifiedAliases<Aliases, "testCaseFront" | "testCaseBack">([
          "testCaseFront",
          "testCaseBack",
        ]).then(({ testCaseFront, testCaseBack }) =>
          wrongPageNoSideEffects({
            nearlyThereTypeOfWrongWasUsed: true,
            testCaseFront,
            testCaseBack,
          })
        );

        const timeInMs = 45296780 as const;
        completePLLTestInMilliseconds(timeInMs, {
          correct: false,
          wrongType: "unrecoverable",
          startingState: "wrongPage",
          forceTestCase: [differentPreAUF, pll, differentNotNonePostAUF],
          endingState: "wrongPage",
          assertNewCasePageDidntDisplay: true,
          wrongPageNavigator: wrongPageNavigateVariant1,
          testRunningNavigator: testRunningNavigateVariant10,
          evaluateResultCallback: () =>
            evaluateResultTimeDependantNoSideEffects7({ timeInMs }),
        });

        // We shouldn't be drilling for known pre and post auf cases even if they haven't been seen
        // in that combination previously
        pllTrainerElements.wrongPage.container.assertShows();

        // Check that it navigates correctly with variant2
        wrongPageNavigateVariant2();
        pllTrainerElements.root
          .getStateAttributeValue()
          .should("be.oneOf", [
            pllTrainerElements.root.stateAttributeValues.newCasePage,
            pllTrainerElements.root.stateAttributeValues.getReadyState,
          ]);
      });

      it("doesn't go to driller or display new case page on what is technically new pre and post aufs if they are equivalent by symmetry to cases that have been learned", function () {
        const time = 120 as const;
        completePLLTestInMilliseconds(time, {
          correct: true,
          startingState: "doNewVisit",
          forceTestCase: [AUF.UPrime, PLL.H, AUF.UPrime],
          endingState: "correctPage",
          testRunningNavigator: testRunningNavigateVariant11,
          evaluateResultCallback: () =>
            evaluateResultTimeDependantNoSideEffects6({ timeInMs: time }),
        });
        completePLLTestInMilliseconds(10000, {
          correct: true,
          startingState: "correctPage",
          forceTestCase: [AUF.none, PLL.H, AUF.U2],
          endingState: "correctPage",
          assertNewCasePageDidntDisplay: true,
          testRunningNavigator: testRunningNavigateVariant12,
          correctPageNavigator: correctPageNavigateVariant2,
        });

        // Should not show a driller as (U', U') is equivalent to (none, U2) for a fully symmetric
        // case such as the H perm
        pllTrainerElements.correctPage.container.assertShows();
      });
    });

    context("Target Parameters and Statistics Displaying:", function () {
      it("displays the new user start page on first visit, and after nearly completed but cancelled test, but displays statistics page after completing a test. It also tests target parameters are persisted within and across sessions", function () {
        const recognitionTime = "3.5";
        const tps = "1.3";

        cy.visit(paths.pllTrainer);
        pllTrainerElements.pickTargetParametersPage.recognitionTimeInput
          .get()
          .type("{selectall}{backspace}" + recognitionTime);
        pllTrainerElements.pickTargetParametersPage.targetTPSInput
          .get()
          .type("{selectall}{backspace}" + tps);
        testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesVariant1(
          { currentValuesAreValid: true }
        );

        assertItsNewUserNotRecurringUserStartPage();

        // Go back to target parameters to assert that it preserves it within a session
        newUserStartPageEditTargetParamsNavigateVariant1();
        pllTrainerElements.pickTargetParametersPage.recognitionTimeInput
          .get()
          .should("have.value", recognitionTime);
        pllTrainerElements.pickTargetParametersPage.targetTPSInput
          .get()
          .should("have.value", tps);
        // Note that the time won't be 500 as we're using a changing clock variant
        // of the test running navigator
        completePLLTestInMilliseconds(500, {
          correct: false,
          wrongType: "unrecoverable",
          startingState: "pickTargetParametersPage",
          endingState: "pickAlgorithmPage",
          testRunningNavigator: testRunningNavigateChangingClockVariant6,
        });

        // We should now be at pick algorithm page and not have recorded the result yet.
        // So when we go for another visit we should see the new user start page again.
        cy.visit(paths.pllTrainer);
        assertItsNewUserNotRecurringUserStartPage();

        // Complete a test
        // Note that the time won't be 500 as we're using a changing clock variant
        // of the test running navigator
        completePLLTestInMilliseconds(500, {
          correct: false,
          wrongType: "unrecoverable",
          startingState: "startPage",
          endingState: "pickAlgorithmPage",
          testRunningNavigator: testRunningNavigateChangingClockVariant7,
        });
        pickAlgorithmNavigateVariant2();

        cy.visit(paths.pllTrainer);
        // As we completed the previous test we should now be at the recurring user's start page.
        assertItsRecurringUserNotNewUserStartPage();

        // Assert that the target parameters are persisted across sessions
        newUserStartPageEditTargetParamsNavigateVariant1();
        pllTrainerElements.pickTargetParametersPage.recognitionTimeInput
          .get()
          .should("have.value", recognitionTime);
        pllTrainerElements.pickTargetParametersPage.targetTPSInput
          .get()
          .should("have.value", tps);
      });
    });
  });

  context("only algorithms picked otherwise new user", function () {
    it("passes pick target parameters page with default values, shows new user start page, and doesn't display algorithm picker for the apps default generated cases whether solve was correct or wrong as in this case algorithms have already been picked", function () {
      cy.setLocalStorage(allPLLsPickedLocalStorage);
      type Aliases = {
        testCaseFront: string;
        testCaseBack: string;
        originalExpectedCubeFront: string;
        originalExpectedCubeBack: string;
        nextExpectedCubeFront: string;
        nextExpectedCubeBack: string;
      };
      // Correct path:
      completePLLTestInMilliseconds(500, {
        correct: true,
        startingState: "doNewVisit",
        pickTargetParametersNavigator: () =>
          testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesVariant2(
            { currentValuesAreValid: true }
          ),
        startPageCallback: assertItsNewUserNotRecurringUserStartPage,
        newCasePageCallback: newCasePageNoSideEffectsButScroll,
        newCasePageNavigator: newCasePageNavigateVariant2,
        testRunningNavigator: testRunningNavigateVariant7,
        evaluateResultCallback: () => {
          pllTrainerElements.evaluateResult.expectedCubeFront
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "originalExpectedCubeFront">(
              "originalExpectedCubeFront"
            );
          pllTrainerElements.evaluateResult.expectedCubeBack
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "originalExpectedCubeBack">(
              "originalExpectedCubeBack"
            );
        },
        endingState: "correctPage",
      });
      pllTrainerElements.correctPage.container.assertShows();

      // Wrong path:
      // Note that the time won't be 500 as we're using a changing clock variant
      // of the test running navigator, and test running assertions with time side effects
      completePLLTestInMilliseconds(500, {
        correct: false,
        wrongType: "unrecoverable",
        startingState: "correctPage",
        endingState: "algorithmDrillerExplanationPage",
        beginningOfTestRunningCallback: () =>
          testRunningWithTimeSideEffects({ timerIsCurrentlyAtZero: true }),
        testRunningNavigator: testRunningNavigateChangingClockVariant1,
        evaluateResultCallback: () => {
          pllTrainerElements.evaluateResult.expectedCubeFront
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "nextExpectedCubeFront">(
              "nextExpectedCubeFront"
            );
          pllTrainerElements.evaluateResult.expectedCubeBack
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "nextExpectedCubeBack">("nextExpectedCubeBack");
        },
        typeOfWrongPageCallback: () => {
          getVerifiedAliases<
            Aliases,
            | "originalExpectedCubeFront"
            | "originalExpectedCubeBack"
            | "nextExpectedCubeFront"
            | "nextExpectedCubeBack"
          >([
            "originalExpectedCubeFront",
            "originalExpectedCubeBack",
            "nextExpectedCubeFront",
            "nextExpectedCubeBack",
          ]).then(typeOfWrongPageNoSideEffects);
        },
      });
      pllTrainerElements.algorithmDrillerExplanationPage.container.assertShows();
      // We just navigate to the status page to test variant 2 of navigation, so if another
      // good place to do this arises we can do it there instead
      algorithmDrillerExplanationPageNavigateVariant2();
      pllTrainerElements.algorithmDrillerStatusPage.container.assertShows();
    });
  });

  context("user who has learned full pll", function () {
    it("shows the recurring user start page displaying all cases attempted, navigates correctly to edit target parameters, and doesn't show new case page on first attempt, it then changes the cube state correctly after choosing type of wrong", function () {
      cy.setLocalStorage(fullyPopulatedLocalStorage);
      type Aliases = {
        solvedFront: string;
        solvedBack: string;
        expectedFront: string;
        expectedBack: string;
      };
      cy.visit(paths.pllTrainer);
      recurringUserStartPageNoSideEffectsButScroll();

      pllTrainerElements.recurringUserStartPage.numCasesTried
        .get()
        .should("include.text", ": 21");
      pllTrainerElements.recurringUserStartPage.numCasesNotYetTried
        .get()
        .should("include.text", ": 0");

      pllTrainerElements.recurringUserStartPage.cubeStartState
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "solvedFront">("solvedFront");
      cy.overrideCubeDisplayAngle("ubl");
      pllTrainerElements.recurringUserStartPage.cubeStartState
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "solvedBack">("solvedBack");
      cy.overrideCubeDisplayAngle(null);

      recurringUserStartPageEditTargetParamsNavigateVariant1();
      pllTrainerElements.pickTargetParametersPage.container.assertShows();
      testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesVariant3(
        { currentValuesAreValid: true }
      );
      // Force test case here to ensure we don't get inverted cases in a row
      cy.overrideNextTestCase([AUF.none, PLL.E, AUF.none]);
      cy.clock();
      recurringUserStartPageNavigateVariant1();
      pllTrainerElements.getReadyState.container.assertShows();
      cy.tick(getReadyWaitTime);
      pllTrainerElements.testRunning.container.waitFor();
      testRunningNavigateVariant12();
      pllTrainerElements.evaluateResult.container.waitFor();
      evaluateResultWhileIgnoringTransitionsNoSideEffects();
      cy.tick(evaluateResultIgnoreTransitionsWaitTime);
      cy.clock().invoke("restore");
      evaluateResultAfterIgnoringTransitionsNoSideEffects();
      evaluateResultNavigateCorrectVariant1();

      // Do another test so that we have a no moves result that is different from solved
      completePLLTestInMilliseconds(500, {
        correct: false,
        // Force test case here to ensure we don't get inverted cases in a row
        forceTestCase: [AUF.none, PLL.Gc, AUF.none],
        wrongType: "unrecoverable",
        startingState: "correctPage",
        endingState: "typeOfWrongPage",
      });
      pllTrainerElements.typeOfWrongPage.container.waitFor();

      cy.getApplicationState().then((typeOfWrongApplicationState) => {
        cy.withOverallNameLogged({ message: "no moves both variants" }, () => {
          pllTrainerElements.typeOfWrongPage.noMoveCubeStateFront
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "expectedFront">("expectedFront");
          pllTrainerElements.typeOfWrongPage.noMoveCubeStateBack
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "expectedBack">("expectedBack");

          typeOfWrongPageNoMovesNavigateVariant1();

          assertCubeMatchesAlias<Aliases, "expectedFront">(
            "expectedFront",
            pllTrainerElements.wrongPage.expectedCubeStateFront
          );
          assertCubeMatchesAlias<Aliases, "expectedBack">(
            "expectedBack",
            pllTrainerElements.wrongPage.expectedCubeStateBack
          );

          // Just a little check that the tests are complex enough and don't have risk
          // of being evergreen
          assertCubeIsDifferentFromAlias<Aliases, "solvedFront">(
            "solvedFront",
            pllTrainerElements.wrongPage.expectedCubeStateFront
          );

          cy.setApplicationState(typeOfWrongApplicationState);

          typeOfWrongPageNoMovesNavigateVariant2();

          assertCubeMatchesAlias<Aliases, "expectedFront">(
            "expectedFront",
            pllTrainerElements.wrongPage.expectedCubeStateFront
          );
          assertCubeMatchesAlias<Aliases, "expectedBack">(
            "expectedBack",
            pllTrainerElements.wrongPage.expectedCubeStateBack
          );
        });

        cy.withOverallNameLogged(
          { message: "nearly there both variants" },
          () => {
            cy.setApplicationState(typeOfWrongApplicationState);
            pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateFront
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "expectedFront">("expectedFront");
            pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateBack
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "expectedBack">("expectedBack");

            typeOfWrongPageNearlyThereNavigateVariant1();

            assertCubeMatchesAlias<Aliases, "expectedFront">(
              "expectedFront",
              pllTrainerElements.wrongPage.expectedCubeStateFront
            );
            assertCubeMatchesAlias<Aliases, "expectedBack">(
              "expectedBack",
              pllTrainerElements.wrongPage.expectedCubeStateBack
            );

            // Just a little check that the tests are complex enough and don't have risk
            // of being evergreen
            assertCubeIsDifferentFromAlias<Aliases, "solvedFront">(
              "solvedFront",
              pllTrainerElements.wrongPage.expectedCubeStateFront
            );

            cy.setApplicationState(typeOfWrongApplicationState);

            typeOfWrongPageNearlyThereNavigateVariant2();

            assertCubeMatchesAlias<Aliases, "expectedFront">(
              "expectedFront",
              pllTrainerElements.wrongPage.expectedCubeStateFront
            );
            assertCubeMatchesAlias<Aliases, "expectedBack">(
              "expectedBack",
              pllTrainerElements.wrongPage.expectedCubeStateBack
            );
          }
        );

        cy.withOverallNameLogged(
          { message: "unrecoverable both variants" },
          () => {
            cy.setApplicationState(typeOfWrongApplicationState);

            typeOfWrongPageUnrecoverableNavigateVariant1();

            assertCubeMatchesAlias<Aliases, "solvedFront">(
              "solvedFront",
              pllTrainerElements.wrongPage.expectedCubeStateFront
            );
            assertCubeMatchesAlias<Aliases, "solvedBack">(
              "solvedBack",
              pllTrainerElements.wrongPage.expectedCubeStateBack
            );

            cy.setApplicationState(typeOfWrongApplicationState);

            typeOfWrongPageUnrecoverableNavigateVariant2();

            assertCubeMatchesAlias<Aliases, "solvedFront">(
              "solvedFront",
              pllTrainerElements.wrongPage.expectedCubeStateFront
            );
            assertCubeMatchesAlias<Aliases, "solvedBack">(
              "solvedBack",
              pllTrainerElements.wrongPage.expectedCubeStateBack
            );
          }
        );
      });
    });
  });

  describe("statistics", function () {
    it("displays the correct averages ordered correctly, and never displays more than 3 worst cases", function () {
      // Taken from the pllToAlgorithmString map
      // We set the algorithms below in the first test to ensure
      // that also the first case we run has the AUFs we expect it to
      const AaAlgorithmLength = 9;
      const HAlgorithmLength = 7;
      const ZAlgorithmLength = 7;
      const GcAlgorithmLength = 11;

      completePLLTestInMilliseconds(1500, {
        // Try with no AUFs
        forceTestCase: [AUF.none, PLL.Aa, AUF.none],
        correct: true,
        startingState: "doNewVisit",
        testRunningNavigator: testRunningNavigateVariant13,
        startPageCallback: () => {
          // Set all the algorithms we will be using so that AUFs
          // are predictable
          cy.setPLLAlgorithm(PLL.Aa, pllToAlgorithmString[PLL.Aa]);
          cy.setPLLAlgorithm(PLL.H, pllToAlgorithmString[PLL.H]);
          cy.setPLLAlgorithm(PLL.Z, pllToAlgorithmString[PLL.Z]);
        },
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            lastThreeResults: [{ timeMs: 1500, turns: AaAlgorithmLength }],
          },
        ],
      });
      completePLLTestInMilliseconds(2000, {
        // Try with a preAUF
        forceTestCase: [AUF.U, PLL.Aa, AUF.none],
        correct: true,
        startingState: "startPage",
        testRunningNavigator: testRunningNavigateVariant14,
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 1500, turns: AaAlgorithmLength },
              // The addition is for the extra AUF turn
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
            ],
          },
        ],
      });
      completePLLTestInMilliseconds(1000, {
        // Try with a postAUF
        forceTestCase: [AUF.none, PLL.Aa, AUF.U2],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 1500, turns: AaAlgorithmLength },
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength + 1 },
            ],
          },
        ],
      });
      // Ensure with a fourth attempt that only the most recent 3 attempts
      // are taken into account
      completePLLTestInMilliseconds(1000, {
        // Try with both AUFs
        forceTestCase: [AUF.UPrime, PLL.Aa, AUF.U],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 1000, turns: AaAlgorithmLength + 1 },
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength + 2 },
            ],
          },
        ],
      });
      completePLLTestInMilliseconds(2000, {
        forceTestCase: [AUF.none, PLL.H, AUF.none],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.H,
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
          },
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 1000, turns: AaAlgorithmLength + 1 },
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength + 2 },
            ],
          },
        ],
      });
      // Test that DNFs work as we want them to
      completePLLTestInMilliseconds(2000, {
        forceTestCase: [AUF.U2, PLL.Aa, AUF.UPrime],
        correct: false,
        wrongType: "nearly there",
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            dnf: true,
          },
          {
            pll: PLL.H,
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
          },
        ],
      });
      completePLLTestInMilliseconds(2000, {
        forceTestCase: [AUF.U2, PLL.Aa, AUF.none],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            dnf: true,
          },
          {
            pll: PLL.H,
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
          },
        ],
      });
      completePLLTestInMilliseconds(1000, {
        forceTestCase: [AUF.none, PLL.Aa, AUF.none],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            dnf: true,
          },
          {
            pll: PLL.H,
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
          },
        ],
      });
      completePLLTestInMilliseconds(3000, {
        forceTestCase: [AUF.U, PLL.Aa, AUF.UPrime],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.H,
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
          },
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
          },
        ],
      });

      /** And here we now test that it correctly calculates statistics for AUFs on symmetric cases */
      /** Note that H-perm is fully symmetrical. Therefore pre-AUF is not a thing, the only
       * difference it makes is changing the post-AUF
       */
      completePLLTestInMilliseconds(2000, {
        // These AUFs actually cancel out and should result in a 0-AUF case
        // and calculated as such
        forceTestCase: [AUF.U, PLL.H, AUF.UPrime],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.H,
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength },
            ],
          },
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
          },
        ],
      });
      completePLLTestInMilliseconds(2000, {
        // These should partially cancel out and just add a single postAUF
        forceTestCase: [AUF.U2, PLL.H, AUF.UPrime],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.H,
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
          },
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
          },
        ],
      });
      completePLLTestInMilliseconds(2000, {
        // This should predictably just add a single turn
        forceTestCase: [AUF.none, PLL.H, AUF.U],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.H,
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
          },
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
          },
        ],
      });
      /**
       * Z is partially symmetrical, having 2 possible preAUFs, either none or a U turn.
       * We just do two tests to see that these partial symmetries seem handled too
       */
      completePLLTestInMilliseconds(5000, {
        forceTestCase: [AUF.none, PLL.Z, AUF.none],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Z,
            lastThreeResults: [{ timeMs: 5000, turns: ZAlgorithmLength }],
          },
          {
            pll: PLL.H,
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
          },
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
          },
        ],
      });
      completePLLTestInMilliseconds(5000, {
        // We check that it can indeed get +2
        forceTestCase: [AUF.U, PLL.Z, AUF.UPrime],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Z,
            lastThreeResults: [
              { timeMs: 5000, turns: ZAlgorithmLength },
              { timeMs: 5000, turns: ZAlgorithmLength + 2 },
            ],
          },
          {
            pll: PLL.H,
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
          },
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
          },
        ],
      });
      completePLLTestInMilliseconds(5000, {
        // We check that a U2 postAUF gets correctly cancelled out
        // as one could then just do U' as the preAUF and it's only +1
        forceTestCase: [AUF.U, PLL.Z, AUF.U2],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Z,
            lastThreeResults: [
              { timeMs: 5000, turns: ZAlgorithmLength },
              { timeMs: 5000, turns: ZAlgorithmLength + 2 },
              { timeMs: 5000, turns: ZAlgorithmLength + 1 },
            ],
          },
          {
            pll: PLL.H,
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
          },
          {
            pll: PLL.Aa,
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
          },
        ],
      });
      /**
       * Finally we check that if a fourth pll is attempted it still only shows
       * the worst 3 cases
       */
      completePLLTestInMilliseconds(10000, {
        forceTestCase: [AUF.U, PLL.Gc, AUF.U2],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Gc,
            lastThreeResults: [{ timeMs: 10000, turns: GcAlgorithmLength + 2 }],
          },
          {
            pll: PLL.Z,
            lastThreeResults: [
              { timeMs: 5000, turns: ZAlgorithmLength },
              { timeMs: 5000, turns: ZAlgorithmLength + 2 },
              { timeMs: 5000, turns: ZAlgorithmLength + 1 },
            ],
          },
          {
            pll: PLL.H,
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
          },
        ],
      });

      function assertCorrectStatistics({
        worstCasesFromWorstToBetter,
      }: {
        worstCasesFromWorstToBetter: (
          | {
              pll: PLL;
              lastThreeResults: { timeMs: number; turns: number }[];
              dnf?: undefined;
            }
          | { pll: PLL; dnf: true }
        )[];
      }): void {
        pllTrainerElements.recurringUserStartPage.worstCaseListItem
          .get()
          .should("have.length", worstCasesFromWorstToBetter.length)
          .and((elements) => {
            elements.each((index, elem) => {
              const text = Cypress.$(elem).text();
              const caseInfo = worstCasesFromWorstToBetter[index];
              if (caseInfo === undefined) {
                throw new Error(
                  "Unexpected wrong index when lengths should be the same"
                );
              }
              if (caseInfo.dnf !== true) {
                const { averageTimeMs, averageTPS } = computeAverages(
                  caseInfo.lastThreeResults
                );
                expect(text)
                  .to.match(
                    new RegExp(
                      "\\b" + pllToPllLetters[caseInfo.pll] + "-perm\\b"
                    )
                  )
                  .and.match(
                    new RegExp(
                      "\\b" + (averageTimeMs / 1000).toFixed(2) + "s\\b"
                    )
                  )
                  .and.match(
                    new RegExp("\\b" + averageTPS.toFixed(2) + "\\s?TPS\\b")
                  );
              } else {
                expect(text).to.equal(
                  pllToPllLetters[caseInfo.pll] + "-perm: DNF"
                );
              }
            });
          });
      }
    });
    it("displays the global statistics correctly", function () {
      // Taken from pllToAlgorithmString
      // We set the algorithms below in the first test to ensure
      // that also the first case we run has the AUFs we expect it to
      const AaAlgorithmLength = 9;
      const GaAlgorithmLength = 11;
      const totalPLLCases = 21;

      completePLLTestInMilliseconds(1000, {
        forceTestCase: [AUF.UPrime, PLL.Aa, AUF.none],
        correct: true,
        startingState: "doNewVisit",
        startPageCallback: () => {
          // Set all the algorithms we will be using so that AUFs
          // are predictable
          cy.setPLLAlgorithm(PLL.Aa, pllToAlgorithmString[PLL.Aa]);
          cy.setPLLAlgorithm(PLL.Ga, pllToAlgorithmString[PLL.Ga]);
        },
      });
      cy.visit(paths.pllTrainer);
      assertCorrectGlobalStatistics({
        numTried: 1,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
        ],
      });

      completePLLTestInMilliseconds(2000, {
        forceTestCase: [AUF.none, PLL.Ab, AUF.none],
        correct: false,
        wrongType: "nearly there",
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      // Still counts a try even though it's incorrect.
      // But doesn't change the global averages
      assertCorrectGlobalStatistics({
        numTried: 2,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
        ],
      });

      completePLLTestInMilliseconds(2000, {
        forceTestCase: [AUF.U, PLL.Ga, AUF.U2],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      // And counts a third one after an incorrect
      // And now changes the global averages
      assertCorrectGlobalStatistics({
        numTried: 3,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
          [{ timeMs: 2000, turns: GaAlgorithmLength + 2 }],
        ],
      });

      completePLLTestInMilliseconds(1000, {
        forceTestCase: [AUF.none, PLL.Ga, AUF.none],
        correct: true,
        startingState: "startPage",
      });
      cy.visit(paths.pllTrainer);
      // And doesn't count a repeat of one we tried before in numTried
      // but does modify one of the averages
      assertCorrectGlobalStatistics({
        numTried: 3,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
          [
            { timeMs: 2000, turns: GaAlgorithmLength + 2 },
            { timeMs: 1000, turns: GaAlgorithmLength },
          ],
        ],
      });

      // Now we make sure that it only counts the last three by going up
      // to 4 tests on Ga
      completePLLTestInMilliseconds(2000, {
        forceTestCase: [AUF.none, PLL.Ga, AUF.U],
        correct: true,
        startingState: "startPage",
        endingState: "correctPage",
      });
      completePLLTestInMilliseconds(3000, {
        forceTestCase: [AUF.UPrime, PLL.Ga, AUF.U2],
        correct: true,
        startingState: "correctPage",
      });
      cy.visit(paths.pllTrainer);
      assertCorrectGlobalStatistics({
        numTried: 3,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
          [
            { timeMs: 1000, turns: GaAlgorithmLength },
            { timeMs: 2000, turns: GaAlgorithmLength + 1 },
            { timeMs: 3000, turns: GaAlgorithmLength + 2 },
          ],
        ],
      });

      function assertCorrectGlobalStatistics({
        numTried,
        casesWithLastThreeCasesValid,
      }: {
        numTried: number;
        casesWithLastThreeCasesValid: { timeMs: number; turns: number }[][];
      }): void {
        const eachCasePrecomputed = casesWithLastThreeCasesValid.map(
          computeAverages
        );
        const globalTimeAverageSeconds =
          average(eachCasePrecomputed.map((x) => x.averageTimeMs)) / 1000;
        const globalTPSAverage = average(
          eachCasePrecomputed.map((x) => x.averageTPS)
        );
        const numNotYetTried = totalPLLCases - numTried;

        pllTrainerElements.recurringUserStartPage.numCasesTried
          .get()
          .should("include.text", ": " + numTried.toString());
        pllTrainerElements.recurringUserStartPage.numCasesNotYetTried
          .get()
          .should("include.text", ": " + numNotYetTried.toString());
        pllTrainerElements.recurringUserStartPage.averageTime
          .get()
          .should(
            "include.text",
            ": " + globalTimeAverageSeconds.toFixed(2) + "s"
          );
        pllTrainerElements.recurringUserStartPage.averageTPS
          .get()
          .should("include.text", ": " + globalTPSAverage.toFixed(2));
      }
    });
    function computeAverages(
      lastThreeResults: { timeMs: number; turns: number }[]
    ): { averageTimeMs: number; averageTPS: number } {
      return {
        averageTimeMs: average(lastThreeResults.map((x) => x.timeMs)),
        averageTPS: average(
          lastThreeResults.map(({ timeMs, turns }) => turns / (timeMs / 1000))
        ),
      };
    }
    function average(l: number[]) {
      return l.reduce((a, b) => a + b) / l.length;
    }

    it("correctly ignores y rotations at beginning and end of algorithm during stats calculations as this can be dealt with through AUFs", function () {
      type Aliases = {
        unmodified: string;
        modified: string;
      };
      cy.visit(paths.pllTrainer);
      const testCase = [AUF.U2, PLL.Aa, AUF.UPrime] as const;
      cy.setPLLAlgorithm(testCase[1], pllToAlgorithmString[testCase[1]]);
      completePLLTestInMilliseconds(1000, {
        startingState: "pickTargetParametersPage",
        forceTestCase: testCase,
        correct: true,
      });

      cy.visit(paths.pllTrainer);
      pllTrainerElements.recurringUserStartPage.worstCaseListItem
        .get()
        .invoke("text")
        .setAlias<Aliases, "unmodified">("unmodified");

      // Reset and try again with modified
      cy.clearLocalStorage();
      cy.visit(paths.pllTrainer);
      cy.setPLLAlgorithm(
        testCase[1],
        "y' " + pllToAlgorithmString[testCase[1]] + " y2"
      );
      completePLLTestInMilliseconds(1000, {
        startingState: "pickTargetParametersPage",
        forceTestCase: testCase,
        correct: true,
      });
      cy.visit(paths.pllTrainer);
      pllTrainerElements.recurringUserStartPage.worstCaseListItem
        .get()
        .invoke("text")
        .setAlias<Aliases, "modified">("modified");

      cy.getAliases<Aliases>().should(({ unmodified, modified }) => {
        assertNonFalsyStringsEqual(
          modified,
          unmodified,
          "modified with y rotations should equal unmodified algorithm"
        );
      });
    });

    it("correctly calculates the TPS of the first attempt on a case, even though we don't know which AUF was used until the algorithm is input", function () {
      assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll: PLL.Ua,
        // Standard slice algorithm
        algorithm: "M2 U M' U2 M U M2",
      });
      assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll: PLL.Ua,
        // An algorithm with a different preAUF but same postAUF
        algorithm: "R2 U' R2 S R2 S' U R2",
      });
      assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll: PLL.Gc,
        // Emil's main Gc algorithm (maybe standard?)
        algorithm: "R2 U' R U' R U R' U R2 D' U R U' R' D",
      });
      assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll: PLL.Gc,
        // An algorithm with a different postAUF but same preAUF
        algorithm: "R2' Uw' R U' R U R' Uw R2 y R U' R' y'",
      });

      function assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll,
        algorithm,
      }: {
        pll: PLL;
        algorithm: string;
      }) {
        type Aliases = {
          cubeBeforeAlgorithmPicked: string;
          statsAfterFirstTest: string;
          cubeAfterAlgorithmPicked: string;
          statsAfterSecondTest: string;
        };
        const testResultTime = 1000;
        const aufOnTheAppsDefaultAlgorithm = [AUF.none, AUF.none] as const;

        cy.clearLocalStorage();
        completePLLTestInMilliseconds(testResultTime, {
          forceTestCase: [
            aufOnTheAppsDefaultAlgorithm[0],
            pll,
            aufOnTheAppsDefaultAlgorithm[1],
          ],
          correct: true,
          overrideDefaultAlgorithm: algorithm,
          startingState: "doNewVisit",
          endingState: "correctPage",
          testRunningCallback: () =>
            pllTrainerElements.testRunning.testCase
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "cubeBeforeAlgorithmPicked">(
                "cubeBeforeAlgorithmPicked"
              ),
        });
        cy.getCurrentTestCase()
          .then(([preAUF, , postAUF]) => {
            const equivalentAUFsForOurAlgorithm: [AUF, AUF] = [preAUF, postAUF];
            completePLLTestInMilliseconds(testResultTime, {
              forceTestCase: [
                equivalentAUFsForOurAlgorithm[0],
                pll,
                equivalentAUFsForOurAlgorithm[1],
              ],
              correct: true,
              startingState: "doNewVisit",
              startPageCallback: () =>
                pllTrainerElements.recurringUserStartPage.worstCaseListItem
                  .get()
                  .invoke("text")
                  .setAlias<Aliases, "statsAfterFirstTest">(
                    "statsAfterFirstTest"
                  ),
              testRunningCallback: () =>
                pllTrainerElements.testRunning.testCase
                  .getStringRepresentationOfCube()
                  .setAlias<Aliases, "cubeAfterAlgorithmPicked">(
                    "cubeAfterAlgorithmPicked"
                  ),
            });

            cy.visit(paths.pllTrainer);
            pllTrainerElements.recurringUserStartPage.worstCaseListItem
              .get()
              .invoke("text")
              .setAlias<Aliases, "statsAfterSecondTest">(
                "statsAfterSecondTest"
              );
            return cy.getAliases<Aliases>();
          })
          .should(
            ({
              cubeBeforeAlgorithmPicked,
              statsAfterFirstTest,
              cubeAfterAlgorithmPicked,
              statsAfterSecondTest,
            }) => {
              // We assert cubes should be the same to ensure we didn't write the test
              // wrong and provided different AUFs / cubes
              assertNonFalsyStringsEqual(
                cubeBeforeAlgorithmPicked,
                cubeAfterAlgorithmPicked,
                "cubes should be the same"
              );
              assertNonFalsyStringsEqual(
                statsAfterFirstTest,
                statsAfterSecondTest,
                "stats should be the same"
              );
            }
          );
      }
    });
  });

  describe("the test case cube displays correctly during tests", function () {
    /* eslint-disable mocha/no-setup-in-describe */
    ([
      {
        testName:
          "displays exactly the same whether there's a y rotation in the beginning or not as it's redundant",
        pll: PLL.Gc,
        algorithmWithRotation: "(y) R2 U' R U' R U R' U R2 D' U R U' R' D",
        // The same algorithm with no y rotation
        algorithmWithoutRotation: "R2 U' R U' R U R' U R2 D' U R U' R' D",
      },
      {
        testName:
          "displays exactly the same whether there's a U or Dw move in the beginning or not as it's redundant",
        pll: PLL.Gc,
        algorithmWithRotation: "U Dw R2 U' R U' R U R' U R2 D' U R U' R' D",
        // The same algorithm with no initial U or Dw move. Note the moves are in the opposite
        // directions, so this is not just equivalent to a y rotation
        algorithmWithoutRotation: "R2 U' R U' R U R' U R2 D' U R U' R' D",
      },
      {
        testName:
          "displays exactly the same, even if there's a y rotation in the middle of the algorithm that isn't corrected later",
        pll: PLL.V,
        algorithmWithRotation: "R' U R' U' (y) R' F' R2 U' R' U R' F R F",
        // The same algorithm but just modified to move the faces without the rotation
        algorithmWithoutRotation: "R' U R' U' B' R' B2 U' B' U B' R B R",
      },
      {
        testName:
          "displays exactly the same, even if there's an x rotation in the beginning of the algorithm that isn't corrected later",
        pll: PLL.E,
        algorithmWithRotation: "x U R' U' L U R U' r2 U' R U L U' R' U",
        // The same algorithm but just modified to move the faces without the rotation
        algorithmWithoutRotation: "F R' F' L F R F' r2 F' R F L F' R' F",
      },
      {
        testName:
          "displays exactly the same, even if there's a z rotation in the beginning of the algorithm that isn't corrected later",
        pll: PLL.V,
        algorithmWithRotation: "z D' R2 D R2 U R' D' R U' R U R' D R U'",
        // The same algorithm but just modified to move the faces without the rotation
        algorithmWithoutRotation: "R' U2 R U2 L U' R' U L' U L U' R U L'",
      },
      {
        testName:
          "displays exactly the same, even if there's a wide move in the algorithm that isn't corrected later",
        pll: PLL.Jb,
        algorithmWithRotation: "R U2 R' U' R U2 L' U R' U' r",
        // The same algorithm but just used an L move instead of the r move
        algorithmWithoutRotation: "R U2 R' U' R U2 L' U R' U' L",
      },
    ] as {
      testName: string;
      pll: PLL;
      algorithmWithRotation: string;
      algorithmWithoutRotation: string;
      only?: boolean;
    }[]).forEach(
      /* eslint-enable mocha/no-setup-in-describe */
      ({
        pll,
        algorithmWithRotation,
        algorithmWithoutRotation,
        testName,
        only,
      }) => {
        (only ? it.only : it)(testName, () => {
          type Aliases = {
            withRotation: string;
            withoutRotation: string;
          };
          // First we input the desired algorithm as our chosen one
          cy.visit(paths.pllTrainer);
          cy.setPLLAlgorithm(pll, algorithmWithRotation);
          // Then we run the test with that algorithm being used
          completePLLTestInMilliseconds(1000, {
            correct: true,
            forceTestCase: [AUF.none, pll, AUF.none],
            startingState: "pickTargetParametersPage",
            endingState: "testRunning",
            testRunningCallback: () =>
              pllTrainerElements.testRunning.testCase
                .getStringRepresentationOfCube()
                .setAlias<Aliases, "withRotation">("withRotation"),
          });

          cy.clearLocalStorage();
          // We again input the desired algorithm as our chosen one
          cy.visit(paths.pllTrainer);
          cy.setPLLAlgorithm(pll, algorithmWithoutRotation);
          // Then we run the test with that algorithm being used
          completePLLTestInMilliseconds(1000, {
            correct: true,
            forceTestCase: [AUF.none, pll, AUF.none],
            startingState: "pickTargetParametersPage",
            endingState: "testRunning",
            testRunningCallback: () =>
              pllTrainerElements.testRunning.testCase
                .getStringRepresentationOfCube()
                .setAlias<Aliases, "withoutRotation">("withoutRotation"),
          });

          cy.getAliases<Aliases>().then(({ withRotation, withoutRotation }) => {
            assertNonFalsyStringsEqual(
              withRotation,
              withoutRotation,
              "they should display the same cube no matter about uncorrected rotations in the algorithm"
            );
          });
        });
      }
    );

    it("doesn't display the same cube for same case with algorithms that require different AUFs", function () {
      type Aliases = {
        firstCube: string;
        secondCube: string;
      };
      const testCase = [AUF.none, PLL.Ua, AUF.none] as const;
      const firstAlgorithm = "R2 U' R' U' R U R U R U' R";
      const secondAlgorithm = "R2 U' R2 S R2 S' U R2";

      cy.visit(paths.pllTrainer);
      cy.setPLLAlgorithm(testCase[1], firstAlgorithm);
      completePLLTestInMilliseconds(1000, {
        forceTestCase: testCase,
        correct: true,
        startingState: "pickTargetParametersPage",
        endingState: "testRunning",
        testRunningCallback: () =>
          pllTrainerElements.testRunning.testCase
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "firstCube">("firstCube"),
      });

      cy.clearLocalStorage();

      cy.visit(paths.pllTrainer);
      cy.setPLLAlgorithm(testCase[1], secondAlgorithm);
      completePLLTestInMilliseconds(1000, {
        forceTestCase: testCase,
        correct: true,
        startingState: "pickTargetParametersPage",
        endingState: "testRunning",
        testRunningCallback: () =>
          pllTrainerElements.testRunning.testCase
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "secondCube">("secondCube"),
      });

      cy.getAliases<Aliases>().should(({ firstCube, secondCube }) => {
        assertNonFalsyStringsDifferent(
          firstCube,
          secondCube,
          "These algorithms should have different AUFs required"
        );
      });
    });
  });

  describe("other important things", function () {
    it("correctly identifies the optimal AUFs of symmetrical cases", function () {
      /**
       * Note that what we are testing here is how, when a case is provided, the app determines
       * the optimal AUF set to simplify this case to and interface with the user in this sense.
       *
       * We are deciding here that we prefer less total turns, quarter turns over half turns,
       * postAUFs over preAUFS and clockwise turns over counterclockwise turns if there
       * are multiple AUF combinations that need tiebreaking between. Also special case
       * [U, U'] is preferred over [U', U] just arbitrarily to have a fully defined ordering.
       *
       * As can be seen several factors are arbitrary such as the clockwise tiebreak.
       * This can definitely be changed in the future to be user customizable
       * or adjusted based on CATPS etc.
       */

      // H PERM TESTS - Full symmetry
      // First we make sure the algorithm is picked so AUFs are predictable
      cy.visit(paths.pllTrainer);
      cy.setPLLAlgorithm(PLL.H, pllToAlgorithmString[PLL.H]);
      assertAUFsDisplayedCorrectly({
        pll: PLL.H,
        // Checking that a preAUF is moved to a postAUF
        aufToSet: [AUF.U, AUF.none],
        aufToExpect: [AUF.none, AUF.U],
        startingStateOverride: "pickTargetParametersPage",
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.H,
        // These two should be simplified to a single U postAUF
        aufToSet: [AUF.UPrime, AUF.U2],
        aufToExpect: [AUF.none, AUF.U],
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.H,
        // These should cancel out to no AUFs
        aufToSet: [AUF.U2, AUF.U2],
        aufToExpect: [AUF.none, AUF.none],
      });

      // Z PERM TESTS - Half symmetry
      // Again make sure algorithm is picked
      cy.setPLLAlgorithm(PLL.Z, pllToAlgorithmString[PLL.Z]);
      assertAUFsDisplayedCorrectly({
        pll: PLL.Z,
        // Checking that [U, U'] is preferred over [U', U]
        aufToSet: [AUF.UPrime, AUF.U],
        aufToExpect: [AUF.U, AUF.UPrime],
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.Z,
        // Checking that [U, U] is preferred over [U', U']
        aufToSet: [AUF.UPrime, AUF.UPrime],
        aufToExpect: [AUF.U, AUF.U],
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.Z,
        // This should be simplified to a single U that has to be preAUF here
        aufToSet: [AUF.UPrime, AUF.U2],
        aufToExpect: [AUF.U, AUF.none],
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.Z,
        // Verifying that an already optimized AUF is not changed
        aufToSet: [AUF.none, AUF.U],
        aufToExpect: [AUF.none, AUF.U],
      });

      function assertAUFsDisplayedCorrectly({
        pll,
        aufToSet,
        aufToExpect,
        startingStateOverride,
      }: {
        pll: PLL;
        aufToSet: [AUF, AUF];
        aufToExpect: [AUF, AUF];
        startingStateOverride?: "pickTargetParametersPage";
      }) {
        completePLLTestInMilliseconds(1000, {
          forceTestCase: [aufToSet[0], pll, aufToSet[1]],
          correct: true,
          startingState: startingStateOverride ?? "doNewVisit",
          endingState: "testRunning",
          testRunningCallback() {
            // We need to restore the clock here in order for getCurrentTestCase to function
            // as ports don't work properly while time is mocked
            cy.clock().invoke("restore");
            cy.getCurrentTestCase().should(([preAUF, , postAUF]) => {
              expect([preAUF, postAUF]).to.deep.equal(aufToExpect);
            });
          },
        });
      }
    });
  });
});

function pickTargetParametersPageFirstThingNoSideEffects() {
  cy.withOverallNameLogged(
    { message: "pickTargetParametersPageFirstThingNoSideEffects" },
    () => {
      ([
        [
          "errors behave properly at the start",
          () => {
            // No errors expected as you enter the page
            pllTrainerElements.globals.anyErrorMessage.assertDoesntExist();
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function pickTargetParametersPageNoSideEffectsButScroll() {
  const elements = pllTrainerElements.pickTargetParametersPage;

  cy.withOverallNameLogged(
    { message: "pickTargetParametersPageNoSideEffectsButScroll" },
    () => {
      ([
        [
          "looks right",
          () => {
            elements.assertAllConsumableViaVerticalScroll(
              elements.container.specifier
            );
            cy.assertNoHorizontalScrollbar();
          },
        ],
        [
          "has correct default values",
          () => {
            elements.recognitionTimeInput.get().should("have.value", "2");
            elements.targetTPSInput.get().should("have.value", "2.5");
          },
        ],
        [
          "displays decimal keyboard on mobile devices",
          () => {
            elements.recognitionTimeInput
              .get()
              .should("have.attr", "inputmode", "decimal");
            elements.targetTPSInput
              .get()
              .should("have.attr", "inputmode", "decimal");
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function pickTargetParametersPageSideEffectsExceptNavigations() {
  const elements = pllTrainerElements.pickTargetParametersPage;

  cy.withOverallNameLogged(
    { message: "pickTargetParametersPageSideEffectsExceptNavigations" },
    () => {
      ([
        [
          "correctly inputs decimal inputs including converting commas to periods",
          () => {
            elements.recognitionTimeInput
              .get()
              .type("{selectall}{backspace}13.5", { delay: 0 })
              .should("have.value", "13.5");
            elements.targetTPSInput
              .get()
              .type("{selectall}{backspace}23.7", { delay: 0 })
              .should("have.value", "23.7");
            elements.recognitionTimeInput
              .get()
              .type("{selectall}{backspace}1,3", { delay: 0 })
              .should("have.value", "1.3");
            elements.targetTPSInput
              .get()
              .type("{selectall}{backspace}2,9", { delay: 0 })
              .should("have.value", "2.9");
          },
        ],
        [
          "displays error exactly if there's an invalid number",
          () => {
            testInput(
              elements.recognitionTimeInput,
              elements.recognitionTimeError
            );
            testInput(elements.targetTPSInput, elements.tpsError);

            function testInput(
              inputElement: OurElement,
              expectedError: OurElement
            ) {
              inputElement
                .get()
                .type("{selectall}{backspace}abc", { delay: 0 })
                .blur();
              expectedError.assertShows();
              inputElement
                .get()
                .type("{selectall}{backspace}3.5", { delay: 0 })
                .blur();
              expectedError.assertDoesntExist();
              inputElement
                .get()
                .type("{selectall}{backspace}3.5.5", { delay: 0 })
                .blur();
              expectedError.assertShows();
              inputElement
                .get()
                .type("{selectall}{backspace}61.1", { delay: 0 })
                .blur();
              expectedError.assertDoesntExist();
              // Empty input should also error
              inputElement
                .get()
                .type("{selectall}{backspace}", { delay: 0 })
                .blur();
              expectedError.assertShows();
            }
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesVariant1(params: {
  currentValuesAreValid: true;
}) {
  cy.withOverallNameLogged(
    { message: "testPickTargetParametersOnlySubmitsWithNoErrorsVariant1" },
    () => {
      testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesGivenSubmit(
        {
          submit: () =>
            pllTrainerElements.pickTargetParametersPage.submitButton
              .get()
              .click(),
          ...params,
        }
      );
    }
  );
}

function testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesVariant2(params: {
  currentValuesAreValid: true;
}) {
  cy.withOverallNameLogged(
    { message: "testPickTargetParametersOnlySubmitsWithNoErrorsVariant2" },
    () => {
      testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesGivenSubmit(
        {
          submit: () =>
            pllTrainerElements.pickTargetParametersPage.targetTPSInput
              .get()
              .type("{enter}"),
          ...params,
        }
      );
    }
  );
}

function testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesVariant3(params: {
  currentValuesAreValid: true;
}) {
  cy.withOverallNameLogged(
    { message: "testPickTargetParametersOnlySubmitsWithNoErrorsVariant3" },
    () => {
      testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesGivenSubmit(
        {
          submit: () =>
            pllTrainerElements.pickTargetParametersPage.recognitionTimeInput
              .get()
              .type("{enter}"),
          ...params,
        }
      );
    }
  );
}
function testPickTargetParametersOnlySubmitsWithNoErrorsUsingCurrentValuesGivenSubmit({
  submit,
}: {
  submit: () => void;
  currentValuesAreValid: true;
}) {
  cy.withOverallNameLogged(
    { message: "testPickTargetParametersOnlySubmitsWithNoErrors" },
    () => {
      const elements = pllTrainerElements.pickTargetParametersPage;

      elements.targetTPSInput
        .get()
        .invoke("val")
        .then((tps) =>
          elements.recognitionTimeInput
            .get()
            .invoke("val")
            .then((recognitionTime) => ({ tps, recognitionTime }))
        )
        .then(({ tps, recognitionTime }) => {
          makeInvalid(
            elements.recognitionTimeInput,
            elements.recognitionTimeError
          );
          submit();
          elements.container.assertShows();
          makeInvalid(elements.targetTPSInput, elements.tpsError);
          submit();
          elements.container.assertShows();
          makeValid(
            elements.recognitionTimeInput,
            elements.recognitionTimeError
          );
          submit();
          elements.container.assertShows();
          makeValid(elements.targetTPSInput, elements.tpsError);
          submit();
          elements.container.assertDoesntExist();

          function makeInvalid(
            inputElement: OurElement,
            errorElement: OurElement
          ) {
            inputElement.get().type("abc", { delay: 0 });
            errorElement.waitFor();
          }
          function makeValid(
            inputElement: OurElement,
            errorElement: OurElement
          ) {
            const value =
              inputElement === elements.targetTPSInput ? tps : recognitionTime;
            inputElement
              .get()
              .type("{selectall}{backspace}" + value, { delay: 0 });
            errorElement.assertDoesntExist();
          }
        });
    }
  );
}

function pickTargetParametersNavigateWithSomeDefaultValues() {
  const elements = pllTrainerElements.pickTargetParametersPage;

  elements.targetTPSInput.get().type("{selectall}{backspace}2.5", { delay: 0 });
  elements.recognitionTimeInput
    .get()
    .type("{selectall}{backspace}2", { delay: 0 });
  elements.submitButton.get().click();
}

function newUserStartPageNoSideEffectsButScroll() {
  const elements = pllTrainerElements.newUserStartPage;

  cy.withOverallNameLogged(
    { message: "newUserStartPageNoSideEffectsButScroll" },
    () => {
      ([
        [
          "looks right",
          () => {
            // These elements should all display without scrolling
            elements.welcomeText.assertShows();
            elements.welcomeText.assertContainedByWindow();
            // The rest we accept having to scroll for
            elements.assertAllConsumableViaVerticalScroll(
              elements.container.specifier
            );

            // A smoke test that we have added some links for the cubing terms
            elements.container.get().within(() => {
              cy.get("a").should("have.length.above", 0);
            });

            cy.assertNoHorizontalScrollbar();
          },
        ],
        [
          "doesn't start test when pressing other keys than space",
          () => {
            cy.pressKey(Key.a);
            elements.container.assertShows();
            cy.pressKey(Key.x);
            elements.container.assertShows();
            cy.pressKey(Key.capsLock);
            elements.container.assertShows();
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function assertItsNewUserNotRecurringUserStartPage() {
  cy.withOverallNameLogged(
    { message: "assertItsNewUserNotRecurringUserStartPage" },
    () => {
      pllTrainerElements.newUserStartPage.welcomeText.get().should("exist");
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();
    }
  );
}

function assertItsRecurringUserNotNewUserStartPage() {
  cy.withOverallNameLogged(
    { message: "assertItsRecurringUserNotNewUserStartPage" },
    () => {
      pllTrainerElements.newUserStartPage.welcomeText.assertDoesntExist();
      pllTrainerElements.recurringUserStartPage.averageTime
        .get()
        .should("exist");
    }
  );
}

function newUserStartPageBeginNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "newUserStartPageBeginNavigateVariant1" },
    () => {
      pllTrainerElements.newUserStartPage.startButton.get().click();
      pllTrainerElements.newUserStartPage.container.assertDoesntExist();
    }
  );
}

function newUserStartPageBeginNavigateVariant2() {
  cy.withOverallNameLogged(
    { message: "newUserStartPageBeginNavigateVariant2" },
    () => {
      pllTrainerElements.newUserStartPage.container.waitFor();
      cy.pressKey(Key.space);
      pllTrainerElements.newUserStartPage.container.assertDoesntExist();
    }
  );
}

function newUserStartPageEditTargetParamsNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "newUserStartPageEditTargetParamsNavigateVariant1" },
    () => {
      pllTrainerElements.newUserStartPage.editTargetParametersButton
        .get()
        .click();
      pllTrainerElements.newUserStartPage.container.assertDoesntExist();
    }
  );
}

function recurringUserStartPageNoSideEffectsButScroll() {
  const elements = pllTrainerElements.recurringUserStartPage;

  cy.withOverallNameLogged(
    { message: "recurringUserStartPageNoSideEffects" },
    () => {
      ([
        [
          "looks right",
          () => {
            // These elements should all display without scrolling
            [
              pllTrainerElements.recurringUserStartPage.numCasesTried,
              pllTrainerElements.recurringUserStartPage.numCasesNotYetTried,
              pllTrainerElements.recurringUserStartPage.worstThreeCases,
              pllTrainerElements.recurringUserStartPage.averageTPS,
              pllTrainerElements.recurringUserStartPage.averageTime,
            ].forEach((x) => {
              x.assertShows();
              x.assertContainedByWindow();
            });
            // The rest should just be consumable by scroll
            elements.assertAllConsumableViaVerticalScroll(
              elements.container.specifier
            );
            cy.assertNoHorizontalScrollbar();
            // A smoke test that we have added some links for the cubing terms
            pllTrainerElements.recurringUserStartPage.container
              .get()
              .within(() => {
                cy.get("a").should("have.length.above", 0);
              });
          },
        ],
        [
          "doesn't start test when pressing other keys than space",
          () => {
            cy.pressKey(Key.a);
            elements.container.assertShows();
            cy.pressKey(Key.x);
            elements.container.assertShows();
            cy.pressKey(Key.capsLock);
            elements.container.assertShows();
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function recurringUserStartPageNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "recurringUserStartPageNavigateVariant1" },
    () => {
      pllTrainerElements.recurringUserStartPage.startButton.get().click();
      pllTrainerElements.recurringUserStartPage.container.assertDoesntExist();
    }
  );
}

function recurringUserStartPageNavigateVariant2() {
  cy.withOverallNameLogged(
    { message: "recurringUserStartPageNavigateVariant2" },
    () => {
      pllTrainerElements.recurringUserStartPage.container.waitFor();
      cy.pressKey(Key.space);
      pllTrainerElements.recurringUserStartPage.container.assertDoesntExist();
    }
  );
}

function recurringUserStartPageEditTargetParamsNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "recurringUserStartPageEditTargetParamsNavigateVariant1" },
    () => {
      pllTrainerElements.recurringUserStartPage.editTargetParametersButton
        .get()
        .click();
      pllTrainerElements.recurringUserStartPage.container.assertDoesntExist();
    }
  );
}

function newCasePageNoSideEffectsButScroll() {
  const elements = pllTrainerElements.newCasePage;

  cy.withOverallNameLogged(
    { message: "newCasePageNoSideEffectsButScroll" },
    () => {
      ([
        [
          "looks right",
          () => {
            elements.assertAllShow();
            cy.assertNoHorizontalScrollbar();
            cy.assertNoVerticalScrollbar();
          },
        ],
        [
          "doesn't start test when pressing other keys than space",
          () => {
            cy.pressKey(Key.a);
            elements.container.assertShows();
            cy.pressKey(Key.x);
            elements.container.assertShows();
            cy.pressKey(Key.capsLock);
            elements.container.assertShows();
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function newCasePageNavigateVariant1() {
  cy.withOverallNameLogged({ message: "newCasePageNavigateVariant1" }, () => {
    pllTrainerElements.newCasePage.startTestButton.get().click();
    pllTrainerElements.newCasePage.container.assertDoesntExist();
  });
}

function newCasePageNavigateVariant2() {
  cy.withOverallNameLogged({ message: "newCasePageNavigateVariant2" }, () => {
    pllTrainerElements.newCasePage.container.waitFor();
    cy.pressKey(Key.space);
    pllTrainerElements.newCasePage.container.assertDoesntExist();
  });
}

function getReadyStateNoSideEffectsButScroll() {
  const elements = pllTrainerElements.getReadyState;

  cy.withOverallNameLogged(
    { message: "getReadyStateNoSideEffectsButScroll" },
    () => {
      ([
        [
          "looks right",
          () => {
            elements.container.assertShows();
            elements.getReadyOverlay.assertShows();
            elements.getReadyExplanation.assertShows();
            // Since they are behind the overlay they don't actually show, so we just assert
            // they are contained by the window instead
            elements.timer.assertContainedByWindow();
            elements.cubePlaceholder.assertContainedByWindow();

            cy.assertNoHorizontalScrollbar();
            cy.assertNoVerticalScrollbar();
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

// We only use this parameter to communicate to the caller the requirements
// this function has in order to be called correctly
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function testRunningWithTimeSideEffects(_: { timerIsCurrentlyAtZero: true }) {
  const elements = pllTrainerElements.testRunning;

  cy.withOverallNameLogged(
    { message: "testRunningWithTimeSideEffects" },
    () => {
      cy.window()
        .then((window) => new window.Date().getTime())
        .then((startTime) => {
          ([
            [
              "looks right",
              () => {
                elements.assertAllShow();
                cy.assertNoHorizontalScrollbar();
                cy.assertNoVerticalScrollbar();
              },
            ],
            [
              "tracks time correctly",
              () => {
                const second = 1000;
                const minute = 60 * second;
                const hour = 60 * minute;
                // Should start at 0
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "0.0");
                // Just testing here that nothing happens with small increments
                cy.tick(3);
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "0.0");
                cy.tick(10);
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "0.0");
                cy.tick(0.2 * second);
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "0.2");
                cy.tick(1.3 * second);
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "1.5");
                // Switch to using time jumps as tick calls all setInterval and
                // request animation frame calbacks in the time interval resulting
                // in slow tests and excessive cpu usage

                // Checking two digit seconds alone
                cy.setSystemTimeWithLastFrameTicked(19.2 * second + startTime);
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "19.2");
                // Checking "normal" minute
                cy.setSystemTimeWithLastFrameTicked(
                  3 * minute + 16.8 * second + startTime
                );
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "3:16.8");
                // Checking single digit seconds displays the 0 when above a minute
                cy.setSystemTimeWithLastFrameTicked(
                  4 * minute + 7.3 * second + startTime
                );
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "4:07.3");
                // Check that it shows hours
                cy.setSystemTimeWithLastFrameTicked(
                  4 * hour + 38 * minute + 45.7 * second + startTime
                );
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "4:38:45.7");
                // Check that it shows double digits for minutes and seconds when in hours
                cy.setSystemTimeWithLastFrameTicked(
                  5 * hour + 1 * minute + 4 * second + startTime
                );
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "5:01:04.0");
                // Just ensuring a ridiculous amount works too, note we don't break it down to days
                cy.setSystemTimeWithLastFrameTicked(
                  234 * hour + 59 * minute + 18.1 * second + startTime
                );
                pllTrainerElements.testRunning.timer
                  .get()
                  .should("have.text", "234:59:18.1");
              },
            ],
            [
              "all looks good also after timer has run for 15 hours",
              () => {
                // We set the timer to double digit hours to test the limits of the width, that seems like it could be plausible
                // for a huge multiblind attempt if we for some reason support that in the future,
                // but three digit hours seems implausible so no need to test that
                cy.setSystemTimeWithLastFrameTicked(
                  1000 * 60 * 60 * 15 + startTime
                );
                cy.assertNoHorizontalScrollbar();
                cy.assertNoVerticalScrollbar();
                const minDimension = Math.min(
                  Cypress.config().viewportWidth,
                  Cypress.config().viewportHeight
                );
                pllTrainerElements.testRunning.timer
                  .get()
                  .should((timerElement) => {
                    expect(timerElement.height()).to.be.at.least(
                      0.2 * minDimension
                    );
                  });
                pllTrainerElements.testRunning.testCase
                  .assertShows()
                  .and((cubeElement) => {
                    expect(
                      cubeElement.width(),
                      "cube width to fill at least half of screen"
                    ).to.be.at.least(minDimension * 0.5 - 1);
                    expect(
                      cubeElement.height(),
                      "cube height to fill at least half of screen"
                    ).to.be.at.least(minDimension * 0.5 - 1);
                  });
              },
            ],
          ] as const).forEach(([testDescription, testFunction]) =>
            cy.withOverallNameLogged({ message: testDescription }, testFunction)
          );
        });
    }
  );
}

function testRunningNavigateVariant1() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant1" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.mouseClickScreen("topLeft");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant2() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant2" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.mouseClickScreen("bottomRight");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant3() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant3" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.mouseClickScreen("center");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant4() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant4" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.mouseClickScreen("topRight");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant5() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant5" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.mouseClickScreen("bottomLeft");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant6() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant6" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.touchScreen("topLeft");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant7() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant7" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.touchScreen("bottomRight");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant8() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant8" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.touchScreen("center");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant9() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant9" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.touchScreen("topRight");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant10() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant10" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    cy.touchScreen("bottomLeft");
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant11() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant11" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    // Extra interesting as it's used as a shortcut in evaluate result
    cy.pressKey(Key.space);
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant12() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant12" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    // Extra interesting as it's used as a shortcut in evaluate result
    cy.pressKey(Key.w);
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant13() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant13" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    // Extra interesting as it's used as a shortcut in evaluate result
    cy.pressKey(Key.W);
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateVariant14() {
  cy.withOverallNameLogged({ message: "testRunningNavigateVariant14" }, () => {
    pllTrainerElements.testRunning.container.waitFor();
    // Just a random "nonimportant" key, to make sure that works too
    cy.pressKey(Key.five);
    pllTrainerElements.testRunning.container.assertDoesntExist();
  });
}

function testRunningNavigateChangingClockVariant1() {
  cy.withOverallNameLogged(
    { message: "testRunningNavigateChangingClockVariant1" },
    () => {
      pllTrainerElements.testRunning.container.waitFor();
      // Extra interesting as it's used as a shortcut in evaluate result
      cy.longPressKey(Key.space);
      pllTrainerElements.testRunning.container.assertDoesntExist();
    }
  );
}

function testRunningNavigateChangingClockVariant2() {
  cy.withOverallNameLogged(
    { message: "testRunningNavigateChangingClockVariant2" },
    () => {
      pllTrainerElements.testRunning.container.waitFor();
      // Extra interesting as it's used as a shortcut in evaluate result
      cy.longPressKey(Key.w);
      pllTrainerElements.testRunning.container.assertDoesntExist();
    }
  );
}

function testRunningNavigateChangingClockVariant3() {
  cy.withOverallNameLogged(
    { message: "testRunningNavigateChangingClockVariant3" },
    () => {
      pllTrainerElements.testRunning.container.waitFor();
      // Extra interesting as it's used as a shortcut in evaluate result
      cy.longPressKey(Key.W);
      pllTrainerElements.testRunning.container.assertDoesntExist();
    }
  );
}

function testRunningNavigateChangingClockVariant4() {
  cy.withOverallNameLogged(
    { message: "testRunningNavigateChangingClockVariant4" },
    () => {
      pllTrainerElements.testRunning.container.waitFor();
      // Just a random "nonimportant" key, to make sure that works too
      cy.longPressKey(Key.five);
      pllTrainerElements.testRunning.container.assertDoesntExist();
    }
  );
}

function testRunningNavigateChangingClockVariant5() {
  cy.withOverallNameLogged(
    { message: "testRunningNavigateChangingClockVariant5" },
    () => {
      pllTrainerElements.testRunning.container.waitFor();
      // button mash space before w
      cy.buttonMash([
        Key.l,
        Key.five,
        Key.shift,
        Key.space,
        Key.capsLock,
        Key.leftCtrl,
        Key.w,
        Key.W,
      ]);
      // We don't just assert leaving the test but also that we didn't pass through
      // evaluate result by pressing w in our button  mash. This is important
      // that it is avoided and it shouldn't be too brittle as test page navigating
      // to evaluate result should be pretty stable
      pllTrainerElements.evaluateResult.container.assertShows();
    }
  );
}

function testRunningNavigateChangingClockVariant6() {
  cy.withOverallNameLogged(
    { message: "testRunningNavigateChangingClockVariant6" },
    () => {
      pllTrainerElements.testRunning.container.waitFor();
      // button mash w before space
      cy.buttonMash([
        Key.w,
        Key.W,
        Key.l,
        Key.five,
        Key.shift,
        Key.space,
        Key.capsLock,
        Key.leftCtrl,
      ]);
      // We don't just assert leaving the test but also that we didn't pass through
      // evaluate result by pressing w in our button  mash. This is important
      // that it is avoided and it shouldn't be too brittle as test page navigating
      // to evaluate result should be pretty stable
      pllTrainerElements.evaluateResult.container.assertShows();
    }
  );
}

function testRunningNavigateChangingClockVariant7() {
  cy.withOverallNameLogged(
    { message: "testRunningNavigateChangingClockVariant7" },
    () => {
      pllTrainerElements.testRunning.container.waitFor();
      // Long button mash
      cy.longButtonMash([
        Key.w,
        Key.W,
        Key.l,
        Key.five,
        Key.shift,
        Key.space,
        Key.capsLock,
        Key.leftCtrl,
      ]);
      // We don't just assert leaving the test but also that we didn't pass through
      // evaluate result by pressing w in our button  mash. This is important
      // that it is avoided and it shouldn't be too brittle as test page navigating
      // to evaluate result should be pretty stable
      pllTrainerElements.evaluateResult.container.assertShows();
    }
  );
}

function evaluateResultWhileIgnoringTransitionsNoSideEffects() {
  const elements = pllTrainerElements.evaluateResult;

  cy.withOverallNameLogged(
    { message: "evaluateResultWhileIgnoringTransitionsNoSideEffects" },
    () => {
      ([
        [
          "looks right",
          () => {
            elements.assertAllShow();
            cy.assertNoHorizontalScrollbar();
            cy.assertNoVerticalScrollbar();
          },
        ],
        [
          "doesn't change state when otherwise correct buttons or shortcuts are pressed",
          () => {
            elements.correctButton.get().click({ force: true });
            elements.container.assertShows();

            elements.wrongButton.get().click({ force: true });
            elements.container.assertShows();

            cy.pressKey(Key.space);
            elements.container.assertShows();
            cy.pressKey(Key.w);
            elements.container.assertShows();
            cy.pressKey(Key.W);
            elements.container.assertShows();
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function evaluateResultAfterIgnoringTransitionsNoSideEffects() {
  const elements = pllTrainerElements.evaluateResult;

  cy.withOverallNameLogged(
    { message: "evaluateResultAfterIgnoringTransitionsNoSideEffects" },
    () => {
      ([
        [
          "looks right",
          () => {
            elements.assertAllShow();
            cy.assertNoHorizontalScrollbar();
            cy.assertNoVerticalScrollbar();
          },
        ],
        [
          "doesn't change state when pressing other keys than space and W",
          () => {
            [Key.leftCtrl, Key.five, Key.l].forEach((key) => {
              cy.withOverallNameLogged(
                {
                  displayName: "TESTING KEY",
                  message: "'" + getKeyValue(key) + "'",
                },
                () => {
                  cy.pressKey(key, { log: false });
                  elements.container.assertShows();
                }
              );
            });
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

// We only use this parameter to communicate to the caller the requirements
// this function has in order to be called correctly
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function evaluateResultTimeDependantNoSideEffects1(_: { timeInMs: 1530 }) {
  cy.withOverallNameLogged(
    { message: "displays the time it was stopped at" },
    () => {
      pllTrainerElements.evaluateResult.timeResult
        .get()
        .should("have.text", "1.53");
    }
  );
}

// We only use this parameter to communicate to the caller the requirements
// this function has in order to be called correctly
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function evaluateResultTimeDependantNoSideEffects2(_: { timeInMs: 600 }) {
  cy.withOverallNameLogged(
    { message: "displays two decimals on whole decisecond" },
    () => {
      pllTrainerElements.evaluateResult.timeResult
        .get()
        .should("have.text", "0.60");
    }
  );
}

// We only use this parameter to communicate to the caller the requirements
// this function has in order to be called correctly
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function evaluateResultTimeDependantNoSideEffects3(_: { timeInMs: 1030 }) {
  cy.withOverallNameLogged(
    { message: "displays two decimals on single digit centisecond" },
    () => {
      pllTrainerElements.evaluateResult.timeResult
        .get()
        .should("have.text", "1.03");
    }
  );
}

// We only use this parameter to communicate to the caller the requirements
// this function has in order to be called correctly
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function evaluateResultTimeDependantNoSideEffects4(_: { timeInMs: 100 }) {
  cy.withOverallNameLogged({ message: "handles low granularity: 0" }, () => {
    pllTrainerElements.evaluateResult.timeResult
      .get()
      .should("have.text", "0.10");
  });
}

// We only use this parameter to communicate to the caller the requirements
// this function has in order to be called correctly
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function evaluateResultTimeDependantNoSideEffects5(_: { timeInMs: 110 }) {
  cy.withOverallNameLogged({ message: "handles low granularity: 1" }, () => {
    pllTrainerElements.evaluateResult.timeResult
      .get()
      .should("have.text", "0.11");
  });
}

// We only use this parameter to communicate to the caller the requirements
// this function has in order to be called correctly
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function evaluateResultTimeDependantNoSideEffects6(_: { timeInMs: 120 }) {
  cy.withOverallNameLogged({ message: "handles low granularity: 2" }, () => {
    pllTrainerElements.evaluateResult.timeResult
      .get()
      .should("have.text", "0.12");
  });
}

/**
 * The timestamp represents 12:34:56.78, and was calculated as follows:
 * 1000 * 60 * 60 * 12 + 1000 * 60 * 34 + 1000 * 56 + 780
 */
// We only use this parameter to communicate to the caller the requirements
// this function has in order to be called correctly
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function evaluateResultTimeDependantNoSideEffects7(_: { timeInMs: 45296780 }) {
  const elements = pllTrainerElements.evaluateResult;

  cy.withOverallNameLogged(
    { message: "evaluateResultTimeDependantNoSideEffects7" },
    () => {
      ([
        [
          "displays the very large time correctly",
          () => {
            elements.timeResult.get().should("have.text", "12:34:56.78");
          },
        ],
        [
          "displays everything nicely and correctly even with very large time",
          () => {
            cy.assertNoHorizontalScrollbar();
            cy.assertNoVerticalScrollbar();
            const minDimension = Math.min(
              Cypress.config().viewportWidth,
              Cypress.config().viewportHeight
            );
            [elements.expectedCubeFront, elements.expectedCubeBack].forEach(
              (cubeElement) =>
                cubeElement.get().should((jqueryCube) => {
                  expect(
                    jqueryCube.width(),
                    "cube width to fill at least a quarter of min dimension"
                  ).to.be.at.least(minDimension / 4);
                  expect(
                    jqueryCube.height(),
                    "cube height to fill at least a quarter of min dimension"
                  ).to.be.at.least(minDimension / 4);
                  expect(
                    jqueryCube.height(),
                    "cube height to fill at most half of screen height"
                  ).to.be.at.most(Cypress.config().viewportHeight / 2);
                })
            );
            elements.timeResult.get().should((timerElement) => {
              expect(
                timerElement.height(),
                "time result height at least 10% of min dimension"
              ).to.be.at.least(minDimension / 10);
              expect(
                timerElement.height(),
                "time result at most a third of screen height"
              ).to.be.at.most(Cypress.config().viewportHeight / 3);
            });
            [elements.correctButton, elements.wrongButton].forEach(
              (buttonGetter) => {
                buttonGetter.get().should((buttonElement) => {
                  expect(
                    buttonElement.height(),
                    "button height at least 5% of min dimension"
                  ).to.be.at.least(minDimension / 20);
                  expect(
                    buttonElement.height(),
                    "button height at most a third of screen height"
                  ).to.be.at.most(Cypress.config().viewportHeight / 3);
                });
              }
            );
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function evaluateResultNavigateCorrectVariant1() {
  cy.withOverallNameLogged(
    { message: "evaluateResultNavigateCorrectVariant1" },
    () => {
      pllTrainerElements.evaluateResult.correctButton.get().click();
      pllTrainerElements.evaluateResult.container.assertDoesntExist();
    }
  );
}

function evaluateResultNavigateCorrectVariant2() {
  cy.withOverallNameLogged(
    { message: "evaluateResultNavigateCorrectVariant2" },
    () => {
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.pressKey(Key.space);
      pllTrainerElements.evaluateResult.container.assertDoesntExist();
    }
  );
}

function evaluateResultNavigateWrongVariant1() {
  cy.withOverallNameLogged(
    { message: "evaluateResultNavigateWrongVariant1" },
    () => {
      pllTrainerElements.evaluateResult.wrongButton.get().click();
      pllTrainerElements.evaluateResult.container.assertDoesntExist();
    }
  );
}

function evaluateResultNavigateWrongVariant2() {
  cy.withOverallNameLogged(
    { message: "evaluateResultNavigateWrongVariant2" },
    () => {
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.pressKey(Key.w);
      pllTrainerElements.evaluateResult.container.assertDoesntExist();
    }
  );
}

function evaluateResultNavigateWrongVariant3() {
  cy.withOverallNameLogged(
    { message: "evaluateResultNavigateWrongVariant3" },
    () => {
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.pressKey(Key.W);
      pllTrainerElements.evaluateResult.container.assertDoesntExist();
    }
  );
}

function pickAlgorithmPageFirstThingNoSideEffects() {
  const elements = pllTrainerElements.pickAlgorithmPage;
  cy.withOverallNameLogged(
    { message: "pickAlgorithmPageFirstThingNoSideEffects" },
    () => {
      ([
        [
          "auto focuses the algorithm input",
          () => {
            elements.algorithmInput.assertIsFocused();
          },
        ],
        [
          "errors behave properly at the start",
          () => {
            // No errors expected as you enter the page
            pllTrainerElements.globals.anyErrorMessage.assertDoesntExist();
            // Should require input if pressing enter right away
            elements.algorithmInput.get().type("{enter}");
            elements.inputRequiredError.assertShows();
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function pickAlgorithmPageSideEffectsExceptNavigations() {
  const elements = pllTrainerElements.pickAlgorithmPage;
  cy.withOverallNameLogged(
    { message: "pickAlgorithmPageSideEffectsExceptNavigations" },
    () => {
      ([
        [
          "looks right",
          () => {
            elements.assertAllShow();
            // Produce a very long error and assert it still displays, and that it didn't
            // trigger any scrollbars
            pllTrainerElements.pickAlgorithmPage.algorithmInput
              .get()
              .type("U B F2 A ".repeat(20) + "{enter}", { delay: 0 });
            pllTrainerElements.pickAlgorithmPage.invalidTurnableError.assertShows();
            cy.assertNoHorizontalScrollbar();
            cy.assertNoVerticalScrollbar();

            // The text should somehow communicate which pll we are picking an algorithm for
            cy.getCurrentTestCase().then(([, pll]) =>
              pllTrainerElements.pickAlgorithmPage.explanationText
                .get()
                .should("contain.text", pllToPllLetters[pll])
            );
          },
        ],
        [
          "has correct links",
          () => {
            type Aliases = {
              firstExpertLink: string;
            };
            cy.getCurrentTestCase().then((currentCase) => {
              // The page should have an AlgDB link to the case being picked for
              testAlgdbLink(currentCase[1]);
              // The page should have any type of expert guidance link, any further assertions
              // would make for too brittle tests
              pllTrainerElements.pickAlgorithmPage.expertPLLGuidanceLink
                .get()
                .should((link) => {
                  expect(link.prop("tagName")).to.equal("A");
                  // Assert it opens in new tab
                  expect(link.attr("target"), "target").to.equal("_blank");
                })
                .then((link) => {
                  const url =
                    link.attr("href") ||
                    "http://veryinvaliddomainnameasdfasfasdfasfdas.invalid";
                  // Check that the link actually works
                  return cy
                    .request(url)
                    .its("status")
                    .should("be.at.least", 200)
                    .and("be.lessThan", 300)
                    .then(() => url);
                })
                .setAlias<Aliases, "firstExpertLink">("firstExpertLink");

              // We want to change the algorithm to something different so ensuring
              // here that we don't pick the same one again
              let differentTestCase: [AUF, PLL, AUF];
              if (currentCase[1] === PLL.Ga) {
                differentTestCase = [AUF.U, PLL.Ja, AUF.U2];
              } else {
                differentTestCase = [AUF.U, PLL.Ga, AUF.U2];
              }
              cy.setCurrentTestCase(differentTestCase);

              testAlgdbLink(differentTestCase[1]);
              pllTrainerElements.pickAlgorithmPage.expertPLLGuidanceLink
                .get()
                .should((link) => {
                  expect(link.prop("tagName")).to.equal("A");
                  // Assert it opens in new tab
                  expect(link.attr("target"), "target").to.equal("_blank");
                })
                .then((link) => {
                  const url =
                    link.attr("href") ||
                    "http://veryinvaliddomainnameasdfasfasdfasfdas.invalid";
                  // Check that the link actually works
                  cy.request(url)
                    .its("status")
                    .should("be.at.least", 200)
                    .and("be.lessThan", 300);
                  return cy.getAliases<Aliases>().then((aliases) => ({
                    previous: aliases.firstExpertLink,
                    current: url,
                  }));
                })
                .should(({ previous, current }) => {
                  assertNonFalsyStringsDifferent(
                    previous,
                    current,
                    "first (previous url) is different from second (current url) after pll case change"
                  );
                });

              // Make sure to reset the test case so we don't have side effects
              cy.setCurrentTestCase(currentCase);

              function testAlgdbLink(currentPLL: PLL) {
                pllTrainerElements.pickAlgorithmPage.algDbLink
                  .get()
                  .should((link) => {
                    expect(link.prop("tagName")).to.equal("A");
                    // Assert it opens in new tab
                    expect(link.attr("target"), "target").to.equal("_blank");

                    expect(link.prop("href"), "href")
                      .to.be.a("string")
                      .and.contain("algdb.net")
                      .and.satisfy(
                        (href: string) =>
                          href
                            .toLowerCase()
                            .endsWith(
                              "/" + pllToPllLetters[currentPLL].toLowerCase()
                            ),
                        "ends with /" +
                          pllToPllLetters[currentPLL].toLowerCase()
                      );
                  })
                  .then((link) => {
                    // Check that the link actually works
                    cy.request(
                      link.attr("href") ||
                        "http://veryinvaliddomainnameasdfasfasdfasfdas.invalid"
                    )
                      .its("status")
                      .should("be.at.least", 200)
                      .and("be.lessThan", 300);
                  });
              }
            });
          },
        ],
        [
          "all errors display exactly when expected, don't update unless an attempt at submitting has occurred, and stays on the page despite submit action when an error is expected",
          () => {
            let useEnterKeyToSubmit = true;
            function clearInputThenTypeAndSubmit(input: string): void {
              elements.algorithmInput
                .get()
                .type(`{selectall}{backspace}${input}`, { delay: 0 });

              if (useEnterKeyToSubmit) {
                elements.algorithmInput.get().type("{enter}", { delay: 0 });
              } else {
                elements.submitButton.get().click();
              }

              useEnterKeyToSubmit = !useEnterKeyToSubmit;
            }
            // Should require input if input is empty
            clearInputThenTypeAndSubmit("");
            elements.inputRequiredError.assertShows();

            // Should no longer require input after input
            elements.algorithmInput.get().type("asdfgfda{enter}");
            elements.inputRequiredError.assertDoesntExist();

            // Should require input again after deleting the input
            clearInputThenTypeAndSubmit("");
            elements.inputRequiredError.assertShows();

            // Errors informatively when invalid turnable encountered
            clearInputThenTypeAndSubmit("U B A");
            elements.invalidTurnableError.assertShows();

            // Errors informatively when invalid turn length encountered
            clearInputThenTypeAndSubmit("U4");
            elements.invalidTurnLengthError.assertShows();

            // Errors informatively when repeated turnable encountered
            // And doesn't update the error until the submit action
            elements.algorithmInput
              .get()
              .type("{selectall}{backspace}U2U", { delay: 0 });
            // Still old error before submit
            elements.invalidTurnLengthError.assertShows();
            elements.submitButton.get().click();
            // Error now updated after submit action
            elements.repeatedTurnableError.assertShows();

            // Errors informatively when mixed wide move styles encountered
            // And doesn't update the error until the submit action, this time using enter key
            elements.algorithmInput
              .get()
              .type("{selectall}{backspace}u B Rw", { delay: 0 });
            // Still old error before submit
            elements.repeatedTurnableError.assertShows();
            elements.algorithmInput.get().type("{enter}", { delay: 0 });
            // Error now updated after submit action
            elements.wideMoveStylesMixedError.assertShows();

            // Errors informatively when space between turnable and apostrophe encountered
            clearInputThenTypeAndSubmit("U '");
            elements.turnWouldWorkWithoutInterruptionError.assertShows();

            // Errors informatively when parenthesis between turnable and apostrophe encountered
            clearInputThenTypeAndSubmit("(U)'");
            elements.turnWouldWorkWithoutInterruptionError.assertShows();

            // Errors informatively when apostrophe on wrong side of length encountered
            clearInputThenTypeAndSubmit("U'2");
            elements.apostropheWrongSideOfLengthError.assertShows();

            // Errors informatively when unclosed parenthesis encountered
            clearInputThenTypeAndSubmit("U ( B F' D2");
            elements.unclosedParenthesisError.assertShows();

            // Errors informatively when unmatched closing parenthesis encountered
            clearInputThenTypeAndSubmit("U B F' ) D2");
            elements.unmatchedClosingParenthesisError.assertShows();

            // Errors informatively when nested parentheses encountered
            clearInputThenTypeAndSubmit("( U (B F') ) D2");
            elements.nestedParenthesesError.assertShows();

            // Errors informatively when invalid symbol encountered
            clearInputThenTypeAndSubmit("( U B F') % D2");
            elements.invalidSymbolError.assertShows();

            // Errors informatively when an algorithm that doesn't match the case is encountered
            cy.getCurrentTestCase().then(([, correctPLL]) => {
              const wrongPLL = correctPLL === PLL.Ga ? PLL.Gb : PLL.Ga;
              clearInputThenTypeAndSubmit(pllToAlgorithmString[wrongPLL]);
              elements.algorithmDoesntMatchCaseError.assertShows();
            });
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function pickAlgorithmNavigateVariant1() {
  cy.withOverallNameLogged({ message: "pickAlgorithmNavigateVariant1" }, () => {
    cy.getCurrentTestCase().then(([, currentPLL]) => {
      typeInAlgorithm(currentPLL);
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type("{enter}", {
          delay: 0,
        });
    });
    pllTrainerElements.pickAlgorithmPage.container.assertDoesntExist();
  });
}

function pickAlgorithmNavigateVariant2() {
  cy.withOverallNameLogged({ message: "pickAlgorithmNavigateVariant2" }, () => {
    cy.getCurrentTestCase().then(([, currentPLL]) => {
      typeInAlgorithm(currentPLL);
    });
    pllTrainerElements.pickAlgorithmPage.submitButton.get().click();
    pllTrainerElements.pickAlgorithmPage.container.assertDoesntExist();
  });
}

function typeInAlgorithm(currentPLL: PLL) {
  const preAUF = allAUFs[Math.floor(Math.random() * allAUFs.length)];
  if (preAUF === undefined) {
    throw new Error("No preAUF found");
  }
  const postAUF = allAUFs[Math.floor(Math.random() * allAUFs.length)];
  if (postAUF === undefined) {
    throw new Error("No postAUF found");
  }
  const allRotations = [
    "",
    "x",
    "x2",
    "x'",
    "z",
    "z'",
  ].flatMap((determineUpFace) =>
    ["", "y", "y2", "y'"].map(
      (determineFrontFace) => determineUpFace + " " + determineFrontFace
    )
  );
  const rotation =
    allRotations[Math.floor(Math.random() * allRotations.length)];
  if (rotation === undefined) {
    throw new Error("No rotation found");
  }

  cy.log(
    "random preAUF, postAUF, and final rotation chosen to test these also work: " +
      preAUF +
      ", " +
      postAUF +
      ", " +
      rotation
  );

  pllTrainerElements.pickAlgorithmPage.algorithmInput
    .get()
    .type(
      "{selectall}{backspace}" +
        aufToAlgorithmString[preAUF] +
        pllToAlgorithmString[currentPLL] +
        aufToAlgorithmString[postAUF] +
        rotation,
      { delay: 0 }
    );
}

function correctPageNoSideEffects() {
  cy.withOverallNameLogged({ message: "correctPageNoSideEffects" }, () => {
    const elements = pllTrainerElements.correctPage;
    ([
      [
        "looks right",
        () => {
          elements.assertAllShow();
          cy.assertNoHorizontalScrollbar();
          cy.assertNoVerticalScrollbar();
          assertFunctioningFeedbackButtonShows();
        },
      ],
      [
        "doesn't start test when pressing keys other than space",
        () => {
          cy.pressKey(Key.a);
          elements.container.assertShows();
          cy.pressKey(Key.x);
          elements.container.assertShows();
          cy.pressKey(Key.capsLock);
          elements.container.assertShows();
        },
      ],
    ] as const).forEach(([testDescription, testFunction]) =>
      cy.withOverallNameLogged({ message: testDescription }, testFunction)
    );
  });
}

function correctPageNavigateVariant1() {
  cy.withOverallNameLogged({ message: "correctPageNavigateVariant1" }, () => {
    pllTrainerElements.correctPage.nextButton.get().click();
    pllTrainerElements.correctPage.container.assertDoesntExist();
  });
}

function correctPageNavigateVariant2() {
  cy.withOverallNameLogged({ message: "correctPageNavigateVariant2" }, () => {
    pllTrainerElements.correctPage.container.waitFor();
    cy.pressKey(Key.space);
    pllTrainerElements.correctPage.container.assertDoesntExist();
  });
}

function typeOfWrongPageNoSideEffects({
  originalExpectedCubeFront,
  originalExpectedCubeBack,
  nextExpectedCubeFront,
  nextExpectedCubeBack,
}: {
  originalExpectedCubeFront: string;
  originalExpectedCubeBack: string;
  nextExpectedCubeFront: string;
  nextExpectedCubeBack: string;
}) {
  const elements = pllTrainerElements.typeOfWrongPage;
  cy.withOverallNameLogged({ message: "typeOfWrongPageNoSideEffects" }, () => {
    ([
      [
        "looks right",
        () => {
          // Make sure all elements present and no scrollbars
          elements.assertAllShow();
          cy.assertNoHorizontalScrollbar();
          cy.assertNoVerticalScrollbar();

          // Check all the cubes look right

          // The cube for 'no moves applied' should be the same state as the previous/original expected cube state
          assertCubeMatchesStateString(
            originalExpectedCubeFront,
            elements.noMoveCubeStateFront
          );
          assertCubeMatchesStateString(
            originalExpectedCubeBack,
            elements.noMoveCubeStateBack
          );
          // The cube for 'nearly there' should look like the expected state if you had
          // solved the case correctly
          assertCubeMatchesStateString(
            nextExpectedCubeFront,
            elements.nearlyThereCubeStateFront
          );
          assertCubeMatchesStateString(
            nextExpectedCubeBack,
            elements.nearlyThereCubeStateBack
          );
        },
      ],
      [
        "doesn't start test when pressing arbitrary keys",
        () => {
          // on purpose use some of the ones we often use like space and w
          [Key.space, Key.w, Key.W, Key.five, Key.d, Key.shift].forEach(
            (key) => {
              cy.pressKey(key);
              elements.container.assertShows();
            }
          );
        },
      ],
    ] as const).forEach(([testDescription, testFunction]) =>
      cy.withOverallNameLogged({ message: testDescription }, testFunction)
    );
  });
}

function typeOfWrongPageNoMovesNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "typeOfWrongPageNoMovesNavigateVariant1" },
    () => {
      pllTrainerElements.typeOfWrongPage.noMoveButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
    }
  );
}

function typeOfWrongPageNoMovesNavigateVariant2() {
  cy.withOverallNameLogged(
    { message: "typeOfWrongPageNoMovesNavigateVariant2" },
    () => {
      pllTrainerElements.typeOfWrongPage.container.waitFor();
      cy.pressKey(Key.one);
      pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
    }
  );
}

function typeOfWrongPageNearlyThereNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "typeOfWrongPageNearlyThereNavigateVariant1" },
    () => {
      pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
    }
  );
}

function typeOfWrongPageNearlyThereNavigateVariant2() {
  cy.withOverallNameLogged(
    { message: "typeOfWrongPageNearlyThereNavigateVariant2" },
    () => {
      pllTrainerElements.typeOfWrongPage.container.waitFor();
      cy.pressKey(Key.two);
      pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
    }
  );
}

function typeOfWrongPageUnrecoverableNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "typeOfWrongPageUnrecoverableNavigateVariant1" },
    () => {
      pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
    }
  );
}

function typeOfWrongPageUnrecoverableNavigateVariant2() {
  cy.withOverallNameLogged(
    { message: "typeOfWrongPageUnrecoverableNavigateVariant2" },
    () => {
      pllTrainerElements.typeOfWrongPage.container.waitFor();
      cy.pressKey(Key.three);
      pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
    }
  );
}

function algorithmDrillerExplanationPageNoSideEffectsButScroll({
  testCaseCube,
}: {
  testCaseCube: string;
  // Just for communicating expectations to caller
  defaultAlgorithmWasUsed: true;
}) {
  const elements = pllTrainerElements.algorithmDrillerExplanationPage;

  cy.withOverallNameLogged(
    { message: "algorithmDrillerExplanationPageNoSideEffectsButScroll" },
    () => {
      ([
        [
          "looks right",
          () => {
            elements.assertAllConsumableViaVerticalScroll(
              elements.container.specifier
            );
            assertCubeMatchesStateString(testCaseCube, elements.caseToDrill);
            cy.assertNoHorizontalScrollbar();
          },
        ],
        [
          "doesn't start test when pressing keys other than space",
          () => {
            cy.pressKey(Key.a);
            elements.container.assertShows();
            cy.pressKey(Key.x);
            elements.container.assertShows();
            cy.pressKey(Key.capsLock);
            elements.container.assertShows();
          },
        ],
        [
          "the algorithm is displayed as expected and without any rotations appended to the end of it",
          () => {
            cy.getApplicationState().then((originalApplicationState) => {
              cy.setCurrentTestCase([AUF.U, PLL.Gb, AUF.UPrime]);
              const gbAlgorithmEndingOneYRotationAway =
                "R' Dw' F R2 Uw R' U R U' R Uw' R2";
              cy.setPLLAlgorithm(PLL.Gb, gbAlgorithmEndingOneYRotationAway);
              elements.algorithmToDrill
                .get()
                .invoke("text")
                .then(sanitizeAlgorithm)
                .should(
                  "equal",
                  sanitizeAlgorithm(
                    "U" + gbAlgorithmEndingOneYRotationAway + "U'"
                  )
                );

              cy.setCurrentTestCase([AUF.U2, PLL.Aa, AUF.UPrime]);
              const AaAlgorithmEndingOneXRotationAway =
                "Lw' U R' D2 R U' R' D2 R2";
              cy.setPLLAlgorithm(PLL.Aa, AaAlgorithmEndingOneXRotationAway);
              elements.algorithmToDrill
                .get()
                .invoke("text")
                .then(sanitizeAlgorithm)
                .should(
                  "equal",
                  // Note that the last AUF here becomes a B move instead of rotating and
                  // doing a U move
                  sanitizeAlgorithm(
                    "U2" + AaAlgorithmEndingOneXRotationAway + "B'"
                  )
                );

              // Try one here with no AUFs and also being a z rotation away instead of x or y
              cy.setCurrentTestCase([AUF.none, PLL.Ra, AUF.none]);
              const RaAlgorithmEndingOneZPrimeRotationAway =
                "L U2 L' U2 L F' L' U' L U L Bw D2";
              cy.setPLLAlgorithm(
                PLL.Ra,
                RaAlgorithmEndingOneZPrimeRotationAway
              );
              elements.algorithmToDrill
                .get()
                .invoke("text")
                .then(sanitizeAlgorithm)
                .should(
                  "equal",
                  sanitizeAlgorithm(RaAlgorithmEndingOneZPrimeRotationAway)
                );

              function sanitizeAlgorithm(algorithm: string): string {
                return algorithm.replace(/\(|\)|\s/g, "");
              }

              // Undo all the side effects we just did
              cy.setApplicationState(originalApplicationState);
            });
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function algorithmDrillerExplanationPageNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "algorithmDrillerExplanationPageNavigateVariant1" },
    () => {
      pllTrainerElements.algorithmDrillerExplanationPage.continueButton
        .get()
        .click();
      pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist();
    }
  );
}

function algorithmDrillerExplanationPageNavigateVariant2() {
  cy.withOverallNameLogged(
    { message: "algorithmDrillerExplanationPageNavigateVariant2" },
    () => {
      pllTrainerElements.algorithmDrillerExplanationPage.container.waitFor();
      cy.pressKey(Key.space);
      pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist();
    }
  );
}

function algorithmDrillerStatusPageRightAfterExplanationPageNoSideEffects({
  solvedFront,
  solvedBack,
}: {
  solvedFront: string;
  solvedBack: string;
  // We are just adding this argument to make it clear what the requirements
  // are for the caller. That's also why only true is allowed
  expectedCubeStateDidNotEqualSolvedJustBeforeThis: true;
}) {
  const elements = pllTrainerElements.algorithmDrillerStatusPage;

  cy.withOverallNameLogged(
    { message: "algorithmDrillerStatusPageNoSideEffects" },
    () => {
      ([
        [
          "looks right",
          () => {
            elements.assertAllShow();
            cy.assertNoHorizontalScrollbar();
            cy.assertNoVerticalScrollbar();
          },
        ],
        [
          "the expected cube state at first is always solved even if expected cube state was not solved before",
          () => {
            assertCubeMatchesStateString(
              solvedFront,
              elements.expectedCubeStateFront
            );
            assertCubeMatchesStateString(
              solvedBack,
              elements.expectedCubeStateBack
            );
          },
        ],
        [
          "initial correct attempts left value reads 3",
          () => {
            elements.correctConsecutiveAttemptsLeft
              .get()
              .should("have.text", "3");
          },
        ],
        [
          "doesn't start test when pressing keys other than space",
          () => {
            cy.pressKey(Key.a);
            elements.container.assertShows();
            cy.pressKey(Key.x);
            elements.container.assertShows();
            cy.pressKey(Key.capsLock);
            elements.container.assertShows();
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function algorithmDrillerStatusPageAfter1SuccessNoSideEffects({
  evaluateResultFront,
  evaluateResultBack,
}: {
  evaluateResultFront: string;
  evaluateResultBack: string;
}) {
  const elements = pllTrainerElements.algorithmDrillerStatusPage;

  cy.withOverallNameLogged(
    { message: "algorithmDrillerStatusPageAfter1SuccessNoSideEffects" },
    () => {
      elements.correctConsecutiveAttemptsLeft.get().should("have.text", "2");

      // Here we assert that the cube is displayed in the expected state
      assertCubeMatchesStateString(
        evaluateResultFront,
        elements.expectedCubeStateFront
      );
      assertCubeMatchesStateString(
        evaluateResultBack,
        elements.expectedCubeStateBack
      );
    }
  );
}

function algorithmDrillerStatusPageAfter1Success1FailureNoSideEffects() {
  cy.withOverallNameLogged(
    { message: "algorithmDrillerStatusPageAfter1Success1FailureNoSideEffects" },
    () => {
      pllTrainerElements.algorithmDrillerStatusPage.correctConsecutiveAttemptsLeft
        .get()
        .should("have.text", "3");
    }
  );
}

function algorithmDrillerStatusPageAfter2SuccessesNoSideEffects() {
  cy.withOverallNameLogged(
    { message: "algorithmDrillerStatusPageAfter2SuccessesNoSideEffects" },
    () => {
      pllTrainerElements.algorithmDrillerStatusPage.correctConsecutiveAttemptsLeft
        .get()
        .should("have.text", "1");
    }
  );
}

function algorithmDrillerStatusPageNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "algorithmDrillerStatusPageNavigateVariant1" },
    () => {
      pllTrainerElements.algorithmDrillerStatusPage.nextTestButton
        .get()
        .click();
      pllTrainerElements.algorithmDrillerStatusPage.container.assertDoesntExist();
    }
  );
}

function algorithmDrillerStatusPageNavigateVariant2() {
  cy.withOverallNameLogged(
    { message: "algorithmDrillerStatusPageNavigateVariant2" },
    () => {
      pllTrainerElements.algorithmDrillerStatusPage.container.waitFor();
      cy.pressKey(Key.space);
      pllTrainerElements.algorithmDrillerStatusPage.container.assertDoesntExist();
    }
  );
}

function algorithmDrillerSuccessPageNoSideEffects() {
  const elements = pllTrainerElements.algorithmDrillerSuccessPage;

  cy.withOverallNameLogged(
    { message: "algorithmDrillerSuccessPageNoSideEffects" },
    () => {
      ([
        [
          "looks right",
          () => {
            elements.assertAllShow();
            cy.assertNoHorizontalScrollbar();
            cy.assertNoVerticalScrollbar();
          },
        ],
        [
          "doesn't start test when pressing keys other than space",
          () => {
            cy.pressKey(Key.a);
            elements.container.assertShows();
            cy.pressKey(Key.x);
            elements.container.assertShows();
            cy.pressKey(Key.capsLock);
            elements.container.assertShows();
          },
        ],
      ] as const).forEach(([testDescription, testFunction]) =>
        cy.withOverallNameLogged({ message: testDescription }, testFunction)
      );
    }
  );
}

function algorithmDrillerSuccessPageNavigateVariant1() {
  cy.withOverallNameLogged(
    { message: "algorithmDrillerSuccessPageNavigateVariant1" },
    () => {
      pllTrainerElements.algorithmDrillerSuccessPage.nextTestButton
        .get()
        .click();
      pllTrainerElements.algorithmDrillerSuccessPage.container.assertDoesntExist();
    }
  );
}

function algorithmDrillerSuccessPageNavigateVariant2() {
  cy.withOverallNameLogged(
    { message: "algorithmDrillerSuccessPageNavigateVariant2" },
    () => {
      pllTrainerElements.algorithmDrillerSuccessPage.container.waitFor();
      cy.pressKey(Key.space);
      pllTrainerElements.algorithmDrillerSuccessPage.container.assertDoesntExist();
    }
  );
}

function wrongPageNoSideEffects({
  testCaseFront,
  testCaseBack,
}: {
  testCaseFront: string;
  testCaseBack: string;
  // It's important that the nearly there button was used because
  // otherwise expected state could be solved state which could avoid catching
  // a bug we actually (nearly) had in production where what was
  // displayed was the expectedCube with the inverse test case applied
  // to it instead of the solved cube with inverse test case
  nearlyThereTypeOfWrongWasUsed: true;
}) {
  const elements = pllTrainerElements.wrongPage;

  cy.withOverallNameLogged({ message: "wrongPageNoSideEffects" }, () => {
    ([
      [
        "looks right",
        () => {
          elements.assertAllShow();
          assertFunctioningFeedbackButtonShows();
          cy.assertNoHorizontalScrollbar();
          cy.assertNoVerticalScrollbar();

          cy.overrideDisplayCubeAnnotations(false);
          // Test case cubes look correct
          assertCubeMatchesStateString(
            testCaseFront,
            pllTrainerElements.wrongPage.testCaseFront
          );
          assertCubeMatchesStateString(
            testCaseBack,
            pllTrainerElements.wrongPage.testCaseBack
          );
          cy.overrideDisplayCubeAnnotations(null);
          // Expected state cubes are tested in a special type of wrong test
        },
      ],
      [
        "doesn't start test when pressing keys other than space",
        () => {
          cy.pressKey(Key.a);
          elements.container.assertShows();
          cy.pressKey(Key.x);
          elements.container.assertShows();
          cy.pressKey(Key.capsLock);
          elements.container.assertShows();
        },
      ],
      [
        "has the right correct answer text",
        () => {
          cy.getCurrentTestCase().then((testCase) => {
            // Verify U, U2 and a pll display correctly
            const firstTestCase = [AUF.U, PLL.Aa, AUF.U2] as const;
            cy.setCurrentTestCase(firstTestCase);
            pllTrainerElements.wrongPage.testCaseName
              .get()
              .invoke("text")
              .should("match", testCaseToWrongPageRegex(firstTestCase));

            // Verify U' and nothing display correctly, while also trying a different PLL
            const secondTestCase = [AUF.UPrime, PLL.Ab, AUF.none] as const;
            cy.setCurrentTestCase(secondTestCase);
            pllTrainerElements.wrongPage.testCaseName
              .get()
              .invoke("text")
              .should("match", testCaseToWrongPageRegex(secondTestCase));

            // Verify no AUFs displays correctly and also trying a third PLL
            const thirdTestCase = [AUF.none, PLL.H, AUF.none] as const;
            cy.setCurrentTestCase(thirdTestCase);
            pllTrainerElements.wrongPage.testCaseName
              .get()
              .invoke("text")
              .should("match", testCaseToWrongPageRegex(thirdTestCase));

            // Reset to the previous test case, which is very important to uphold the
            // promise of no side effects
            cy.setCurrentTestCase(testCase);
          });
        },
      ],
    ] as const).forEach(([testDescription, testFunction]) =>
      cy.withOverallNameLogged({ message: testDescription }, testFunction)
    );
  });
}

function testCaseToWrongPageRegex(testCase: readonly [AUF, PLL, AUF]): RegExp {
  const firstAufString = aufToAlgorithmString[testCase[0]];
  const secondAufString = aufToAlgorithmString[testCase[2]];
  return new RegExp(
    [
      firstAufString && String.raw`\b${firstAufString}\s+`,
      String.raw`[^\b]*${pllToPllLetters[testCase[1]]}[^\b]*`,
      secondAufString && String.raw`\s+${secondAufString}\b`,
    ].join("")
  );
}

function wrongPageNavigateVariant1() {
  cy.withOverallNameLogged({ message: "wrongPageNavigateVariant1" }, () => {
    pllTrainerElements.wrongPage.nextButton.get().click();
    pllTrainerElements.wrongPage.container.assertDoesntExist();
  });
}

function wrongPageNavigateVariant2() {
  cy.withOverallNameLogged({ message: "wrongPageNavigateVariant2" }, () => {
    pllTrainerElements.wrongPage.container.waitFor();
    cy.pressKey(Key.space);
    pllTrainerElements.wrongPage.container.assertDoesntExist();
  });
}

function assertFunctioningFeedbackButtonShows() {
  pllTrainerElements.globals.feedbackButton
    .assertShows()
    .parent()
    .within(() => {
      // It should be a link going to a google form
      cy.get("a")
        .should((linkElement) => {
          expect(linkElement.prop("href"), "href")
            .to.be.a("string")
            .and.satisfy(
              (href: string) => href.startsWith("https://forms.gle/"),
              "starts with https://forms.gle/"
            );
          // Asserts it opens in new tab
          expect(linkElement.attr("target"), "target").to.equal("_blank");
        })
        .then((link) => {
          // Check that the link actually works
          cy.request(
            link.attr("href") ||
              "http://veryinvaliddomainnameasdfasfasdfasfdas.invalid"
          )
            .its("status")
            .should("be.at.least", 200)
            .and("be.lessThan", 300);
        });
    });
}

function getVerifiedAliases<
  Aliases extends { [key: string]: string },
  Keys extends keyof Aliases
>(keysToVerify: Keys[]): Cypress.Chainable<{ [key in Keys]: string }> {
  return cy.getAliases<Aliases>().then((aliases) => {
    const result: { [key in Keys]: string } = {} as {
      [key in Keys]: string;
    };
    for (const key of keysToVerify) {
      const value: string | undefined = aliases[key];
      if (value === undefined) {
        throw new Error(`Key ${key.toString()} is not defined`);
      }
      result[key] = value;
    }
    return result;
  });
}
