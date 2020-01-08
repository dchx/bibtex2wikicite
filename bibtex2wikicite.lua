-- coding: utf-8

-- getmetatable('').__index = function(str,i) return string.sub(str,i,i) end -- string indexing
function strip(strng) return strng:match("^%s*(.-)%s*$") end -- strip left and right spaces of strng
function split(strng, separate)
    --[[
    Split a string by separate into table
    ]]
    substrings = {}
    for substring in (strng..separate):gmatch("(.-)"..separate) do
        table.insert(substrings, substring)
    end
    return substrings
end

function tablelen(tbl)
    len = 0
    for i in pairs(tbl) do
        len = len + 1
    end
    return len
end

function findbracket(strng)
    --[[
    Return the substrings in the first layer of the bracket {}
    ]]
    brackets = "{}"
    lb = brackets:sub(1, 1)
    rb = brackets:sub(2, 2)
    nlayer = 0
    value = ""
    varlist = {}
    left = "" -- substrings not in brackes
    leftlist = {}
    for istr = 1, string.len(strng) do
	s = strng:sub(istr, istr)
        if s==lb then nlayer = nlayer + 1 end
        if s==rb then nlayer = nlayer - 1 end
        if nlayer>0 then value = value .. s
        else left = left .. s
        end
        if nlayer==0 and string.len(value)~=0 then
            value = value:sub(2) -- don't include left bracket
            table.insert(varlist, strip(value))
            value = ""
            left = left:sub(1, string.len(left)-1) -- don't include right bracket
            table.insert(leftlist, strip(left))
            left = ""
        end
    end
    return varlist, leftlist
end

function journalconverter(journal)
    if     journal == '\\apj' then return '{{ApJ}}'
    elseif journal == '\\apjl' then return '{{ApJL}}'
    elseif journal == '\\aj' then return '{{AJ}}'
    elseif journal == '\\mnras' then return '{{MNRAS}}'
    elseif journal == '\\aap' then return '{{A&A}}'
    elseif journal == '\\aaps' then return '{{A&A}} Supplement'
    elseif journal == '\\aapr' then return '{{A&AR}}'
    elseif journal == '\\araa' then return '{{ARAA}}'
    elseif journal == '\\nat' then return '{{Nature}}'
    elseif journal == 'Nature Astronomy' then return '{{Nature}} Astronomy'
    elseif journal == 'Science' then return '[[Science]]'
    elseif journal == 'Physical Review Letters' then return '{{PRL}}'
    elseif journal == '\\prd' then return '{{PRD}}'
    elseif journal == '\\physrep' then return '{{PhR}}'
    else return journal
    end
end

function clear_nonenglish(strng)
    --[[
    Clear non-English letters in string
    ]]
    latex = {"\\\\`", "\\\\'", "\\\\^", '\\\\"', "\\\\H", "\\\\~", "\\\\c",
             "\\\\k", "\\\\=", "\\\\b", "\\\\.", "\\\\d", "\\\\r", "\\\\u",
             "\\\\v"}
    unico = {'\u{0300}','\u{0301}','\u{0302}','\u{0308}','\u{030B}','\u{0303}','\u{0327}',
             '\u{0328}','\u{0304}','\u{0332}','\u{0307}','\u{0323}','\u{030A}','\u{0306}',
             '\u{030C}'}
    strng = strng:gsub("\\ll", '\u{0142}') -- do l with stroke
    for i = 1, tablelen(latex) do
        strng = strng:gsub(latex[i] .. '(.)','%1' .. unico[i])
    end
    return strng
end

-- above revised 

function paras2wikicite(paras)
    --[[
    Input: dictionary
    Output: wikicite string
    ]]
    keys = {'last1', 'first1', 'last2', 'first2', 'last3', 'first3', 'last4',
            'editor1-last', 'editor1-first', 'editor2-last', 'editor2-first',
            'editor3-last', 'editor3-first', 'editor4-last', 'title',
            'chapter', 'journal', 'year', 'series', 'volume', 'issue',
            'number', 'pages', 'arxiv', 'doi', 'bibcode'}
    -- deal with books
    if paras['reftype']=='BOOK' then
        if string.match(paras.keys(), 'booktitle') then _ = paras.pop('booktitle') end
        outstr = "* {{cite book | "
    elseif string.match(paras.keys(), 'booktitle') then
        outstr = "* {{cite book | "
        if string.match(paras.keys(), 'title') then paras['chapter'] = paras.pop('title') end
        if string.match(paras.keys(), 'booktitle') then paras['title'] = paras.pop('booktitle') end
    else outstr = "* {{cite journal | "
    end

    for _, key in ipairs(keys) do
        if string.match(paras.keys(), key) then
            if key == 'last4' then
                outstr += 'display-authors = etal | '
            elseif key == 'editor4-last' then
                outstr += 'display-editors = etal | '
            else
                outstr += (key+' = '+paras[key]+' | ')
            end
        end
    end
    outstr += 'ref = harv}}'
    return outstr
