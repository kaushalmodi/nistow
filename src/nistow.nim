# nistow
# Copyright xmonader
# Stow alternative in nim to manage dotfiles.


import os, strutils, strformat
type
  LinkInfo = tuple[original: string, dest: string]

proc getLinkableFiles(appPath: string, dest: string): seq[LinkInfo] =

    # collects the linkable files in a certain app.

    # appPath: application's dotfiles directory
    #     we expect dir to have the hierarchy.
    #     i3
    #     `-- .config
    #         `-- i3
    #         `-- config

    # dest: destination of the link files

  var appPath = expandTilde(appPath)
  if not dirExists(appPath):
    raise newException(ValueError, fmt("App path {appPath} doesn't exist."))
  var dest = expandTilde(dest)
  var linkables = newSeq[LinkInfo]()
  # Walk through all files (not symbolic links) recursively in appPath.
  for filepath in walkDirRec(appPath, yieldFilter={pcFile}):
    let linkpath = filepath.replace(appPath, dest)
        # remove leading /
    var linkInfo : LinkInfo = (original: filepath, dest: linkpath)
    linkables.add(linkInfo)
  return linkables

proc stow(linkables: seq[LinkInfo], simulate: bool=true, verbose: bool=true, force: bool=false) =
    # Creates symbolic links and related directories

    # linkables is a list of tuples (filepath, linkpath) : List[Tuple[file_path, link_path]]
    # simulate does simulation with no effect on the filesystem: bool
    # verbose shows log messages: bool

  for linkinfo in linkables:
    let (filepath, linkpath) = linkinfo
    if simulate:
      echo(fmt("Will link {filepath} -> {linkpath}"))
    elif verbose:
      echo(fmt("Linking {filepath} -> {linkpath}"))

    if not simulate:
      createDir(parentDir(linkpath))
      if not fileExists(linkpath):
        createSymlink(filepath, linkpath)
      else:
        if force:
          removeFile(linkpath)
          createSymlink(filepath, linkpath)
        else:
          if verbose:
            echo(fmt("  Skipping linking as that link already exists."))

proc nistow*(simulate: bool=false, verbose: bool=false, force: bool=false,
             app: string, dest :string=getHomeDir()) =
  ##Stow (Manage your dotfiles easily)

  try:
    stow(getLinkableFiles(appPath=app, dest=dest), simulate=simulate, verbose=verbose, force=force)
  except ValueError:
    echo "Error happened: " & getCurrentExceptionMsg()

when isMainModule:
  import cligen

  # https://github.com/c-blake/cligen/issues/83#issuecomment-444951772
  proc mergeParams(cmdNames: seq[string], cmdLine=commandLineParams()): seq[string] =
    result = cmdLine
    if cmdLine.len == 0:
      result = @["--help"]

  dispatch(nistow,
           version = ("version", "0.1.0"))
