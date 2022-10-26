/* Should trigger violation of rule MC3.R10.4*/
void f()
{
    signed char sc;
    char c;
    int i;
    // char aaa;
    i = (c) ?: sc;
}
