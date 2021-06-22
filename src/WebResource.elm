module WebResource exposing (WebResource(..), getUrl)

import PLL exposing (PLL)


type WebResource
    = TwoSidedPllRecognitionGuide
    | PLLAlgorithmsResource
    | HomeGripExplanation
    | PLLExplanation
    | AUFExplanation
    | AlgDBPLL PLL
    | ExpertGuidancePLL PLL


getUrl : WebResource -> String
getUrl resource =
    case resource of
        TwoSidedPllRecognitionGuide ->
            "http://cubing.pt/wp-content/uploads/2017/03/pll2side-20140531.pdf"

        PLLExplanation ->
            "https://www.speedsolving.com/wiki/index.php/PLL"

        HomeGripExplanation ->
            "https://www.quora.com/How-should-a-speedcuber-hold-and-grip-the-cube/answer/Sukant-Koul-1"

        AUFExplanation ->
            "https://www.speedsolving.com/wiki/index.php/AUF"

        PLLAlgorithmsResource ->
            "https://www.youtube.com/watch?v=JvqGU0UZPcE"

        AlgDBPLL pll ->
            "http://algdb.net/puzzle/333/pll/" ++ String.toLower (PLL.getLetters pll)

        ExpertGuidancePLL pll ->
            let
                timestamp =
                    case pll of
                        PLL.Ua ->
                            18

                        PLL.Ub ->
                            43

                        PLL.H ->
                            60 + 10

                        PLL.Z ->
                            60 + 24

                        PLL.Aa ->
                            60 + 42

                        PLL.Ab ->
                            2 * 60 + 6

                        PLL.E ->
                            2 * 60 + 30

                        PLL.T ->
                            2 * 60 + 50

                        PLL.F ->
                            3 * 60 + 6

                        PLL.Jb ->
                            3 * 60 + 26

                        PLL.Ja ->
                            3 * 60 + 43

                        PLL.Ra ->
                            3 * 60 + 57

                        PLL.Rb ->
                            4 * 60 + 15

                        PLL.Y ->
                            4 * 60 + 35

                        PLL.V ->
                            4 * 60 + 53

                        PLL.Na ->
                            5 * 60 + 13

                        PLL.Nb ->
                            5 * 60 + 35

                        PLL.Ga ->
                            6 * 60 + 2

                        PLL.Gb ->
                            6 * 60 + 18

                        PLL.Gc ->
                            6 * 60 + 37

                        PLL.Gd ->
                            7 * 60 + 13
            in
            "https://youtu.be/9r_HqG4zSbk?t=" ++ String.fromInt timestamp