end

-- below revised 
function find_key_val(strng)
    --[[
    Return keys and values [list] for string like "... key = value, ..."
    ]]
    keys={}
    values={}
    while string.match(strng, ',') and string.len(strng) ~= 0 do
        table.insert(keys, strip(strng:sub(1, strng:find('=')-1):gsub(',','')))
        strng = strip(strng:sub(strng:find('=')+1))
        if string.len(strng) ~= 0 then
            table.insert(values, strip(strng:sub(1, strng:find(',')-1)))
            strng = strng:sub(strng:find(',')+1)
        end
    end
    if tablelen(values) ~= 0 and string.len(values[tablelen(values)])==0 then
        table.remove(keys, tablelen(keys))
        table.remove(values, tablelen(values))
    end
    return keys, values
end
-- above revised 

function split_authors(paras):
    --[[
    Input dictionary paras
    Return dictionary paras, authors and editors modified
    ]]
    for _, authortype in ipairs({'author','editor'}) do
        if string.match(paras.keys(), authortype) then
            authorlist = split(paras[authortype], ' and ')
            for i,author in ipairs(authorlist) do
                names = split(author, ',')
                last = strip(names[0])
                first = strip(','.join(names[1:]))
                n = str(i+1)
                if authortype == 'author' then
                    paras['first'+n] = first
                    paras['last'+n] = last
                elseif authortype == 'editor' then
                    paras['editor'+n+'-first'] = first
                    paras['editor'+n+'-last'] = last
                end
            end
        end
    end
    return paras
end

-- below revised 
function bibtex2wikicite(strng)
    --[[
    Input bibtex code, return wikicite code
    ]]
    -- find first layer {} 
    mainpart, reftype = findbracket(strng)
    reftype = strip(reftype[1]):match("^@*(.-)$") -- lstrip('@')
    -- find second layer {}
    values, prekeys = findbracket(mainpart[1])
    -- form keys
    bibcode = strip(split(prekeys[1], ',')[1])
    keys = {}
    for _, key in ipairs(prekeys) do
        table.insert(keys, strip(key:match(".*,(.*)="))) -- rightmost substring between ',' and '='
    end
    -- form dictionary
    for i in pairs(keys) do paras[keys[i]] = values[i] end
    paras['bibcode'] = bibcode
    paras['reftype'] = reftype -- ARTICLE/BOOK/INPROCEEDINGS etc
    -- deal with additional paras without {}
    for _, key in ipairs(prekeys) do
        addkey, addval = find_key_val(key)
-- above revised 
        for i = 1, tablelen(addkey) do
            paras[addkey[i]] = addval[i]
        end
    end
    -- deal with values
    for _, k in ipairs(paras.keys()) do
        paras[k] = paras[k]:gsub('{',''):gsub('}','') -- remove {}s
        paras[k] = clear_nonenglish(strip(paras[k])) -- clear non-letter
        paras[k] = paras[k]:gsub('~',' '):gsub('"','') -- replace ~,"
    end

    -- deal with authors
    paras = split_authors(paras)
    -- deal with arviv parameter
    if string.match(paras.keys(), 'eprint') and string.match(paras.keys(), 'archivePrefix') and
      paras['archivePrefix']=='arXiv' then
        paras['arxiv'] = paras.pop('eprint')
    end
    if string.match(paras.keys(), 'journal') then
        paras['journal'] = journalconverter(paras['journal'])
        if paras['journal']=='arXiv e-prints' then
            if string.match(paras.keys(), 'year') and not paras['year'].isnumeric() then
                paras['year'] = '20' + split(paras['year'], ':')[1][:2]
            end
            if string.match(paras.keys(), 'pages') then
                paras.pop('pages')
            end
        end
    end
    -- title no periods
    for _, noperiod in ipairs({'title', 'booktitle'}) do
        if string.match(paras.keys(), noperiod) then
            paras[noperiod] = paras[noperiod]:match("^\.*(.-)\.*$") -- strip('.')
        end
    end

    -- dictionary to wikicite code
    return paras2wikicite(paras)
end

if __name__ == '__main__' then
        strng = input("Bibtex code:")
        print(bibtex2wikicite(strng))
end
