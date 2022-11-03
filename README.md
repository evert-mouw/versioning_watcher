_A simple shellscript to create backup copies (versioning) in a watched directory._

### Versioning Watcher script

This shellscript offers simple versioning of files.

You get protection gainst accidental editing errors, by creating
multiple older version of a file (undo). E.g., when you save a file `current.ext`, then a copy named `.current.ext.#@old_version$.1` is created. By default, such backup copies (older versions) are hidden files (you can disable that option) and up to nine copies are stored (you can change the MAX number).

I advise to use this in combination with a filewatcher like fswatch of watchman. Rudimentary support for [watchman](https://facebook.github.io/watchman/) is build-in.

### Example usage

```
mkdir my_new_project
cd my_new_project
versioning_watch.sh watchman .
touch foo.bar
echo foo >> foo.bar
echo bar >> foo.bar
ls -al
cat foo.bar.#@old_version$.2
versioning_watch.sh cleanup .
ls -al
versioning_watch.sh watchman_rm .
cd ..
rm -rf my_new_project
```

### Reference

Arguments (inputs) either:

- one and only one FILENAME to apply versioning to
  (more filenames will be ignored)
- watchman DIRECTORY (fire & forget)
- watchman_rm DIRECTORY (remove watch)
- cleanup DIRECTORY (removes old versions)

Edit the shellscript to change a few options.

### Roadmap / TODO

Hey I like it simple, but you could improve and expand this script any way you like.
I've included a few `TODO` items in the script.

### Copyright

[WTFPL](http://www.wtfpl.net/) – Do What the Fuck You Want to Public License

Evert Mouw, 2022-11-03
