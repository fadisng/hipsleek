/*
data str {
  int val;
  str next;
}
*/

WFS<> ==
  self::char_star<0,q>*q::BADS<> 
  or self::char_star<v,q>*q::WFS<> & v!=0 
  inv true;

WFSeg<p> ==
  self=p 
  or self::char_star<v,q>*q::WFSeg<p> & v!=0
  inv true;

BADS<> ==
  self::char_star<v,q>*q::BADS<> 
  inv true;

/*
     while (*s != '\0')
         s++;
 no guarantee it reaches the end of string ..
*/
void while1(ref char_star s)
  requires s::WFS<> 
  ensures s::WFSeg<s'>*s'::char_star<0,q>*q::BADS<>;
{
  int x=__get_char(s);
  if (x!=0) {
    // dprint;
    s = __plus_plus_char(s);
    //dprint;
    while1(s);
  }
}

/*
     while ((*s++ = *s2++) != '\0')
         ;               
*/
void while2(ref char_star s1,ref char_star s2)
  requires s1::char_star<_,q>*q::BADS<> * s2::WFS<> 
  ensures s1::WFSeg<q>*q::char_star<0,qq>*qq::BADS<> 
    * s2'::char_star<0,_> & s1'=q; 
{
  int x=__get_char(s2);
  __write_char(s1,x);
  if (x!=0) {
    dprint;
    s2 = __plus_plus_char(s2);
    s1 = __plus_plus_char(s1);
    while2(s1,s2);
  }

}
