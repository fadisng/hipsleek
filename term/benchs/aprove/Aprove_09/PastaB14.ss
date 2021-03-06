int rand_int ()
requires Term
ensures true;

void main () 
requires Term
ensures true;
{
	int x = rand_int();
	int y = rand_int();
	
	loop_1(x, y);
}

void loop_1 (ref int x, ref int y)
case {
	x!=y -> requires Term ensures true;
	x=y -> case {
		x<=0 -> requires Term ensures true;
		x>0 -> requires Term ensures true;
	}
}
{
	if (x == y && x > 0) {
		loop_2(x, y);
		loop_1(x, y); 
	}
}

void loop_2 (ref int x, ref int y)
case {
	y>0 -> requires Term[y] ensures x'<x & y'<=0;
	y<=0 -> requires Term ensures x'=x & y'<=0;
}
{
	if (y > 0) {
		x--;
		y--;
		loop_2(x, y);
	}
}
