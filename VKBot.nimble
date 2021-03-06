# Package

version       = "0.0.1"
author        = "Daniil Yarancev"
description   = "VKBot - command bot for Russian biggest social network - VKontakte"
license       = "GPLv3"
srcDir = "src"
bin = @["vkbot"]
skipFiles = @["nakefile.nim"]
# Dependencies

requires "nim >= 0.16.1"
requires "strfmt"

when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libssl-dev"
  else:
    foreignDep "openssl"
