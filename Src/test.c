/* Should trigger violation of rule MC3.R10.4*/
void f()
{
    signed char sc;
    char c;
    int i;
    i = (c) ?: sc;
    i = (c) ?: sc;
}
