void loop (int i)
case {
	i=0 -> requires Term ensures true;
	i!=0 -> requires Loop ensures false;
}
{
	if (i != 0) {
		if (i < 0) {
			i--;
			i = -i;
		} else {
			i++;
			i = -i;
		}
		loop(i);
	}
}
