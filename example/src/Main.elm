-- Copyright (c) Microsoft Corporation. All rights reserved.
-- Licensed under the MIT License.


module Main exposing (..)

import Browser
import Json.Decode as Decode
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
    , parseResult : Result Decode.Error JsonTree.Node
    , treeState : JsonTree.State
    , clickToSelectEnabled : Bool
    , selections : List JsonTree.KeyPath
    }


init : Model
init =
    { jsonInput = exampleJsonInput
    , parseResult = JsonTree.parseString exampleJsonInput
    , treeState = JsonTree.defaultState
    , clickToSelectEnabled = False
    , selections = []
    }



---- UPDATE ----


type Msg
    = SetJsonInput String
    | Parse
    | SetTreeViewState JsonTree.State
    | ExpandAll
    | CollapseAll
    | ToggleSelectionMode
    | Selected JsonTree.KeyPath


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetJsonInput string ->
            { model | jsonInput = string }

        Parse ->
            { model | parseResult = JsonTree.parseString model.jsonInput }

        SetTreeViewState state ->
            { model | treeState = state }

        ExpandAll ->
            { model | treeState = JsonTree.expandAll model.treeState }

        CollapseAll ->
            case model.parseResult of
                Ok rootNode ->
                    { model | treeState = JsonTree.collapseToDepth 1 rootNode model.treeState }

                Err _ ->
                    model

        ToggleSelectionMode ->
            { model
                | clickToSelectEnabled = not model.clickToSelectEnabled
                , selections = []
              }

        Selected keyPath ->
            { model | selections = model.selections ++ [ keyPath ] }



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ style "margin" "20px" ]
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
            , style "width" "400px"
            , style "height" "200px"
            , style "font-size" "14px"
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
                pre [] [ text ("Invalid JSON: " ++ Decode.errorToString e)]
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


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }
