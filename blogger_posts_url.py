import sys
import re

s = sys.stdin.read()

p = re.compile(
    "<entry"
    ".+?"
    "term=\'http://schemas.google.com/blogger/2008/kind#post\'"
    ".+?"
    "<link rel=\'alternate\' type=\'text/html\' href=\'(.+?)\'")

m = p.search(s)

if m == None:
    sys.exit(1)
else:
    while m != None:
        print m.group(1)
        m = p.search(s, m.end())
    sys.exit(0)
