-- Copyright (c) Microsoft Corporation. All rights reserved.
-- Licensed under the MIT License.

module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (checked, class, style, type_, value)
import Html.Events exposing (onCheck, onClick, onInput)
import JsonTree


exampleJsonInput =
    """
{
    "name": "Arnold",
    "age": 70,
    "isStrong": true,
    "knownWeakness": null,
    "nicknames": ["Terminator", "The Governator"],
    "extra": {
           "foo": "bar"
    }
}
"""



---- MODEL ----


type alias Model =
    { jsonInput : String
    , parseResult : Result String JsonTree.Node
    , treeState : JsonTree.State
    , clickToSelectEnabled : Bool
    , selections : List JsonTree.KeyPath
    }


init : ( Model, Cmd Msg )
init =
    ( { jsonInput = exampleJsonInput
      , parseResult = JsonTree.parseString exampleJsonInput
      , treeState = JsonTree.defaultState
      , clickToSelectEnabled = False
      , selections = []
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = SetJsonInput String
    | Parse
    | SetTreeViewState JsonTree.State
    | ExpandAll
    | CollapseAll
    | ToggleSelectionMode
    | Selected JsonTree.KeyPath


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetJsonInput string ->
            ( { model | jsonInput = string }
            , Cmd.none
            )

        Parse ->
            ( { model | parseResult = JsonTree.parseString model.jsonInput }
            , Cmd.none
            )

        SetTreeViewState state ->
            ( { model | treeState = state }
            , Cmd.none
            )

        ExpandAll ->
            ( { model | treeState = JsonTree.expandAll model.treeState }
            , Cmd.none
            )

        CollapseAll ->
            case model.parseResult of
                Ok rootNode ->
                    ( { model | treeState = JsonTree.collapseToDepth 1 rootNode model.treeState }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        ToggleSelectionMode ->
            ( { model
                | clickToSelectEnabled = not model.clickToSelectEnabled
                , selections = []
              }
            , Cmd.none
            )

        Selected keyPath ->
            ( { model | selections = model.selections ++ [ keyPath ] }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "JSON Tree View Example" ]
        , viewInputArea model
        , hr [] []
        , viewJsonTree model
        , if model.clickToSelectEnabled then
            viewSelections model
          else
            text ""
        ]


viewInputArea : Model -> Html Msg
viewInputArea model =
    div []
        [ h3 [] [ text "Raw JSON input:" ]
        , textarea
            [ value model.jsonInput
            , onInput SetJsonInput
            , style
                [ ( "width", "400px" )
                , ( "height", "200px" )
                , ( "font-size", "14px" )
                ]
            ]
            []
        , div [] [ button [ onClick Parse ] [ text "Parse" ] ]
        ]


viewJsonTree : Model -> Html Msg
viewJsonTree model =
    let
        toolbar =
            div []
                [ label []
                    [ input
                        [ type_ "checkbox"
                        , onCheck (always ToggleSelectionMode)
                        , checked model.clickToSelectEnabled
                        ]
                        []
                    , text "Selection Mode"
                    ]
                , button [ onClick ExpandAll ] [ text "Expand All" ]
                , button [ onClick CollapseAll ] [ text "Collapse All" ]
                ]

        config allowSelection =
            { onSelect =
                if allowSelection then
                    Just Selected
                else
                    Nothing
            , toMsg = SetTreeViewState
            }
    in
        div []
            [ h3 [] [ text "JSON Tree View" ]
            , toolbar
            , case model.parseResult of
                Ok rootNode ->
                    JsonTree.view rootNode (config model.clickToSelectEnabled) model.treeState

                Err e ->
                    text ("Invalid JSON: " ++ e)
            ]


viewSelections : Model -> Html Msg
viewSelections model =
    div []
        [ hr [] []
        , h3 [] [ text "Recently selected key-paths" ]
        , if List.isEmpty model.selections then
            text "No selections. Click any scalar value in the JSON tree view above to select it."
          else
            ul [] (List.map (\x -> li [] [ text x ]) model.selections)
        ]



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
