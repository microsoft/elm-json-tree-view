-- Copyright (c) Microsoft Corporation. All rights reserved.
-- Licensed under the MIT License.

module JsonTree
    exposing
        ( Node
        , TaggedValue(..)
        , KeyPath
        , Config
        , State
        , parseValue
        , parseString
        , view
        , defaultState
        , expandAll
        , collapseToDepth
        )

{-| This library provides a JSON tree view. You feed it JSON, and it transforms it into
interactive HTML.

Features:

  - show JSON as a tree of HTML
  - expand/collapse nodes in the tree
  - expand/collapse the entire tree
  - select scalar values in the tree


# Basic Usage

@docs parseString, parseValue, view


# Types

@docs Config, State, defaultState, Node, TaggedValue, KeyPath


# Expand/Collapse

@docs expandAll, collapseToDepth

-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Html exposing (Attribute, Html, button, div, li, span, text, ul)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import InlineHover exposing (hover)
import Set exposing (Set)


{-| A node in the tree
-}
type alias Node =
    { value : TaggedValue
    , keyPath : KeyPath
    }


{-| A tagged value
-}
type TaggedValue
    = TString String
    | TFloat Float
    | TBool Bool
    | TList (List Node)
    | TDict (Dict String Node)
    | TNull


{-| The path to a piece of data in the tree.
-}
type alias KeyPath =
    String


{-| Parse a JSON value as a tree.
-}
parseValue : Decode.Value -> Result String Node
parseValue json =
    let
        rootKeyPath =
            ""

        decoder =
            Decode.map (annotate rootKeyPath) coreDecoder
    in
        Decode.decodeValue decoder json


{-| Parse a JSON string as a tree.
-}
parseString : String -> Result String Node
parseString string =
    Decode.decodeString Decode.value string
        |> Result.andThen parseValue


coreDecoder : Decoder Node
coreDecoder =
    let
        makeNode v =
            { value = v, keyPath = "" }
    in
        Decode.oneOf
            [ Decode.map (makeNode << TString) Decode.string
            , Decode.map (makeNode << TFloat) Decode.float
            , Decode.map (makeNode << TBool) Decode.bool
            , Decode.map (makeNode << TList) (Decode.list (Decode.lazy (\_ -> coreDecoder)))
            , Decode.map (makeNode << TDict) (Decode.dict (Decode.lazy (\_ -> coreDecoder)))
            , Decode.null (makeNode TNull)
            ]


annotate : String -> Node -> Node
annotate pathSoFar node =
    let
        annotateList index val =
            annotate (pathSoFar ++ "[" ++ toString index ++ "]") val

        annotateDict fieldName val =
            annotate (pathSoFar ++ "." ++ fieldName) val
    in
        case node.value of
            TString _ ->
                { node | keyPath = pathSoFar }

            TFloat _ ->
                { node | keyPath = pathSoFar }

            TBool _ ->
                { node | keyPath = pathSoFar }

            TNull ->
                { node | keyPath = pathSoFar }

            TList children ->
                { node
                    | keyPath = pathSoFar
                    , value = TList (List.indexedMap annotateList children)
                }

            TDict dict ->
                { node
                    | keyPath = pathSoFar
                    , value = TDict (Dict.map annotateDict dict)
                }



-- VIEW


{-| Show a JSON tree.
-}
view : Node -> Config msg -> State -> Html msg
view node config state =
    div
        [ style css.root ]
        (viewNodeInternal 0 config node state)


{-| Configuration of the JSON tree view. It describes how to map events in the tree view
into events that your app understands.

Since the `Config` contains functions, it should never be held in your model. It should
only appear in your `view` code.

`onSelect` should be set to `Nothing` for most users. However, if you want to make the
tree's leaf nodes selectable, you should provide a function that takes the selected `KeyPath`
and acts on it.

`toMsg` provides an updated `State` to your application which you should use to overwrite
the previous state.

-}
type alias Config msg =
    { onSelect : Maybe (KeyPath -> msg)
    , toMsg : State -> msg
    }


{-| The state of the JSON tree view. Note that this is just the runtime state needed to
implement things like expand/collapse--it is *not* the tree data itself.

You should store the current state in your model.

-}
type State
    = State (Set KeyPath)


{-| Initial state where the entire tree is fully expanded.
-}
defaultState : State
defaultState =
    stateFullyExpanded


{-| Collapses any nodes deeper than `maxDepth`.
-}
collapseToDepth : Int -> Node -> State -> State
collapseToDepth maxDepth tree _ =
    collapseToDepthHelp maxDepth 0 tree stateFullyExpanded


collapseToDepthHelp : Int -> Int -> Node -> State -> State
collapseToDepthHelp maxDepth currentDepth node state =
    let
        descend children =
            List.foldl
                (collapseToDepthHelp maxDepth (currentDepth + 1))
                (if currentDepth >= maxDepth then
                    collapse node.keyPath state
                 else
                    state
                )
                children
    in
        case node.value of
            TString str ->
                state

            TFloat x ->
                state

            TBool bool ->
                state

            TNull ->
                state

            TList nodes ->
                descend nodes

            TDict dict ->
                descend (Dict.values dict)


{-| Expand all nodes
-}
expandAll : State -> State
expandAll _ =
    stateFullyExpanded


stateFullyExpanded : State
stateFullyExpanded =
    State (Set.fromList [])



-- EXPAND/COLLAPSE --


lazyStateChangeOnClick : (() -> State) -> (State -> msg) -> Attribute msg
lazyStateChangeOnClick newStateThunk toMsg =
    {- This is semantically equivalent to `onClick (toMsg newState)`, but defers the computation
       of the new `State` until the event is delivered/decoded.
    -}
    let
        force =
            \thunk -> thunk ()
    in
        newStateThunk
            |> Decode.succeed
            |> Decode.map (force >> toMsg)
            |> Html.Events.on "click"


expand : KeyPath -> State -> State
expand keyPath ((State hiddenPaths) as state) =
    State (Set.remove keyPath hiddenPaths)


collapse : KeyPath -> State -> State
collapse keyPath ((State hiddenPaths) as state) =
    State (Set.insert keyPath hiddenPaths)


isCollapsed : KeyPath -> State -> Bool
isCollapsed keyPath ((State hiddenPaths) as state) =
    Set.member keyPath hiddenPaths


viewNodeInternal : Int -> Config msg -> Node -> State -> List (Html msg)
viewNodeInternal depth config node state =
    case node.value of
        TString str ->
            viewScalar css.string ("\"" ++ str ++ "\"") node config

        TFloat x ->
            viewScalar css.number (toString x) node config

        TBool bool ->
            viewScalar css.bool (toString bool) node config

        TNull ->
            viewScalar css.null "null" node config

        TList nodes ->
            viewArray depth nodes node.keyPath config state

        TDict dict ->
            viewDict depth dict node.keyPath config state


viewScalar : List ( String, String ) -> String -> Node -> Config msg -> List (Html msg)
viewScalar someCss str node config =
    List.singleton <|
        case config.onSelect of
            Just onSelect ->
                hover css.selectable
                    span
                    [ style someCss
                    , id node.keyPath
                    , onClick (onSelect node.keyPath)
                    ]
                    [ text str ]

            Nothing ->
                span
                    [ style someCss
                    , id node.keyPath
                    ]
                    [ text str ]


viewCollapser : Int -> Config msg -> (() -> State) -> String -> Html msg
viewCollapser depth config newStateThunk displayText =
    if depth == 0 then
        text ""
    else
        span
            [ style css.collapser
            , lazyStateChangeOnClick newStateThunk config.toMsg
            ]
            [ text displayText ]


viewExpandButton : Int -> KeyPath -> Config msg -> State -> Html msg
viewExpandButton depth keyPath config state =
    viewCollapser depth config (\_ -> expand keyPath state) "+"


viewCollapseButton : Int -> KeyPath -> Config msg -> State -> Html msg
viewCollapseButton depth keyPath config state =
    viewCollapser depth config (\_ -> collapse keyPath state) "-"


viewArray : Int -> List Node -> KeyPath -> Config msg -> State -> List (Html msg)
viewArray depth nodes keyPath config state =
    let
        innerContent =
            if List.isEmpty nodes then
                []
            else if isCollapsed keyPath state then
                [ viewExpandButton depth keyPath config state
                , text "…"
                ]
            else
                [ viewCollapseButton depth keyPath config state
                , ul
                    [ style css.ul ]
                    (List.map viewListItem nodes)
                ]

        viewListItem node =
            li
                [ style css.li ]
                (List.append (viewNodeInternal (depth + 1) config node state) [ text "," ])
    in
        [ text "[" ] ++ innerContent ++ [ text "]" ]


viewDict : Int -> Dict String Node -> KeyPath -> Config msg -> State -> List (Html msg)
viewDict depth dict keyPath config state =
    let
        innerContent =
            if Dict.isEmpty dict then
                []
            else if isCollapsed keyPath state then
                [ viewExpandButton depth keyPath config state
                , text "…"
                ]
            else
                [ viewCollapseButton depth keyPath config state
                , ul
                    [ style css.ul ]
                    (List.map viewListItem (Dict.toList dict))
                ]

        viewListItem ( fieldName, node ) =
            li
                [ style css.li ]
                ([ span [ style css.fieldName ] [ text fieldName ]
                 , text ": "
                 ]
                    ++ (viewNodeInternal (depth + 1) config node state)
                    ++ [ text "," ]
                )
    in
        [ text "{" ] ++ innerContent ++ [ text "}" ]



-- STYLES


css =
    { root =
        [ ( "font-family", "monospace" )
        , ( "white-space", "pre" )
        ]
    , ul =
        [ ( "list-style-type", "none" )
        , ( "margin-left", "26px" )
        , ( "padding-left", "0px" )
        ]
    , li =
        [ ( "position", "relative" )
        ]
    , collapser =
        [ ( "position", "absolute" )
        , ( "cursor", "pointer" )
        , ( "top", "1px" )
        , ( "left", "-15px" )
        ]
    , fieldName =
        [ ( "font-weight", "bold" )
        ]
    , string =
        [ ( "color", "green" )
        ]
    , number =
        [ ( "color", "blue" )
        ]
    , bool =
        [ ( "color", "firebrick" )
        ]
    , null =
        [ ( "color", "gray" )
        ]
    , selectable =
        [ ( "background-color", "#fafad2" )
        , ( "cursor", "pointer" )
        ]
    }
