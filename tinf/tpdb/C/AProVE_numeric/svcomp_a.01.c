extern int __VERIFIER_nondet_int(void);

int test_fun(int x, int y)
{
    int c = 0;
    while (x > 0)
    {
        y = 0;
        while (y < x)
        {
            y = y + 1;
            c = c + 1;
            //x = x;
        }
        x = x - 1;
    }
    return c;
}

int main() {
    return test_fun(__VERIFIER_nondet_int(), __VERIFIER_nondet_int());
}
