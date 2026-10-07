#!/usr/bin/env python3
"""Validate localization coverage, formatting tokens, and reviewed Photoshop terminology.

Run from any directory. --require-reviewed also rejects translations awaiting linguistic review.
"""
import re,pathlib,json

def strings(s):
 i=0
 while i<len(s):
  if s.startswith('//',i):
   j=s.find('\n',i); i=len(s) if j<0 else j;continue
  if s.startswith('/*',i):
   j=s.find('*/',i+2);i=len(s) if j<0 else j+2;continue
  if s.startswith('"""',i):
   j=s.find('"""',i+3); i=len(s) if j<0 else j+3;continue
  if s[i]=='"':
   a=i;i+=1;parts=[];start=i
   while i<len(s):
    if s.startswith('\\(',i):
     parts.append(s[start:i]);beg=i+2;i=beg;depth=1
     while depth:
      if s[i]=='"':
       i+=1
       while s[i]!='"':
        if s[i]=='\\':i+=1
        i+=1
       i+=1;continue
      if s[i]=='(':depth+=1
      if s[i]==')':depth-=1
      i+=1
     parts.append(('expr',s[beg:i-1]));start=i;continue
    if s[i]=='\\':i+=2;continue
    if s[i]=='"':
     parts.append(s[start:i]);i+=1;break
    i+=1
   yield a,i,parts
  else:i+=1

def key(parts):
 out='';n=0
 for p in parts:
  if isinstance(p,tuple):n+=1;out+=f'%{n}$@'
  else:out+=p.replace('\\n','\n').replace('\\"','"').replace('\\t','\t')
 return out


import argparse,collections,sys
root=pathlib.Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--require-reviewed',action='store_true')
args=parser.parse_args()
catalog=json.loads((root/'Compositor/Localizable.xcstrings').read_text())
entries=catalog['strings']
locales={'en','zh-Hans','zh-Hant','ja','ko','de','fr','es','pt-BR'}
errors=[]
pending=collections.Counter()
def units(node):
 if 'stringUnit' in node:yield node['stringUnit']
 for value in node.get('variations',{}).values():
  for variant in value.values():yield from units(variant)
def tokens(text):return collections.Counter(re.findall(r'%\d+\$@|%lld',text))
for source,entry in entries.items():
 if entry.get('shouldTranslate') is False:continue
 if set(entry.get('localizations',{}))!=locales:errors.append(f'Missing/extra locales: {source}')
 for language,node in entry.get('localizations',{}).items():
  for unit in units(node):
   value=unit['value']
   if not value:errors.append(f'Empty translation: {language}: {source}')
   if tokens(value)!=tokens(source):errors.append(f'Placeholder mismatch: {language}: {source}')
   if unit['state']!='translated':pending[language]+=1
   if '\ufffd' in value or '▁' in value:errors.append(f'Invalid translation character: {language}: {source}')
for path in (root/'Compositor').rglob('*.swift'):
 if path.name=='Localization.swift':continue
 source=path.read_text()
 for a,b,parts in strings(source):
  prefix=source[max(0,a-100):a]
  if prefix.endswith(('L10n.tr(', 'L10n.text(')):
   message=key(parts)
   if message not in entries:errors.append(f'Missing key: {path.relative_to(root)}: {message}')
  elif re.search(r'(?:Text|Button|Menu|Toggle|Picker|Label|TextField|help|accessibilityLabel|accessibilityValue)\($',prefix):
   message=key(parts)
   if re.search(r'[A-Za-z]{3}',message) and message not in {'Compositor'}:
    errors.append(f'Unlocalized UI literal: {path.relative_to(root)}: {message}')
 for match in re.finditer(r'L10n\.(?:tr|text)\([^\n]*?\)\s*\+\s*"([^"\n]*)"', source):
  if re.search(r'[A-Za-z]{3}', match[1]) and match[1] not in {'.png', '.jpg', '.comp'}:
   errors.append(f'Unlocalized appended text: {path.relative_to(root)}: {match[1]}')
glossary=(root/'docs/localization/glossary.tsv').read_text().splitlines()
columns=glossary[0].split('\t')[1:]
for row in glossary[1:]:
 cells=row.split('\t');source=cells[0]
 for language,expected in zip(columns,cells[1:]):
  actual=entries[source]['localizations'][language]['stringUnit']['value']
  if actual!=expected:errors.append(f'Glossary mismatch: {language}: {source}')
info=json.loads((root/'Compositor/InfoPlist.xcstrings').read_text())
for source,entry in info['strings'].items():
 if entry.get('shouldTranslate') is False:continue
 if set(entry.get('localizations',{}))!=locales:errors.append(f'Missing file type locales: {source}')
 for language,node in entry.get('localizations',{}).items():
  if not node['stringUnit']['value']:errors.append(f'Empty file type: {language}: {source}')
localizable_count=sum(entry.get('shouldTranslate') is not False for entry in entries.values())
print(f'{localizable_count} localizable keys; {len(locales)} languages; all placeholders and glossary terms checked.')
print('Awaiting linguistic review:',dict(sorted(pending.items())))
if args.require_reviewed and pending:errors.append('Some translations still require linguistic review.')
for error in errors:print(error,file=sys.stderr)
sys.exit(bool(errors))
