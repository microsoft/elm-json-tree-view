# Elm JSON Tree View

This library provides a JSON tree view. You feed it JSON, and it transforms it into
interactive HTML.

Features:

  - show JSON as a tree of HTML
  - expand/collapse nodes in the tree
  - expand/collapse the entire tree
  - select scalar values in the tree
  
## Usage

See the [docs](http://package.elm-lang.org/packages/Microsoft/elm-json-tree-view/latest) 
or look at the example app in the `example` directory.

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

Note that the above example is only meant to give you a taste. It does not wire everything
up, which means that some things will be broken (i.e. expand/collapse). See the 
[docs](http://package.elm-lang.org/packages/Microsoft/elm-json-tree-view/latest) and
the example app for more details. 

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to
agree to a Contributor License Agreement (CLA) declaring that you have the right to,
and actually do, grant us the rights to use your contribution. For details, visit
https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need
to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the
instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License

MIT