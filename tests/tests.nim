import unittest
import osproc
import os
import strutils
import random
import md5
import sequtils

let CURRENT_DIR = getCurrentDir()
const TESTS_DIR = "tmp"


proc generate_gibberish(size : int = 512) : string = 
  ## Generats a string full of random trash.
  ## The size parameter defines the size of the file.
  result = ""
  randomize()

  for _ in 0..size:
    result = result & $(chr(random(255)))

proc create_gibberish_file(name : string = "foo", size : int = 512) : string = 
  ## Generats a file full of random trash.
  ## The file parameter is the file name
  ## The size parameter defines the size of the file.
  let f = open(name, fmWrite)
  let gibberish = generate_gibberish()
  f.write(gibberish)
  f.close()
  return getMD5(gibberish)

proc compare_md5(name : string, md5 : string) : bool = 
  ## Verify file md5
  ## name is the file to verify
  ## md5 is an md5 string, as returned by "getMD5"
  let f = open(name)
  let data = f.readAll()
  let dmd5 = getMD5(data)
  f.close()
  #echo md5
  #echo dmd5
  return dmd5 == md5

suite "Sanity check":
  ## Sanity check tests. If these fail, something went VERY wrong
  
  setup:
    createDir(TESTS_DIR)
    copyFileWithPermissions("rotate", joinPath(TESTS_DIR, "rotate"))
    setCurrentDir(TESTS_DIR)
  
  teardown:
    setCurrentDir(CURRENT_DIR)
    removeDir(TESTS_DIR)
  
  test "Basic test":
    let prc = osproc.startProcess("rotate")
    check(waitForExit(prc, timeout = 1000) == 1)

  test "-h flag":
    let prc = osproc.startProcess("rotate", args = ["-h"])
    check(waitForExit(prc, timeout = 1000) == 0)

  test "--help flag":
    let prc = osproc.startProcess("rotate", args = ["--help"])
    check(waitForExit(prc, timeout = 1000) == 0)


suite "Basic tests":
  ## Basic functionality tests. Rotate once and so on

  setup:
    createDir(TESTS_DIR)
    copyFileWithPermissions("rotate", joinPath(TESTS_DIR, "rotate"))
    setCurrentDir(TESTS_DIR)
    ## Generate a file with gibberish

  
  teardown:
    setCurrentDir(CURRENT_DIR)
    removeDir(TESTS_DIR)

  test "Single move, no limts":
    let md5 = create_gibberish_file()
    let prc = osproc.startProcess("rotate", args = ["foo"])
    check(waitForExit(prc, timeout = 1000) == 0)
    check(existsFile("foo.1") == true)
    check(compare_md5("foo.1", md5))
    
  test "Single move, no limits, missing file":
    let prc = osproc.startProcess("rotate", args = ["foo"])
    check(waitForExit(prc, timeout = 1000) == 1)

suite "Move tests with existing backups":
  ## Rotate tests with already existing files. We want to verify that files
  ## are not getting clobbered or deleted unreasonably

  setup:
    createDir(TESTS_DIR)
    copyFileWithPermissions("rotate", joinPath(TESTS_DIR, "rotate"))
    setCurrentDir(TESTS_DIR)
  
  teardown:
    setCurrentDir(CURRENT_DIR)
    removeDir(TESTS_DIR)

  test "Single move, multiple existing backups, no limits":
    ## Generate multiple gibberish files
    randomize()

    ## Seq of md5s. Used to verify that the files weren't clobbered
    var md5s : seq[string] = @[]
    var n = random(2..20)
    echo "Creating $1 files" % $n
    md5s.add(create_gibberish_file("foo"))
    for x in 1..n:
      md5s.add(create_gibberish_file("foo." & $(x)))

    let prc = osproc.startProcess("rotate", args = ["foo"])
    check(waitForExit(prc, timeout = 1000) == 0)

    ## Check the md5s
    for x in 1..n+1:
      check(compare_md5("foo." & $x, md5s[x-1]))

  test "Single move, multiple existing backups, limit < nfiles":
    randomize()

    ## Seq of md5s. Used to verify that the files weren't clobbered
    var md5s : seq[string] = @[]
    var n = random(5..20)
    var mn = n - random(1..n)

    echo "Creating $1 files" % $n
    md5s.add(create_gibberish_file("foo"))
    for x in 1..n:
      md5s.add(create_gibberish_file("foo." & $(x)))

    echo "Passing -n=$1" % $mn
    let prc = osproc.startProcess("rotate", args = ["-n=$1" % $mn, "foo"])
    check(waitForExit(prc, timeout = 1000) == 0)

    ## Check the md5s
    for x in 1..mn:
      echo "Checking file $1" % $x
      check(compare_md5("foo." & $x, md5s[x-1]))
    echo "--"
    for x in mn+1..n:
      echo "Checking file $1" % $x
      check(compare_md5("foo." & $x, md5s[x]))

suite "Advanced tests":
  ## All out tests meant to stress the application.

  setup:
    createDir(TESTS_DIR)
    copyFileWithPermissions("rotate", joinPath(TESTS_DIR, "rotate"))
    setCurrentDir(TESTS_DIR)
  
  teardown:
    setCurrentDir(CURRENT_DIR)
    removeDir(TESTS_DIR)

  test "Generate and rotate 100x. No limit.":
    var md5s : seq[string] = @[]
    
    for n in 1..100:
      md5s.add(create_gibberish_file("foo"))
      let prc = osproc.startProcess("rotate", args = ["foo"])
      check(waitForExit(prc, timeout = 1000) == 0)
      for m in 1..n:
        check(compare_md5("foo."& $m, md5s[^m]))

  test "Generate and rotate 100x. Limit = 10.":
    var md5s : seq[string] = @[]
    
    for n in 1..100:
      md5s.add(create_gibberish_file("foo"))
      let prc = osproc.startProcess("rotate", args = ["-n=10", "foo"])
      check(waitForExit(prc, timeout = 1000) == 0)

      if len(md5s) > 10:
        md5s.delete(0, 0)
      
      for m in 1..(min(10, len(md5s))):
        check(compare_md5("foo."& $m, md5s[^m]))

