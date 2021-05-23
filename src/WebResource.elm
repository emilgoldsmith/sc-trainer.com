module WebResource exposing (WebResource(..), getUrl)


type WebResource
    = TwoSidedPllRecognitionGuide
    | PLLAlgorithmsResource
    | HomeGripExplanation
    | PLLExplanation
    | AUFExplanation


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
