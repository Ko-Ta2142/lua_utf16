# lua unicode16 to utf8
unicode(16le/be)からutf8へ変換します。  
bomがあれば自動判別します。

convert unicode to utf8.
bom auto detect.

## sample

```lua
-- exists bom
local s16 = [unicode string array byte]
local s8 = misc_utf16.utf16to8(s16)

-- no bom
local s16 = [unicode string array byte]
local s8 = misc_utf16.utf16to8(s16,true) --little edinet
```