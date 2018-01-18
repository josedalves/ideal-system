# Package

version       = "0.1.0"
author        = "josedalves"
description   = "File rotation script"
license       = "MIT"

# Dependencies

requires "nim >= 0.17.2"
skipDirs = @["tests"]
bin = @["rotate"]


task clean, "Clean source tree":
  rmDir("nimcache")
  rmFile("rotate")
  rmDir("tests/nimcache")
  rmFile("tests/tests")


task buildarm, "Build arm":
  --cpu:arm
  --os:linux
  setCommand("compile", "rotate.nim")

