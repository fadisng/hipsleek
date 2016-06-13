data str_buf{
   int offset;
   string s;
   int size;
}

pred str_obj<offset,s,length> ==
  self::str_buf<offset,s,length> & endzero(s) & slen(s)<=length+1
           & 0<=offset<=length
  inv endzero(s) & slen(s)<=length+1 & 0<=offset<=length.

void plus_plus(str_buf s)
  requires s::str_obj<offset,str,length> & offset<length
  ensures s::str_obj<offset+1,str,length>;
{
  s.offset = s.offset+1;
}

void minus_minus(str_buf s)
  requires s::str_obj<offset,str,length> & offset>0
  ensures s::str_obj<offset-1,str,length>;
{
  s.offset = s.offset-1;
}