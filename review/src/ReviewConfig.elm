module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Docs.ReviewAtDocs
import Docs.ReviewLinksAndSections
import Docs.UpToDateReadmeLinks
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDuplicatePorts
import NoEtaReducibleLambdas
import NoExposingEverything
import NoImportingEverything
import NoMissingSubscriptionsCall
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoPrematureLetComputation
import NoRecordAliasConstructor
import NoRecursiveUpdate
import NoRedundantConcat
import NoRedundantCons
import NoSimpleLetBody
import NoUnapprovedLicense
import NoUnoptimizedRecursion
import NoUnsafePorts
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUselessSubscriptions
import Review.Rule as Rule exposing (Rule)
import Simplify
import UseMemoizedLazyLambda


config : List Rule
config =
    [ Docs.ReviewAtDocs.rule
    , Docs.ReviewLinksAndSections.rule
    , Docs.UpToDateReadmeLinks.rule
    , NoConfusingPrefixOperator.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoExposingEverything.rule
    , NoImportingEverything.rule [ "Element", "Test" ]
    , NoMissingTypeAnnotation.rule
    , NoMissingTypeAnnotationInLetIn.rule
    , NoMissingTypeExpose.rule
    , NoSimpleLetBody.rule
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
    , Simplify.rule Simplify.defaults
    , NoUnoptimizedRecursion.rule (NoUnoptimizedRecursion.optOutWithComment "IGNORE TCO")
    , NoUnapprovedLicense.rule
        { allowed = [ "BSD-3-Clause", "MIT" ]
        , forbidden = [ "GPL-3.0-only", "GPL-3.0-or-later" ]
        }
    , NoMissingSubscriptionsCall.rule
    , NoRecursiveUpdate.rule
    , NoUselessSubscriptions.rule
    , NoEtaReducibleLambdas.rule
        { lambdaReduceStrategy = NoEtaReducibleLambdas.AlwaysRemoveLambdaWhenPossible
        , argumentNamePredicate = always True
        }
    , NoRecordAliasConstructor.rule
    , UseMemoizedLazyLambda.rule
    , NoRedundantConcat.rule
    , NoRedundantCons.rule
    , NoDuplicatePorts.rule
    , NoUnsafePorts.rule NoUnsafePorts.any
    ]
        -- This is the temporary file that our elm-review.sh script generates to avoid unused dependency errors
        |> List.map (Rule.ignoreErrorsForFiles [ "src/Temporary.elm" ])
