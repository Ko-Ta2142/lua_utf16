
--utf16 to utf8

misc_utf16={}

misc_utf16.littleendian = true	--current endiant

function misc_utf16.band(v1,v2)
	-- lua 5.2
	return bit32.band(v1,v2)
	-- lua 5.3
	-- return v1 & v2
end

function misc_utf16.rshift(v1,shift)
	-- lua 5.2
	return bit32.rshift(v1,shift)
	-- lua 5.3
	-- return v1 >> shift
end

function misc_utf16.lshift(v1,shift)
	-- lua 5.2
	return bit32.lshift(v1,shift)
	-- lua 5.3
	-- return v1 << shift
end

function misc_utf16.unpack16(buf,pos,littleendian)
	local c1,c2 = string.byte(buf,pos,pos+1)
	if c1 == nil then c1 = 0 end
	if c2 == nil then c2 = 0 end

	if littleendian == misc_utf16.littleendian then
		return misc_utf16.lshift(c1,8) + c2
	else
		return misc_utf16.lshift(c2,8) + c1
	end
end

function misc_utf16.checkbom_le(s)
	if string.len(s)<2 then
		return false
	end
	local c1,c2 = string.byte(s,1,2)
	if c1 ~= 0xFF then return false end
	if c2 ~= 0xFE then return false end
	return true
end

function misc_utf16.checkbom_be(s)
	if string.len(s)<2 then
		return false
	end
	local c1,c2 = string.byte(s,1,2)
	if c1 ~= 0xFE then return false end
	if c2 ~= 0xFF then return false end
	return true
end

function misc_utf16.utf16to8(data,little)
	if little == nil then little = true end
	-- bom check
	local bom = 0
	if misc_utf16.checkbom_le(data) then little = true; bom = 1 end
	if misc_utf16.checkbom_be(data) then little = false; bom = 1 end
	-- bom extract
	if bom == 1 then
		data = string.sub(data,3)
	end
	-- convert
	if little then
		return misc_utf16.convert(data , misc_utf16.utf16le_dec , misc_utf16.utf8_enc)
	else
		return misc_utf16.convert(data , misc_utf16.utf16be_dec , misc_utf16.utf8_enc)
	end
end

function misc_utf16.convert(buf,decoder,encoder)
	local out = {}
	local cp,len,pos
	pos = 1
	len = #buf
	while pos<len + 1 do
		pos, cp = decoder(buf,pos)
		table.insert(out,encoder(cp))
	end
	return table.concat(out)
end

function misc_utf16.utf16le_dec(buf,pos)
	local cp = misc_utf16.unpack16(buf,pos)
	pos = pos + 2	--uchar( 2byte)
	if (cp >= 0xD800) and (cp <= 0xDFFF) then
		local high = misc_utf16.lshift( cp - 0xD800,10 )
		cp = misc_utf16.unpack16(buf,pos)
		pos = pos + 2	--uchar( 2byte)
		cp = 0x10000 + high + cp - 0xDC00
	end
	return pos, cp
end

function misc_utf16.utf16be_dec(buf,pos)
	local cp = misc_utf16.unpack16(buf,pos)
	pos = pos + 2	--uchar( 2byte)
	if (cp >= 0xD800)and(cp <= 0xDFFF) then
		local high = misc_utf16.lshift( cp - 0xD800,10 )
		cp = misc_utf16.unpack16(buf,pos)
		pos = pos + 2	--uchar( 2byte)
		 cp = 0x10000 + high + cp - 0xDC00
	end
	return pos, cp
end

function misc_utf16.utf8_enc(cp)
	local shift,mask
	if cp <= 0x7F then
		return string.char(cp)
	elseif cp <= 0x7FF then		-- 2byte = 0xC0,xxxx
		shift = 6
		mask = 0xC0
	elseif cp <= 0xFFFF then	-- 3bytr = 0xE0,xxxx,xxxx
		shift = 12
		mask = 0xE0
	elseif cp <= 0x10FFFF then	-- 4byte = 0xF0,xxxx,xxxx,xxxx
		shift = 18
		mask = 0xF0
	else
		return nil
	end

	local ss = ""
	local cc
	cc = misc_utf16.rshift(cp,shift)
	cc = misc_utf16.band(cc,0x3F)
	ss = string.char(mask + cc)
	shift = shift - 6
	while shift >= 0 do
		cc = misc_utf16.rshift(cp,shift)
		cc = misc_utf16.band(cc,0x3F)
		ss = ss..string.char(0x80 + cc)
		shift = shift - 6
	end

	return ss
end
