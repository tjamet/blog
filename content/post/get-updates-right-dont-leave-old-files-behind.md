---
title: "Get your updates right, but don't leave old files behind"
date: 2017-07-14
---
During development you often update the deliverables with the latest version of
your code. But don't forget what you removed. Here is how you can do it with
Make.

## What is Make?

> GNU Make is a tool which controls the generation of executables and other
non-source files of a program from the program's source files. Make gets its
knowledge of how to build your program from a file called the makefile, which
lists each of the non-source files and how to compute it from other files. When
you write a program, you should write a makefile for it, so that it is possible
to use Make to build and install the program.
([Source](https://www.gnu.org/software/make/))

With awareness of both how to generate a file (the **target)** and what that
file needs (its **dependencies)**, `make` can help save valuable time and
prevent you from having to rebuild a target whose dependencies did not change
since the last build. Although `make` is great at saving time, it takes some
expertise to manage efficient work during code cleanup phases.

## The make `clean` target

Most projects come with a `make clean` target providing a developer with the
ability to remove any non-source file the make program generated. Even the
[reference itself](https://www.gnu.org/software/make/manual/html_node/Cleanup.html) instructs
how to clean build output:

```make
.PHONY : clean
clean :
        -rm edit $(objects)
```

The whole `Makefile` might be close to:

```make
TARGETS=bin/prog1

all: ${TARGETS}

bin/%:
    mkdir -p bin
    echo $@ > $@

clean:
    - rm ${TARGETS}
```

It is then possible to run:

```sh
$> make
mkdir -p bin
echo bin/prog1 > bin/prog1
$> ls bin
prog1
$> make
make: Nothing to be done for `all'.
$> make clean
rm bin/prog1
$> ls bin
$> make
mkdir -p bin
echo bin/prog1 > bin/prog1
$> ls bin
prog1
```

It also works when adding targets:

```sh
$> make TARGETS='bin/prog1 bin/prog2 bin/prog3' # this simulates the addition of 2 new targets in Makefile
mkdir -p bin
echo bin/prog2 > bin/prog2
mkdir -p bin
echo bin/prog3 > bin/prog3
$> ls bin
prog1 prog2 prog3
```

However, when targets are removed (e.g. when you are moving outside of a feature
branch adding a program), make won't be able to clean your working directory
properly:

```sh
$> make clean
rm bin/prog1
$> ls bin
prog2 prog3
```

## Improving the `make clean` target

As we noticed, our current implementation of the build is not reproducible,
hence some files in the bin are still available but not rebuildable after a git
clone. To solve this issue, the first approach would be to clean the whole
repository after each checkout with `git clean -dxf` . However this can be very
inefficient if your build time is high. Another option is to add a simple script
in charge of cleaning previously buildable targets (`./cleanup.sh`):

```sh
#!/bin/bash

if [ -f .targets ] ; then
    for target in $(cat .targets); do
        if [[ "${TARGETS}" != *"${target}"* ]]; then
            if [ -e ${target} ]; then
                echo "Removing dangling target ${target}" >&2
                rm ${target}
            fi
        fi
    done
fi
echo "${TARGETS}"  > .targets
```

integrate it in the makefile:

```make
TARGETS=bin/prog1

$(shell env TARGETS="${TARGETS}" ./cleanup.sh >&2)

all: ${TARGETS}
.PHONY: clean

bin/%:
    mkdir -p bin
    echo "#/bin/bash" > $@
    echo "echo $@" > $@
    chmod +x $@

clean:
    - rm ${TARGETS}
```

and test the changes:

```sh
$> make TARGETS='bin/prog1 bin/prog2 bin/prog3'
mkdir -p bin
echo "#/bin/bash" > bin/prog2
echo "echo bin/prog2" > bin/prog2
chmod +x bin/prog2
mkdir -p bin
echo "#/bin/bash" > bin/prog3
echo "echo bin/prog3" > bin/prog3
chmod +x bin/prog3
$> make clean
Removing dangling target bin/prog2
Removing dangling target bin/prog3
rm bin/prog1
$> ls bin | wc -l
0
```

## Conclusion

Whenever you're considering performing an update either with `make` as described
here, or with `puppet`, `ansible` or other configuration management tools, don't
forget to remove anything redundant to prevent the famous **it works for me**
pattern. You can find the illustrations of this article hosted on GitHub:
[https://github.com/leboncoin/bytes-clean-examples](https://github.com/leboncoin/bytes-clean-examples)


Re-post from: <http://bytes.schibsted.com/get-updates-right-dont-leave-old-files-behind/>
