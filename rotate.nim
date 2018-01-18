import os
import ospaths
import parseopt2
import strutils
import algorithm


type

  RotateMode = enum
    RotateModeNumeric   # foo.1, foo.2, ...
    #RotateModeAlpha     # foo.a, foo.b, ... <- Future

  RotateConfig = object
    filename : string
    maxRotations : int
    dryRun : bool
    verbose : bool
    mode : RotateMode

  RotateStackItem = tuple[src : string, dst : string]

template log(msg : string) = 
  if config.verbose:
    echo msg

template log_error(msg : string) = 
  echo msg

proc rotate_file(config : ref RotateConfig) = 
  let sp = splitPath(config.filename)
  let dirname = sp.head
  let basename = sp.tail

  var
    n = config.maxRotations
    to_move : seq[RotateStackItem] = @[]
    to_delete : seq[string] = @[]
    current : string = config.filename & ".1"

  ## First move
  to_move.add((src : config.filename, dst : current))

  if config.maxRotations <= 0:
    var i = 2
    while existsFile(current):
      var rotname = config.filename & "." & $i
      log "push " & current & " " & rotname
      to_move.add((src : current, dst : rotname))
      current = rotname
      i+=1
  else:
    for i in 2..config.maxRotations:
      var rotname = config.filename & "." & $i
      if existsFile(current):
        log "push " & rotname
        to_move.add((src : current, dst : rotname))
        current = rotname
      else:
        break
  
  for item in to_move.reversed():
    log "Pop: $1" % $item
    if existsFile(item.dst):
      if not tryRemoveFile(item.dst):
        ## TODO: Shred support
        log_error "Failed to remove file $1. Aborting!" % item.dst
        quit 1

    try:
      moveFile(item.src, item.dst)
    except OSError:
      log_error "Failed to move file $1 to $2. Aborting!" % [item.src, item.dst]
      quit 1

proc usage() = 
  #echo "$1 [-n NUM] [-v] [-d] [-h] <file>" % (splitPath(getAppFilename()).tail)
  echo "$1 [-n NUM] [-h] <file>" % (splitPath(getAppFilename()).tail)
  echo "Rotate a file."
  echo ""
  echo "    -n NUM, --n-backups=NUM  Number of backups to keep."
  #echo "    -v,     --verbose          Be more verbose"
  #echo "    -d,     --dry-run          Dry run. Don't actually move or delete any files"
  echo "    -h,     --help             Show this help screen."

proc main() = 
  var expected_args = 1
  var config : ref RotateConfig = new RotateConfig

  config.dryRun = false
  config.verbose = false
  config.mode = RotateModeNumeric
  config.maxRotations = -1

  for kind, key, val in getopt():
    case kind:
      of cmdArgument:
        if expected_args <= 0:
          echo "Error: Invalid number of arguments"
          usage()
          quit(1)
        config.filename = expandFilename(key)
        expected_args -= 1
      of cmdShortOption:
        case key:
          of "n":
            config.maxRotations = parseInt(val)
          of "d":
            config.dryRun = true
          of "v":
            config.verbose = true
          of "h":
            usage()
            quit 0
          else:
            echo "Invalid option: $1" % ("-"&key)
            usage()
            quit(1)
      of cmdLongOption:
        case key:
          of "n-backups":
            config.maxRotations = parseInt(val)
          of "dry-run":
            config.dryRun = true
          of "verbose":
            config.verbose = true
          of "help":
            usage()
            quit 0
          else:
            echo "Invalid option: $1" % ("--"&key)
            usage()
            quit(1)
      of cmdEnd:
        discard

  if expected_args > 0:
    echo "Missing argument"
    usage()
    quit(1)

  rotate_file(config)

main()

