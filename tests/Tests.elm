module Tests exposing (..)

import Dict
import Expect exposing (Expectation)
import Json.Encode as Encode
import JsonTree exposing (Node, TaggedValue(..))
import Test exposing (Test, describe, only, test)


suite : Test
suite =
    describe "JsonTree parsing"
        [ test "parses strings" <|
            \_ ->
                JsonTree.parseValue (Encode.string "hi")
                    |> Expect.equal (Ok (Node (TString "hi") ""))
        , test "parses numbers" <|
            \_ ->
                JsonTree.parseValue (Encode.float 3.14)
                    |> Expect.equal (Ok (Node (TFloat 3.14) ""))
        , test "parses bools" <|
            \_ ->
                JsonTree.parseValue (Encode.bool True)
                    |> Expect.equal (Ok (Node (TBool True) ""))
        , test "parses null" <|
            \_ ->
                JsonTree.parseValue Encode.null
                    |> Expect.equal (Ok (Node TNull ""))
        , test "parses lists" <|
            \_ ->
                JsonTree.parseValue (Encode.list Encode.float [ 1, 2, 3 ])
                    |> Expect.equal
                        (Ok
                            { value =
                                TList
                                    [ Node (TFloat 1) "[0]"
                                    , Node (TFloat 2) "[1]"
                                    , Node (TFloat 3) "[2]"
                                    ]
                            , keyPath = ""
                            }
                        )
        , test "parses dictionaries" <|
            \_ ->
                JsonTree.parseValue
                    (Encode.object
                        [ ( "age", Encode.float 42 )
                        , ( "name", Encode.string "Arnold" )
                        ]
                    )
                    |> Expect.equal
                        (Ok
                            { value =
                                TDict
                                    (Dict.fromList
                                        [ ( "age", { value = TFloat 42, keyPath = ".age" } )
                                        , ( "name", { value = TString "Arnold", keyPath = ".name" } )
                                        ]
                                    )
                            , keyPath = ""
                            }
                        )
        , test "parses lists of dictionaries" <|
            \_ ->
                JsonTree.parseValue
                    (Encode.list Encode.object
                        [ [ ( "age", Encode.float 42 )
                          , ( "name", Encode.string "Arnold" )
                          ]
                        , [ ( "age", Encode.float 99 )
                          , ( "name", Encode.string "Lou" )
                          ]
                        ]
                    )
                    |> Expect.equal
                        (Ok
                            { value =
                                TList
                                    [ { value =
                                            TDict
                                                (Dict.fromList
                                                    [ ( "age", { value = TFloat 42, keyPath = "[0].age" } )
                                                    , ( "name", { value = TString "Arnold", keyPath = "[0].name" } )
                                                    ]
                                                )
                                      , keyPath = "[0]"
                                      }
                                    , { value =
                                            TDict
                                                (Dict.fromList
                                                    [ ( "age", { value = TFloat 99, keyPath = "[1].age" } )
                                                    , ( "name", { value = TString "Lou", keyPath = "[1].name" } )
                                                    ]
                                                )
                                      , keyPath = "[1]"
                                      }
                                    ]
                            , keyPath = ""
                            }
                        )
        , test "parses dictionary of lists" <|
            \_ ->
                JsonTree.parseValue
                    (Encode.object
                        [ ( "names", Encode.list Encode.string [ "Arnold", "Lou" ] ) ]
                    )
                    |> Expect.equal
                        (Ok
                            { value =
                                TDict
                                    (Dict.fromList
                                        [ ( "names"
                                          , { value =
                                                TList
                                                    [ Node (TString "Arnold") ".names[0]"
                                                    , Node (TString "Lou") ".names[1]"
                                                    ]
                                            , keyPath = ".names"
                                            }
                                          )
                                        ]
                                    )
                            , keyPath = ""
                            }
                        )
        ]
