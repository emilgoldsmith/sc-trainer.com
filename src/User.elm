module User exposing (User, new)

import Algorithm exposing (Algorithm)


type User
    = User UsersCurrentPLLAlgorithms


type alias UsersCurrentPLLAlgorithms =
    { -- Edges only
      h : Maybe Algorithm
    , ua : Maybe Algorithm
    , ub : Maybe Algorithm
    , z : Maybe Algorithm

    -- Corners only
    , aa : Maybe Algorithm
    , ab : Maybe Algorithm
    , e : Maybe Algorithm

    -- Edges And Corners
    , f : Maybe Algorithm
    , ga : Maybe Algorithm
    , gb : Maybe Algorithm
    , gc : Maybe Algorithm
    , gd : Maybe Algorithm
    , ja : Maybe Algorithm
    , jb : Maybe Algorithm
    , na : Maybe Algorithm
    , nb : Maybe Algorithm
    , ra : Maybe Algorithm
    , rb : Maybe Algorithm
    , t : Maybe Algorithm
    , v : Maybe Algorithm
    , y : Maybe Algorithm
    }


new : User
new =
    User
        { h = Nothing
        , ua = Nothing
        , ub = Nothing
        , z = Nothing
        , aa = Nothing
        , ab = Nothing
        , e = Nothing
        , f = Nothing
        , ga = Nothing
        , gb = Nothing
        , gc = Nothing
        , gd = Nothing
        , ja = Nothing
        , jb = Nothing
        , na = Nothing
        , nb = Nothing
        , ra = Nothing
        , rb = Nothing
        , t = Nothing
        , v = Nothing
        , y = Nothing
        }
