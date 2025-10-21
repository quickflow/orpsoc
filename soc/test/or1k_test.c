
void main()
{
  volatile unsigned int *pAddr = (unsigned int *) 0x5000;
  unsigned int count;
  for(count=0; count< 256; count++) {
    *pAddr++ = count;
  }
}
