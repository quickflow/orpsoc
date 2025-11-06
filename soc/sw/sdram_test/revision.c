
typedef struct load_info
{
  unsigned long boardtype;         // BOOT_ID
  unsigned char boardName[12];     //
  unsigned char caaName[20];       //
  unsigned char caaRev[8];         //
  unsigned char addInfo[16];       //

} LOAD_INFO;


LOAD_INFO load_info_values = {
    
  0x00000001,
  "ALTERA 3C25 ",              // Boardname, must be fixed 12 bytes
  "NIOS II Dev Kit     ",      // Add. info, must be fixed 20 bytes
  "R1      ",                  // Revision , must be fixed 8 bytes
  "Xianfeng Zeng   "           // Add. info, must be fixed 16 bytes
};

