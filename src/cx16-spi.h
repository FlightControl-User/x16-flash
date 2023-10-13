extern unsigned char spi_manufacturer;
extern unsigned char spi_memory_type;
extern unsigned char spi_memory_capacity;


void spi_get_jedec();
void spi_get_uniq();
void spi_();
void spi_read_flash(unsigned long);
void spi_read_flash_to_bank(unsigned long);
void spi_spi_read_flash_to_bank_continue();
void spi_sector_erase(unsigned long);
void spi_block_erase(unsigned long);
void spi_write_page_begin(unsigned long);
unsigned char spi_wait_non_busy();
unsigned char spi_read();
void spi_write(unsigned char data);
void spi_fast();
unsigned char spi_deselect();
void spi_select();

unsigned char* const vera_reg_SPIData = (unsigned char*)0x9F3E;
unsigned char* const vera_reg_SPICtrl = (unsigned char*)0x9F3F;

