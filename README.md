# pattern-matching
Tools that use regex to perform enumeration

## search-filesystem.sh

This script allows you to rapidly search all of the following, searching recursively:

1. filenames
2. contents of text files 
3. text-based contents of `zip` archives
4. text-based contents of `gzip` archives

It's Linux-only.

### Typical Workflow

Clone the repo, then **modify `patterns.txt`**, adding regexes (one per line) for whatever you want to search for. For example:

> All of the matching is case-insensitive, so you can leave that out of your regexes :wink:

```
pass(word|[^a-z0-9])?
id_(rsa|ed25519)
root_cred(ential)?
[0-9a-f]{32}
```

Next, **run the script**. Just choose a base directory to begin recursion from. Optionally, you can also specify:

- What level of **depth** to continue recursion into (default: 2)
  For example, you may only want to search inside the base directory and its subdirectories. For this, you'd specify `max_depth=1`.
- Whether or not you want to do all **modes** of searching (default: 4)
  For example, you may only want to search for matching filenames (mode 1) and matching contents of text files (mode 2), so you'd specify `final_step=2`.
- An alternate file of regexes (default: `./patterns.txt`)
  It's possible you want to use this tool with multiple projects, each with their own set of regexes that you like to use. In that case, just copy `patterns.txt` and modify the contents of the copy.

```bash
# Usage: ./search-filesystem.sh base_directory [max_depth] [final_step] [patterns_file]

# Use the defaults
./search-filesystem.sh /base_dir/to/search

# Search deeper, ignore zip and gzip/targz archives, use alternative file for regexes
./search-filesystem.sh /base_dir/to/search 5 2 my_patterns.txt
```

### Regex Definitions

Regexes can be as simple as you might use for any `grep` call. This script uses *Extended* regex syntax, like `grep -E`. Some of the tools I use within this script cannot process "Perl-Compatible Regular Expressions" (PCREs), so please avoid their usage. See `man pcre2syntax` for more details. In general, avoid this stuff in your `patterns.txt` file:

```
# - \b (word boundaries)
# - Lookaheads/lookbehinds ((?=...), (?<=...), etc.)
# - Non-capturing groups ((?:...))
# - Lazy quantifiers (*?, +?, ??)
# - Complex backreferences (\1, \2, etc.)
# - Test POSIX bracket expressions ([:alnum:], [:digit:], etc.) for environment-specific issues
```



---

> I hope you all get as much use out of this as I do :heart: If you enjoy this repo, please give it a :star:

Enjoy,

:handshake::handshake::handshake::handshake:
@4wayhandshake

