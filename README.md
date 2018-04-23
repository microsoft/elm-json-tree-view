# Elm JSON Tree View

This library provides a JSON tree view. You feed it JSON, and it transforms it into interactive HTML.

Try the [online demo](https://microsoft.github.io/elm-json-tree-view/example/index.html) ([source](https://github.com/Microsoft/elm-json-tree-view/blob/master/example/src/Main.elm))

Features:

  - show JSON as a tree of HTML
  - expand/collapse nodes in the tree
  - expand/collapse the entire tree
  - select scalar values in the tree
  
## Usage

See the [docs](http://package.elm-lang.org/packages/Microsoft/elm-json-tree-view/latest) or look at the example app's [source code](https://github.com/Microsoft/elm-json-tree-view/blob/master/example/src/Main.elm).

But if you really insist on something super simple, here goes:
```elm
import JsonTree
import Html exposing (text)

main =
    JsonTree.parseString """[1,2,3]"""
        |> Result.map (\tree -> JsonTree.view tree config JsonTree.defaultState)
        |> Result.withDefault (text "Failed to parse JSON")

config = { onSelect = Nothing, toMsg = always () }
```

Note that the above example is only meant to give you a taste. It does not wire everything up, which means that some things will be broken (i.e. expand/collapse). See the [docs](http://package.elm-lang.org/packages/Microsoft/elm-json-tree-view/latest) and the example app for more details. 

## Thanks

UI based on Gildas Lormeau's [JSONView](https://github.com/gildas-lormeau/JSONView-for-Chrome) Chrome extension.