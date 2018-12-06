# Package

version       = "0.1.0"
author        = "xmonader"
description   = "Stow alternative in nim to manage dotfiles."
license       = "MIT"
srcDir        = "src"
bin = @["nistow"]
# Dependencies

requires "nim >= 0.19.0", "cligen#head"
