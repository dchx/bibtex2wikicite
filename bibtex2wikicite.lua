-- coding: utf-8
import re

function findbracket(string,brackets="{}")
    '''
    Return the substrings in the first layer of the bracket {}
    '''
    lb = brackets[0]
    rb = brackets[1]
    nlayer = 0
    value = ""
    varlist = []
    left = "" -- substrings not in brackes
    leftlist = []
    for s in string do
        if s==lb then nlayer += 1 end
        if s==rb then nlayer -= 1 end
        if nlayer>0 then value += s
        else left += s
        end
        if nlayer==0 and len(value)!=0 then
            value = value[1:] -- don't include left bracket
            varlist.append(value.strip())
            value = ""
            left = left[:-1] -- don't include right bracket
            leftlist.append(left.strip())
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

function clear_nonenglish(string)
    '''
    Clear non-English letters in string
    '''
    latex = ["\\\\`", "\\\\'", "\\\\^", '\\\\"', "\\\\H", "\\\\~", "\\\\c",\
             "\\\\k", "\\\\=", "\\\\b","\\\\\.", "\\\\d", "\\\\r", "\\\\u",\
             "\\\\v"]
    unico = ['\u0300','\u0301','\u0302','\u0308','\u030B','\u0303','\u0327',\
             '\u0328','\u0304','\u0332','\u0307','\u0323','\u030A','\u0306',\
             '\u030C']
    string = string.replace("\\ll",'\u0142') -- do l with stroke
    for i in range(len(latex)) do
        string = re.sub(latex[i]+"(.)","\\1"+unico[i],string)
    end
    return string
end

function paras2wikicite(paras)
    '''
    Input: dictionary
    Output: wikicite string
    '''
    keys = ['last1', 'first1', 'last2', 'first2', 'last3', 'first3', 'last4',\
            'editor1-last', 'editor1-first', 'editor2-last', 'editor2-first',\
            'editor3-last', 'editor3-first', 'editor4-last', 'title',\
            'chapter', 'journal', 'year', 'series', 'volume', 'issue',\
            'number', 'pages', 'arxiv', 'doi', 'bibcode']
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

    for key in keys do
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

function find_key_val(string)
    '''
    Return keys and values [list] for string like "... key = value, ..."
    '''
    keys=[]
    values=[]
    while string.match(string, ',') do
        keys.append(string[:string.find('=')].replace(',','').strip())
        string = string[string.find('=')+1:]
        values.append(string[:string.find(',')].strip())
        string = string[string.find(',')+1:]
    end
    if len(values[-1])==0 then
        keys = keys[:-1]
        values = values[:-1]
    end
    return keys, values

function split_authors(paras):
    '''
    Input dictionary paras
    Return dictionary paras, authors and editors modified
    '''
    for authortype in ['author','editor'] do
        if string.match(paras.keys(), authortype) then
            authorlist = paras[authortype].split(' and ')
            for i,author in enumerate(authorlist) do
                names = author.split(',')
                last = names[0].strip()
                first = ','.join(names[1:]).strip()
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

function bibtex2wikicite(string)
    '''
    Input bibtex code, return wikicite code
    '''
    -- find first layer {} 
    mainpart, reftype = findbracket(string)
    reftype = reftype[0].strip().lstrip('@')
    -- find second layer {}
    values, prekeys = findbracket(mainpart[0])
    -- form keys
    bibcode=prekeys[0].split(',')[0].strip()
    keys=[key[key.rfind(',')+1:key.rfind('=')].strip() for key in prekeys]
    -- form dictionary
    paras = dict(zip(keys,values))
    paras['bibcode'] = bibcode
    paras['reftype'] = reftype -- ARTICLE/BOOK/INPROCEEDINGS etc
    -- deal with additional paras without {}
    for key in prekeys do
        addkey, addval = find_key_val(key)
        for i in range(len(addkey)) do
            paras[addkey[i]] = addval[i]
        end
    end
    -- deal with values
    for k in paras.keys() do
        paras[k] = paras[k].replace('{','').replace('}','') -- remove {}s
        paras[k] = clear_nonenglish(paras[k].strip()) -- clear non-letter
        paras[k] = paras[k].replace('~',' ').replace('"','') -- replace ~,"
    end

    -- deal with authors
    paras = split_authors(paras)
    -- deal with arviv parameter
    if string.match(paras.keys(), 'eprint') and string.match(paras.keys(), 'archivePrefix') and\
     paras['archivePrefix']=='arXiv' then
        paras['arxiv'] = paras.pop('eprint')
    end
    if string.match(paras.keys(), 'journal') then
        paras['journal'] = journalconverter(paras['journal'])
        if paras['journal']=='arXiv e-prints' then
            if string.match(paras.keys(), 'year') and not paras['year'].isnumeric() then
                paras['year'] = '20'+paras['year'].split(':')[1][:2]
            end
            if string.match(paras.keys(), 'pages') then
                paras.pop('pages')
            end
        end
    end
    -- title no periods
    for noperiod in ['title', 'booktitle'] do
        if string.match(paras.keys(), noperiod) then
            paras[noperiod] = paras[noperiod].strip('.')
        end
    end

    -- dictionary to wikicite code
    return paras2wikicite(paras)
end

if __name__ == '__main__' then
        string = input("Bibtex code:")
        print(bibtex2wikicite(string))
end
