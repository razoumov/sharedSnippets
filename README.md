## Scripts for DAR (= Disk ARchive) archiving and backup utility

Using [dar](http://dar.linux.free.fr) would be much easier if you did not have to memorize and specify all the flags and
the right syntax on the command line. In the script `dar.sh` we provide several Bash functions for easy backup. Please
note that these functions assume that you are below your quota (so you can write files!), have read and write
permissions, i.e. all the common-sense assumptions. It is your job to ensure that this is the case, and that dar
archived/restored your files correctly before you delete the originals. In other words, please test everything before
including these functions into your workflow.

### Limiting the number of files in each slice with `multidar`

Paste the function `multidar()` into your shell, or save its definition into your $HOME/.bashrc file and then enable it
with `source ~/.bashrc`.

Now, running the command without arguments will show you the syntax:

```sh
$ multidar
Usage: multidar sourceDirectory maxNumberOfFilesPerArchive
```

Let's assume that we have 1000 files inside test. Running the command

```sh
$ multidar test 300
```

will produce four archives, each with its own basename and no more than 300 files inside. To restore from these
archives, use a Bash loop:

```sh
$ for f in test-aa{a..d}
  do
      dar -R restore/ -O -w -x $f
  done
```

### Backup

The function `backup()` provides an easy way to back up your directories. You need to define the four variables at the top:

- `BREF` stores the absolute path of the parent directory (containing all subdirectories and files to archive)
- `BSRC` stores a relative (to BREF) list of subdirectories and files to archive; BSRC cannot be an absolute path
- `BDEST` is the backup destination
- `BTAG` will form the root of the backup basename

To create the full backup `all0.*.dar`, type

```sh
$ backup 0
```

To create the first incremental backup all1.*.dar, type

```sh
$ backup 1
```

To create the second incremental backup all2.*.dar, type

```sh
$ backup 2
```

and so on. To see all backups, type

```sh
$ backup show
```

If your current backup exceeds 5GB, more than one slice will be created.

If you have too many incremental backups, you can always create a lower-numbered backup, e.g.

```sh
$ backup 1
```

will overwrite the first incremental backup and will remove all higher-numbered backups.

### Restore from backup

The function `restore()` will help you restore your backup. Similar to the previous function, you need to define these
variables:

- `BSRC` is the backup directory
- `BTAG` is the root of the backup basename
- `BDEST` is the directory into which you are restoring

Search for a file `test999` inside your backups with:

```sh
$ restore -l test999
```

This will scan both the full backup and all incremental backups. To extract this file, you can specify the backup number
and the full path of the file as it appears in the archive, e.g.

```sh
$ restore -n 2 test/test999
```

However, this will not necessarily restore the file. This command will only restore the file if it was modified between
backups 1 and 2 and therefore included into backup 2. To restore the file for sure, you have two options: either restore
from the full backup and then from all incremental backups in the chronological order:

```sh
$ restore -n 0 test/test999
$ restore -n 1 test/test999
$ restore -n 2 test/test999
...
```

or use the -x flag:

```sh
$ restore -x test/test999
```

This last command will automatically go through all backups in the right order. To restore the entire directory, simply
type:

```sh
$ restore -x test
```

Note that `restore()` does not accept Unix wild masks.

### Symmetric encryption

To encrypt your backup, uncomment the line

```sh
#FLAGS+=(-K aes:)   # add encryption
```

in `backup()` function. Then dar will ask for a separate password (and confirmation) for each new backup, and the
password for the reference (old) backup. When restoring, you will have to provide the password for each backup.
