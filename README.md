# Rotate - Rotate a file

This is a simple, standalone utility that performs file rotation.

# Requirements

* nim >= 0.17.2

# Building

To build, cd into the project directory and type

```
    nimble build
```

A binary called "rotate" will be created.

Some tests are included with this project. To run the tests, cd into the
project directory and type:

```
    nimble test
```

# Invocation

```
  rotate [-n num] [-v] [-d] [-h] <file>
```

Required arguments:
* file: The file to rotate

Optional arguments:
* -n=num: number of backups to keep.
* -h: Print usage.

# Examples

No limits:

```
$ ls
rotate
$ for ((n=0;n<10;n++)); do touch foo; ./rotate foo; done
$ ls
foo.1  foo.10  foo.2  foo.3  foo.4  foo.5  foo.6  foo.7  foo.8  foo.9  rotate
```

Limit of 5 backups:

```
$ ls
rotate
$ for ((n=0;n<10;n++)); do touch foo; ./rotate -n=5 foo; done
$ ls
foo.1  foo.2  foo.3  foo.4  foo.5  rotate
```

# TODO

* Proper handling of short options (currently they have to be specified as -x=foo)
* Allow specifying the backup format. Currently the only format supported is "foo.n", where n is a number.
* Better error handling and recovery. For example, if the "move" fails for any reason (say, network failure) we lose data. BAD!
* Dry run mode.

# Alternatives

### logrotate

The logrotate daemon is the canonical way to rotate logs, though
it can also be used for the purpose of rotating any file. However, it has the
disadvantage of being complex and hard to use as a standalone tool, since you
have to create and maintain a configuration file, and manually invoke
`logrotate your_config_file`.

### mv

mv can be used to create backups prior to moving with the "--backup" option,
but this option is underwhelming. There's no way to specify a limit nor the
format (rotate here doesn't let you either, but it will eventually allow you to
;))

