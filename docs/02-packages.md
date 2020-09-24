# Add-On Packages

## Why can't I compile packages from source?

If you are a Windows user, you are missing RTools. See [this FAQ](installing-r-and-rstudio.html#rtools)

If you are a Mac user, [there might be something wrong with your installation](#xcrun).

*October 24, 2019. -DB*

## When I try to compile, I get the following error message: {#xcrun}

**`xcrun: error: invalid active developer path`**

Solution:

* Open up the Terminal App. (Application>Utilities or you can use the Terminal tab in RStudio, next to the console).
* At the command line in the Terminal type the following line.

```
xcode-select --install
```

*October 24, 2019. -DB*
