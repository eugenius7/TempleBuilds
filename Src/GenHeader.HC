
#define UNFOUND_F "unfound.DD"
CHashTable *tab=HashTableNew(0x1000);
CHashGeneric *gen;
I64 ln;
U8 *ln_txt;
for(ln=1;ln_txt=DocLineRead(UNFOUND_F,ln);ln++) {
  if('A'<=*ln_txt<='Z') {
    gen=CAlloc(sizeof CHashGeneric);
    gen->str=MStrUtil(ln_txt,SUF_REM_SPACES);
    gen->type=HTT_FRAME_PTR;
    HashAdd(gen,tab);
  }
  Free(ln_txt);
}
CDoc *headers=DocNew("Headers.HH");
U0 TrimComment(U8 *str) {
  if(str=StrMatch("//",str)) {
    *str=0;
  }
}
Bool NextLine(CDoc *doc) {
  CDocEntry* old;
loop:
  old=doc->cur_entry;
  EdLineDown(doc);
  if(old==doc->cur_entry) return FALSE;
  if(doc->cur_entry->type_u8!=DOCT_TEXT) goto loop;
  return TRUE;
}
U0 GenHeadersForFile(U8 *file) {
  CDoc *doc=DocRead(file,DOCF_PLAIN_TEXT_TABS|DOCF_NO_CURSOR);
  I64 ln=1;
  U8 buf[STR_LEN],header[STR_LEN];
  U8 *ptr,*ln_txt,*header_start,*ptr2,*b;
  CDocEntry *old;
  if(!DocGoToLine(doc,1)) {
    DocDel(doc);
    return;
  }
  for(;TRUE;) {
    if(doc->cur_entry->type_u8==DOCT_TEXT) {
      ln_txt=StrNew(doc->cur_entry->tag);
    } else {
      ln++;
      goto nl;
    }
    ptr=ln_txt;
    if(!('A'<=ToUpper(*ptr)<='Z')) goto next;
    StrUtil(ln_txt,SUF_REM_TRAILING);
    if(!StrNCmp(ln_txt,"public",StrLen("public"))) {
      ptr+=StrLen("public");
    }
    while(*ptr&&Bt(char_bmp_white_space,*ptr))
      ptr++;
    if(!StrNCmp(ptr,"extern",6)) goto next;
    if(!StrNCmp(ptr,"import",6)) goto next;
    
    header_start=ptr;
    if(!StrFirstOcc(ptr,"(")) goto next;
    ptr=StrFirstOcc(ptr,"(")-1;
    while(ptr>header_start&&Bt(char_bmp_white_space,*ptr))
      ptr--;
    while(ptr>header_start&&Bt(char_bmp_alpha_numeric,*ptr)) {
      ptr--;
    }
    if(ptr!=header_start) ptr++;
    else goto next; //There MUST be room for a return-type and pointer stars/spaces
    //Check for return type
    for(ptr2=header_start;ptr2<ptr&&Bt(char_bmp_alpha_numeric,*ptr2);ptr2++);
    //Check for pointer stars or spaces
    for(;ptr2<ptr;ptr2++)
      if(Bt(char_bmp_white_space,*ptr2)||*ptr2=='*') {
        ; //All is good
      } else { //Found a non space/pointer star
        goto next;
      }
    StrCpy(buf,"");
    while(*ptr&&Bt(char_bmp_alpha_numeric,*ptr)) {
      CatPrint(buf,"%c",*ptr++);
    }
    if(HashFind(buf,tab,HTT_FRAME_PTR)) {
      DocPrint(headers,"extern ");
      if(b=StrFirstOcc(header_start,"{;")) {
found_end:
        *b=0;
        TrimComment(header_start);
        DocPrint(headers,header_start);
        DocPrint(headers,";\n");
      } else {
        DocPrint(headers,header_start);
        NextLine(doc);
        Free(ln_txt);
        ln_txt=StrNew(doc->cur_entry->tag);
        while(!StrFirstOcc(ln_txt,"{;")) {
          TrimComment(ln_txt);
          DocPrint(headers,ln_txt);
          NextLine(doc);
          Free(ln_txt);
          ln_txt=StrNew(doc->cur_entry->tag);
        }
        header_start=ln_txt;
	b=StrFirstOcc(header_start,"{;");
	goto found_end;
      }
    }
next:
    ln++;
    Free(ln_txt);
nl:
   if(!NextLine(doc)) break;
  }
  DocDel(doc);
}
CDirEntry *root=FilesFind("*.HC",FUF_RECURSE|FUF_FLATTEN_TREE),*ent;
for(ent=root;ent;ent=ent->next) {
  GenHeadersForFile(ent->full_name);
}
DirEntryDel(ent);

DocWrite(headers);
DocDel(headers);
