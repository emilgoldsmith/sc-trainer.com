module.exports = {
  "PLL Trainer": {
    "completely new user": {
      "different paths in the app:": {
        "shows new case for new user -> solved quickly + ending test by touching screen where correct button shows up doesn't press that button -> pick algorithm -> correct with goodjob text (no driller) -> same case again on a different visit, no new case page, doesn't display picker, doesn't display good job text": {
          "inputRequiredError": "input required",
          "invalidTurnableError": "The turnable A is invalid. We expected something like U, Rw, r, x or M:U B A~",
          "invalidTurnLengthError": "The turn length 4 is invalid. Only lengths allowed are 2 and 3:U4~",
          "repeatedTurnableError": "You repeated a turnable twice in a row. Try combining the two into one, such as U2 U becoming U':U2U~",
          "wideMoveStylesMixedError": "You have mixed different types of wide moves. The turnable using a second style was Rw. To solve this pick one style and use it throughout the algorithm:u B R~w~",
          "turnWouldWorkWithoutInterruptionError -- space between": "An invalid turn was found. The turn would become valid if the underlined interruption was removed:U ~'",
          "apostropheWrongSideOfLengthError": "Turn is invalid. It would be valid if you swapped the apostrophe to the other side of the length though:U'~2",
          "turnWouldWorkWithoutInterruptionError -- parenthesis between": "An invalid turn was found. The turn would become valid if the underlined interruption was removed:(U)~'",
          "unclosedParenthesisError": "There is an unclosed parenthesis, add a closing parenthesis to fix this:U (~ B F' D2",
          "unmatchedClosingParenthesisError": "There is an unmatched closing parenthesis, remove it or add an opening parenthesis to fix this:U B F' )~ D2",
          "nestedParenthesesError": "There are nested parentheses in this algorithm which is not allowed. Remove them to fix it:( U (~B F') ) D2",
          "invalidSymbolError": "The symbol % is never valid anywhere in an algorithm, remove it to fix this error:( U B F') %~ D2",
          "algorithmDoesntMatchCaseError": "The algorithm doesn't solve the case. Try double checking it from the source"
        }
      }
    }
  },
  "__version": "10.8.0"
}
