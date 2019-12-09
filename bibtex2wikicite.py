# coding: utf-8
import re

def findbracket(string,brackets="{}"):
    '''
    Return the substrings in the first layer of the bracket {}
    '''
    lb = brackets[0]
    rb = brackets[1]
    nlayer = 0
    value = ""
    varlist = []
    left = "" # substrings not in brackes
    leftlist = []
    for s in string:
        if s==lb: nlayer += 1
        if s==rb: nlayer -= 1
        if nlayer>0: value += s
        else: left += s
        if nlayer==0 and len(value)!=0:
            value = value[1:] # don't include left bracket
            varlist.append(value.strip())
            value = ""
            left = left[:-1] # don't include right bracket
            leftlist.append(left.strip())
            left = ""
    return varlist, leftlist

def journalconverter(journal):
    if   journal == '\\apj': return '{{ApJ}}'
    elif journal == '\\apjl': return '{{ApJL}}'
    elif journal == '\\aj': return '{{AJ}}'
    elif journal == '\\mnras': return '{{MNRAS}}'
    elif journal == '\\aap': return '{{A&A}}'
    elif journal == '\\aaps': return '{{A&A}} Supplement'
    elif journal == '\\aapr': return '{{A&AR}}'
    elif journal == '\\araa': return '{{ARAA}}'
    elif journal == '\\nat': return '{{Nature}}'
    elif journal == 'Nature Astronomy': return '{{Nature}} Astronomy'
    elif journal == 'Science': return '[[Science]]'
    elif journal == 'Physical Review Letters': return '{{PRL}}'
    elif journal == '\\prd': return '{{PRD}}'
    elif journal == '\\physrep': return '{{PhR}}'
    else: return journal

def clear_nonenglish(string):
    '''
    Clear non-English letters in string
    '''
    latex = ["\\\\`", "\\\\'", "\\\\^", '\\\\"', "\\\\H", "\\\\~", "\\\\c",\
             "\\\\k", "\\\\=", "\\\\b","\\\\\.", "\\\\d", "\\\\r", "\\\\u",\
             "\\\\v"]
    unico = ['\u0300','\u0301','\u0302','\u0308','\u030B','\u0303','\u0327',\
             '\u0328','\u0304','\u0332','\u0307','\u0323','\u030A','\u0306',\
             '\u030C']
    string = string.replace("\\ll",'\u0142') # do l with stroke
    for i in range(len(latex)):
        string = re.sub(latex[i]+"(.)","\\1"+unico[i],string)
    return string

def paras2wikicite(paras):
    '''
    Input: dictionary
    Output: wikicite string
    '''
    keys = ['last1', 'first1', 'last2', 'first2', 'last3', 'first3', 'last4',\
            'editor1-last', 'editor1-first', 'editor2-last', 'editor2-first',\
            'editor3-last', 'editor3-first', 'editor4-last', 'title',\
            'chapter', 'journal', 'year', 'series', 'volume', 'issue',\
            'number', 'pages', 'arxiv', 'doi', 'bibcode']
    # deal with books
    if paras['reftype']=='BOOK':
        if 'booktitle' in paras.keys(): _=paras.pop('booktitle')
        outstr = "* {{cite book | "
    elif 'booktitle' in paras.keys():
        outstr = "* {{cite book | "
        if 'title' in paras.keys(): paras['chapter'] = paras.pop('title')
        if 'booktitle' in paras.keys(): paras['title'] = paras.pop('booktitle')
    else: outstr = "* {{cite journal | "

    for key in keys:
        if key in paras.keys():
            if key == 'last4':
                outstr += 'display-authors = etal | '
            elif key == 'editor4-last':
                outstr += 'display-editors = etal | '
            else:
                outstr += (key+' = '+paras[key]+' | ')
    outstr += 'ref = harv}}'
    return outstr

def find_key_val(string):
    '''
    Return keys and values [list] for string like "... key = value, ..."
    '''
    keys=[]
    values=[]
    while ',' in string:
        keys.append(string[:string.find('=')].replace(',','').strip())
        string = string[string.find('=')+1:]
        values.append(string[:string.find(',')].strip())
        string = string[string.find(',')+1:]
    if len(values[-1])==0:
        keys = keys[:-1]
        values = values[:-1]
    return keys, values

def split_authors(paras):
    '''
    Input dictionary paras
    Return dictionary paras, authors and editors modified
    '''
    for authortype in ['author','editor']:
        if authortype in paras.keys():
            authorlist = paras[authortype].split(' and ')
            for i,author in enumerate(authorlist):
                names = author.split(',')
                last = names[0].strip()
                first = ','.join(names[1:]).strip()
                n = str(i+1)
                if authortype == 'author':
                    paras['first'+n] = first
                    paras['last'+n] = last
                elif authortype == 'editor':
                    paras['editor'+n+'-first'] = first
                    paras['editor'+n+'-last'] = last
    return paras

def bibtex2wikicite(string):
    '''
    Input bibtex code, return wikicite code
    '''
    # find first layer {} 
    mainpart, reftype = findbracket(string)
    reftype = reftype[0].strip().lstrip('@')
    # find second layer {}
    values, prekeys = findbracket(mainpart[0])
    # form keys
    bibcode=prekeys[0].split(',')[0].strip()
    keys=[key[key.rfind(',')+1:key.rfind('=')].strip() for key in prekeys]
    # form dictionary
    paras = dict(zip(keys,values))
    paras['bibcode'] = bibcode
    paras['reftype'] = reftype # ARTICLE/BOOK/INPROCEEDINGS etc
    # deal with additional paras without {}
    for key in prekeys:
        addkey, addval = find_key_val(key)
        for i in range(len(addkey)):
            paras[addkey[i]] = addval[i]
    # deal with values
    for k in paras.keys(): 
        paras[k] = paras[k].replace('{','').replace('}','') # remove {}s
        paras[k] = clear_nonenglish(paras[k].strip()) # clear non-letter
        paras[k] = paras[k].replace('~',' ').replace('"','') # replace ~,"

    # deal with authors
    paras = split_authors(paras)
    # deal with arviv parameter
    if 'eprint' in paras.keys() and 'archivePrefix' in paras.keys() and\
     paras['archivePrefix']=='arXiv':
        paras['arxiv'] = paras.pop('eprint')
    if 'journal' in paras.keys():
        paras['journal'] = journalconverter(paras['journal'])
        if paras['journal']=='arXiv e-prints':
            if 'year' in paras.keys() and not paras['year'].isnumeric():
                paras['year'] = '20'+paras['year'].split(':')[1][:2]
            if 'pages' in paras.keys():
                paras.pop('pages')
    # title no periods
    for noperiod in ['title', 'booktitle']:
        if noperiod in paras.keys():
            paras[noperiod] = paras[noperiod].strip('.')

    # dictionary to wikicite code
    return paras2wikicite(paras)

if __name__ == '__main__':
    from builtins import input
    string = input("Bibtex code:")
    print(bibtex2wikicite(string))
