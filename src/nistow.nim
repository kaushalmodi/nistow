# nistow
# Copyright xmonader
# Stow alternative in nim to manage dotfiles.


import os, strutils, strformat, parseopt
type
  LinkInfo = tuple[original:string, dest:string]

proc getLinkableFiles*(appPath: string, dest: string=expandTilde("~")): seq[LinkInfo] =

    # collects the linkable files in a certain app.

    # appPath: application's dotfiles directory
    #     we expect dir to have the hierarchy.
    #     i3
    #     `-- .config
    #         `-- i3
    #         `-- config

    # dest: destination of the link files : default is the home of user.

  var appPath = expandTilde(appPath)
  if not dirExists(appPath):
    raise newException(ValueError, fmt("App path {appPath} doesn't exist."))
  var linkables = newSeq[LinkInfo]()
  for filepath in walkDirRec(appPath, yieldFilter={pcFile}):
    let linkpath =  filepath.replace(appPath, dest)
        # remove leading /
    var linkInfo : LinkInfo = (original:filepath, dest:linkpath)
    linkables.add(linkInfo)
  return linkables

proc stow(linkables: seq[LinkInfo], simulate: bool=true, verbose: bool=true, force: bool=false) =
    # Creates symoblic links and related directories

    # linkables is a list of tuples (filepath, linkpath) : List[Tuple[file_path, link_path]]
    # simulate does simulation with no effect on the filesystem: bool
    # verbose shows log messages: bool

  for linkinfo in linkables:
    let (filepath, linkpath) = linkinfo
    if verbose:
      echo(fmt("Will link {filepath} -> {linkpath}"))

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
            echo(fmt("Skipping linking {filepath} -> {linkpath}"))

proc writeVersion() =
    echo "Stow version 0.1.0"

proc nistow*(version=false, simulate=false, verbose=false, force=false, app: string, dest="") =
  ##Stow 0.1.0 (Manage your dotfiles easily)

  var dest_local: string

  if version:
    writeVersion()
    quit()

  if dest.isNilOrEmpty():
    dest_local = getHomeDir()
  else:
    dest_local = dest

  try:
    stow(getLinkableFiles(appPath=app, dest=dest_local), simulate=simulate, verbose=verbose, force=force)
  except ValueError:
    echo "Error happened: " & getCurrentExceptionMsg()

when isMainModule:
  import cligen
  # Use dispatchGen to do some initial setup for cligen, but don't run nistow, yet..
  # The mandatoryOverride option allows the absence of any mandatory switch
  # (like --app in this case), if the mandatoryOverride switch --version is present.
  dispatchGen(nistow,
              mandatoryOverride = @["version"])
  # If the user has run the binary without any switches, pass the --help switch
  # automatically to dispatch_nistow.
  # Else, collect the passed switches using commandLineParams() and pass those to
  # dispatch_nistow.
  quit(dispatch_nistow(if paramCount() > 0: commandLineParams() else: @[ "--help" ]))
