# Commands

Every command from this project, grouped by task. Paths and file names are placeholders; the commands are the ones I ran.

## Orientation and help

```bash
pwd                      # print the current directory
cd /home/homelab/Documents
cd -                     # jump back to the previous directory
ls                       # list the current directory
ls -1                    # one entry per line
man cat                  # full manual for a command
cat --help               # short usage summary
```

## Directories

```bash
mkdir school
cp -r school project_files
mv project_files school
rm -r school
```

## Files

```bash
touch notes.txt
nano notes.txt           # add content, then Ctrl+X to save and exit
cp notes.txt notes2.txt
mv notes2.txt archive.txt
cat archive.txt          # read the file back
stat archive.txt         # size, timestamps, inode, permissions
```

## Links

```bash
ln -s notes2.txt shortcut.txt   # symbolic link to a file
cp -P shortcut.txt copy.txt     # copy the link itself, not its target
rm copy.txt
echo "User: $(whoami)"; date    # who am I, and the current time
```

## Editing in the terminal

```bash
nano notes.txt           # edit
# Ctrl+X to save and exit
cat notes.txt            # confirm the change
```

## Searching

```bash
# find files
find . -name "*.txt"
locate notes.txt
which python3
whereis ssh
type cd
ls *.txt                 # wildcard match in the current directory

# find text and differences
grep "error" notes.txt
egrep "error|warn" notes.txt
fgrep "literal-string" notes.txt
diff notes.txt notes2.txt
```
