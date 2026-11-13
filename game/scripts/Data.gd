extends Node
## Все справочники игры по эпохам 1995 → 2026: детали, ОС, игры, вирусы, инструменты, события.
## Чтобы добавить деталь — допиши строчку в таблицу ниже (последнее поле — год выхода).

const SLOTS := ["mobo", "cpu", "cooler", "ram", "gpu", "storage", "psu"]
const SLOT_NAMES := {
	"mobo": "Материнская плата", "cpu": "Процессор", "cooler": "Кулер",
	"ram": "Оперативная память", "gpu": "Видеокарта", "storage": "Накопитель",
	"psu": "Блок питания",
}
## Порядок сборки: что должно стоять, чтобы поставить деталь
const NEEDS := {"cpu": ["mobo"], "cooler": ["cpu"], "ram": ["mobo"], "gpu": ["mobo"]}

# [id, название, множитель нагрузки на видеокарту]
const QUALITIES := [
	["low", "Низкие", 1.7], ["medium", "Средние", 1.0],
	["high", "Высокие", 0.72], ["ultra", "Ультра", 0.5],
]

const START_YEAR := 1995
const DAYS_PER_YEAR := 20

## Средняя мощность железа по годам (для требований игр и подбора ПК клиентов)
const MID_CPU := {1993: 1, 1995: 1, 1996: 2, 1997: 3, 1998: 5, 1999: 7, 2000: 10, 2001: 15, 2002: 20, 2003: 28,
	2004: 32, 2005: 45, 2006: 70, 2007: 90, 2008: 100, 2009: 120, 2010: 140, 2011: 170, 2012: 200, 2013: 210,
	2014: 230, 2015: 250, 2016: 270, 2017: 300, 2018: 350, 2019: 420, 2020: 500, 2021: 550, 2022: 600,
	2023: 700, 2024: 800, 2025: 850, 2026: 900}
const MID_GPU := {1993: 1, 1995: 1, 1996: 2, 1997: 3, 1998: 5, 1999: 8, 2000: 10, 2001: 14, 2002: 20, 2003: 26,
	2004: 38, 2005: 50, 2006: 75, 2007: 100, 2008: 115, 2009: 150, 2010: 180, 2011: 200, 2012: 240, 2013: 270,
	2014: 300, 2015: 380, 2016: 450, 2017: 500, 2018: 560, 2019: 620, 2020: 750, 2021: 850, 2022: 950,
	2023: 1050, 2024: 1200, 2025: 1400, 2026: 1500}
const MID_RAM := {1993: 0.004, 1995: 0.008, 1997: 0.016, 1998: 0.032, 1999: 0.064, 2000: 0.128, 2002: 0.256,
	2004: 0.512, 2006: 1.0, 2008: 2.0, 2012: 4.0, 2014: 6.0, 2015: 8.0, 2020: 12.0, 2022: 16.0}
const MID_SIZE := {1993: 0.015, 1995: 0.05, 1997: 0.3, 1999: 0.6, 2001: 1.5, 2003: 3.0, 2004: 6.0, 2007: 8.0,
	2009: 10.0, 2011: 15.0, 2013: 30.0, 2015: 50.0, 2018: 70.0, 2020: 90.0, 2023: 120.0}

var parts := {}

# --- Процессоры: id, имя, сокет, мощность, TDP, цена, год
const CPU_T := [
	["cpu_p75", "Intel Pentium 75", "Socket5", 1, 8, 200, 1995],
	["cpu_p133", "Intel Pentium 133", "Socket7", 2, 11, 250, 1996],
	["cpu_pmmx200", "Intel Pentium MMX 200", "Socket7", 3, 15, 300, 1997],
	["cpu_k6_2", "AMD K6-2 300", "Socket7", 4, 17, 150, 1998],
	["cpu_p2_400", "Intel Pentium II 400", "Slot1", 6, 25, 400, 1998],
	["cpu_p3_600", "Intel Pentium III 600", "Slot1", 9, 30, 350, 1999],
	["cpu_cel500", "Intel Celeron 500", "Socket370", 6, 20, 120, 1999],
	["cpu_p3_1000", "Intel Pentium III 1 ГГц", "Socket370", 14, 30, 450, 2000],
	["cpu_axp1800", "AMD Athlon XP 1800+", "SocketA", 22, 60, 250, 2001],
	["cpu_p4_24", "Intel Pentium 4 2.4 ГГц", "Socket478", 25, 60, 300, 2002],
	["cpu_a64_3200", "AMD Athlon 64 3200+", "Socket754", 35, 89, 280, 2003],
	["cpu_p4_30ht", "Intel Pentium 4 3.0 HT", "Socket478", 33, 82, 280, 2004],
	["cpu_ax2_4200", "AMD Athlon 64 X2 4200+", "Socket939", 55, 89, 350, 2005],
	["cpu_c2d_e6600", "Intel Core 2 Duo E6600", "LGA775", 80, 65, 320, 2006],
	["cpu_c2q_q6600", "Intel Core 2 Quad Q6600", "LGA775", 110, 105, 280, 2007],
	["cpu_ph2_940", "AMD Phenom II X4 940", "AM3", 130, 125, 225, 2009],
	["cpu_i5_750", "Intel Core i5-750", "LGA1156", 140, 95, 200, 2009],
	["cpu_i5_2500k", "Intel Core i5-2500K", "LGA1155", 200, 95, 216, 2011],
	["cpu_fx8350", "AMD FX-8350", "AM3+", 210, 125, 195, 2012],
	["cpu_i7_3770k", "Intel Core i7-3770K", "LGA1155", 240, 77, 330, 2012],
	["cpu_i5_4460", "Intel Core i5-4460", "LGA1150", 230, 84, 180, 2014],
	["cpu_i7_4790k", "Intel Core i7-4790K", "LGA1150", 300, 88, 340, 2014],
	["cpu_g4560", "Intel Pentium G4560", "LGA1151", 180, 54, 64, 2017],
	["cpu_i5_7600k", "Intel Core i5-7600K", "LGA1151", 320, 91, 240, 2017],
	["cpu_r5_1600", "AMD Ryzen 5 1600", "AM4", 340, 65, 220, 2017],
	["cpu_r5_3600", "AMD Ryzen 5 3600", "AM4", 450, 65, 200, 2019],
	["cpu_i3_10100", "Intel Core i3-10100", "LGA1200", 380, 65, 120, 2020],
	["cpu_r5_5600x", "AMD Ryzen 5 5600X", "AM4", 600, 65, 300, 2020],
	["cpu_i5_12400", "Intel Core i5-12400F", "LGA1700", 620, 65, 180, 2022],
	["cpu_i7_13700k", "Intel Core i7-13700K", "LGA1700", 900, 180, 410, 2022],
	["cpu_r9_7950x", "AMD Ryzen 9 7950X", "AM5", 1050, 170, 700, 2022],
	["cpu_r5_7600", "AMD Ryzen 5 7600", "AM5", 750, 65, 230, 2023],
	["cpu_r7_7800x3d", "AMD Ryzen 7 7800X3D", "AM5", 1000, 120, 450, 2023],
	["cpu_i9_14900k", "Intel Core i9-14900K", "LGA1700", 1050, 253, 590, 2023],
	["cpu_r7_9800x3d", "AMD Ryzen 7 9800X3D", "AM5", 1150, 120, 480, 2024],
	["cpu_u9_285k", "Intel Core Ultra 9 285K", "LGA1851", 1100, 125, 590, 2024],
]
# --- Платы: id, имя, сокет, память, шина видео, накопители, TPM, цена, год
const MOBO_T := [
	["mb_430fx", "Intel 430FX Triton", "Socket5", "EDO", "PCI", ["ide"], false, 120, 1995],
	["mb_430vx", "ASUS P55T2P4 (430VX)", "Socket7", "EDO", "PCI", ["ide"], false, 130, 1996],
	["mb_mvp3", "Gigabyte GA-5AX (Super7)", "Socket7", "SDRAM", "AGP", ["ide"], false, 110, 1998],
	["mb_440bx", "ABIT BH6 (440BX)", "Slot1", "SDRAM", "AGP", ["ide"], false, 130, 1998],
	["mb_i815", "ASUS CUSL2 (i815)", "Socket370", "SDRAM", "AGP", ["ide"], false, 120, 2000],
	["mb_kt266", "MSI K7T266 Pro", "SocketA", "DDR", "AGP", ["ide"], false, 110, 2001],
	["mb_845pe", "ASUS P4PE (845PE)", "Socket478", "DDR", "AGP", ["ide"], false, 120, 2002],
	["mb_k8t800", "MSI K8T Neo (K8T800)", "Socket754", "DDR", "AGP", ["ide", "sata"], false, 110, 2003],
	["mb_nf4", "DFI LanParty nF4", "Socket939", "DDR", "PCIe", ["ide", "sata"], false, 150, 2005],
	["mb_p965", "ASUS P5B (P965)", "LGA775", "DDR2", "PCIe", ["ide", "sata"], false, 130, 2006],
	["mb_p35", "Gigabyte GA-P35-DS3", "LGA775", "DDR2", "PCIe", ["ide", "sata"], false, 120, 2007],
	["mb_790x", "ASUS M4A79 (790X)", "AM3", "DDR3", "PCIe", ["sata"], false, 120, 2009],
	["mb_p55", "MSI P55-GD65", "LGA1156", "DDR3", "PCIe", ["sata"], false, 140, 2009],
	["mb_p67", "ASUS P8P67", "LGA1155", "DDR3", "PCIe", ["sata"], false, 150, 2011],
	["mb_970", "Gigabyte 970A-DS3", "AM3+", "DDR3", "PCIe", ["sata"], false, 90, 2012],
	["mb_z77", "ASRock Z77 Extreme4", "LGA1155", "DDR3", "PCIe", ["sata"], false, 140, 2012],
	["mb_h81", "ASRock H81M", "LGA1150", "DDR3", "PCIe", ["sata"], false, 55, 2014],
	["mb_z97", "MSI Z97 Gaming 5", "LGA1150", "DDR3", "PCIe", ["sata", "nvme"], false, 150, 2014],
	["mb_b250", "ASUS B250M", "LGA1151", "DDR4", "PCIe", ["sata", "nvme"], true, 90, 2017],
	["mb_b350", "MSI B350 Tomahawk", "AM4", "DDR4", "PCIe", ["sata", "nvme"], true, 100, 2017],
	["mb_b450", "MSI B450 Tomahawk", "AM4", "DDR4", "PCIe", ["sata", "nvme"], true, 110, 2018],
	["mb_b550", "ASUS TUF B550", "AM4", "DDR4", "PCIe", ["sata", "nvme"], true, 140, 2020],
	["mb_h410", "Gigabyte H410M", "LGA1200", "DDR4", "PCIe", ["sata", "nvme"], true, 75, 2020],
	["mb_b660", "MSI B660M Mortar", "LGA1700", "DDR4", "PCIe", ["sata", "nvme"], true, 140, 2022],
	["mb_z790", "ASUS ROG Z790", "LGA1700", "DDR5", "PCIe", ["sata", "nvme"], true, 300, 2022],
	["mb_b650", "Gigabyte B650 Aorus", "AM5", "DDR5", "PCIe", ["sata", "nvme"], true, 180, 2022],
	["mb_x670", "ASUS ROG X670E", "AM5", "DDR5", "PCIe", ["sata", "nvme"], true, 400, 2022],
	["mb_z890", "MSI Z890 Tomahawk", "LGA1851", "DDR5", "PCIe", ["sata", "nvme"], true, 300, 2024],
]
# --- Память: id, тип, ГБ, цена, год
const RAM_T := [
	["ram_edo8", "EDO", 0.008, 250, 1995], ["ram_edo16", "EDO", 0.016, 400, 1996],
	["ram_sd32", "SDRAM", 0.032, 120, 1997], ["ram_sd64", "SDRAM", 0.064, 150, 1998],
	["ram_sd128", "SDRAM", 0.128, 140, 1999], ["ram_sd256", "SDRAM", 0.256, 180, 2000],
	["ram_ddr256", "DDR", 0.256, 90, 2001], ["ram_ddr512", "DDR", 0.512, 110, 2003], ["ram_ddr1g", "DDR", 1.0, 160, 2004],
	["ram_ddr2_1g", "DDR2", 1.0, 100, 2006], ["ram_ddr2_2g", "DDR2", 2.0, 120, 2007], ["ram_ddr2_4g", "DDR2", 4.0, 90, 2008],
	["ram_ddr3_4g", "DDR3", 4.0, 70, 2009], ["ram_ddr3_8g", "DDR3", 8.0, 80, 2011], ["ram_ddr3_16g", "DDR3", 16.0, 140, 2013],
	["ram_ddr4_8g", "DDR4", 8.0, 60, 2015], ["ram_ddr4_16g", "DDR4", 16.0, 80, 2017], ["ram_ddr4_32g", "DDR4", 32.0, 120, 2019],
	["ram_ddr5_16g", "DDR5", 16.0, 90, 2021], ["ram_ddr5_32g", "DDR5", 32.0, 110, 2022], ["ram_ddr5_64g", "DDR5", 64.0, 200, 2023],
]
# --- Видеокарты: id, имя, шина, мощность, Вт, ГБ видеопамяти, цена, год
const GPU_T := [
	["gpu_trio64", "S3 Trio64", "PCI", 1, 5, 0.002, 60, 1995],
	["gpu_voodoo", "3dfx Voodoo Graphics", "PCI", 3, 10, 0.004, 300, 1996],
	["gpu_tnt", "NVIDIA RIVA TNT", "AGP", 5, 12, 0.016, 200, 1998],
	["gpu_gf256", "NVIDIA GeForce 256", "AGP", 8, 15, 0.032, 250, 1999],
	["gpu_gf2gts", "NVIDIA GeForce2 GTS", "AGP", 12, 20, 0.032, 300, 2000],
	["gpu_gf3", "NVIDIA GeForce3", "AGP", 16, 25, 0.064, 350, 2001],
	["gpu_r9700", "ATI Radeon 9700 Pro", "AGP", 28, 40, 0.128, 400, 2002],
	["gpu_fx5900", "NVIDIA GeForce FX 5900", "AGP", 30, 60, 0.128, 400, 2003],
	["gpu_6800gt", "NVIDIA GeForce 6800 GT (AGP)", "AGP", 45, 70, 0.256, 400, 2004],
	["gpu_7800gt", "NVIDIA GeForce 7800 GT", "PCIe", 60, 80, 0.256, 450, 2005],
	["gpu_8800gtx", "NVIDIA GeForce 8800 GTX", "PCIe", 110, 155, 0.768, 600, 2006],
	["gpu_9800gt", "NVIDIA GeForce 9800 GT", "PCIe", 120, 105, 0.512, 180, 2008],
	["gpu_hd5850", "ATI Radeon HD 5850", "PCIe", 180, 150, 1.0, 260, 2009],
	["gpu_gtx460", "NVIDIA GeForce GTX 460", "PCIe", 190, 160, 1.0, 230, 2010],
	["gpu_gtx660", "NVIDIA GeForce GTX 660", "PCIe", 260, 140, 2.0, 230, 2012],
	["gpu_gtx760", "NVIDIA GeForce GTX 760", "PCIe", 300, 170, 2.0, 250, 2013],
	["gpu_gt710", "NVIDIA GT 710", "PCIe", 60, 19, 2.0, 40, 2014],
	["gpu_750ti", "NVIDIA GTX 750 Ti", "PCIe", 220, 60, 2.0, 150, 2014],
	["gpu_gtx970", "NVIDIA GTX 970", "PCIe", 430, 145, 4.0, 330, 2014],
	["gpu_1050ti", "NVIDIA GTX 1050 Ti", "PCIe", 330, 75, 4.0, 140, 2016],
	["gpu_1060", "NVIDIA GTX 1060", "PCIe", 500, 120, 6.0, 250, 2016],
	["gpu_1080", "NVIDIA GTX 1080", "PCIe", 750, 180, 8.0, 600, 2016],
	["gpu_2070", "NVIDIA RTX 2070", "PCIe", 800, 175, 8.0, 500, 2018],
	["gpu_1660s", "NVIDIA GTX 1660 Super", "PCIe", 600, 125, 6.0, 230, 2019],
	["gpu_3080", "NVIDIA RTX 3080", "PCIe", 1300, 320, 10.0, 700, 2020],
	["gpu_3060", "NVIDIA RTX 3060", "PCIe", 880, 170, 12.0, 330, 2021],
	["gpu_rx6600", "AMD RX 6600", "PCIe", 820, 132, 8.0, 330, 2021],
	["gpu_4090", "NVIDIA RTX 4090", "PCIe", 2200, 450, 24.0, 1600, 2022],
	["gpu_7900xtx", "AMD RX 7900 XTX", "PCIe", 1800, 355, 24.0, 1000, 2022],
	["gpu_4060", "NVIDIA RTX 4060", "PCIe", 950, 115, 8.0, 300, 2023],
	["gpu_4070", "NVIDIA RTX 4070", "PCIe", 1250, 200, 12.0, 600, 2023],
	["gpu_5070", "NVIDIA RTX 5070", "PCIe", 1450, 250, 12.0, 550, 2025],
	["gpu_5090", "NVIDIA RTX 5090", "PCIe", 2800, 575, 32.0, 2000, 2025],
]
# --- Накопители: id, имя, интерфейс, ГБ, скорость, цена, год
const STOR_T := [
	["hdd_850m", "HDD 850 МБ (IDE)", "ide", 0.85, 3, 250, 1995],
	["hdd_2g", "HDD 2 ГБ (IDE)", "ide", 2.0, 4, 250, 1997],
	["hdd_10g", "HDD 10 ГБ (IDE)", "ide", 10.0, 5, 150, 1999],
	["hdd_40g", "HDD 40 ГБ (IDE)", "ide", 40.0, 6, 120, 2001],
	["hdd_80g", "HDD 80 ГБ (IDE)", "ide", 80.0, 7, 100, 2003],
	["hdd_160g", "HDD 160 ГБ (SATA)", "sata", 160.0, 9, 90, 2005],
	["hdd_500g", "HDD 500 ГБ (SATA)", "sata", 500.0, 10, 90, 2007],
	["hdd_1t", "HDD 1 ТБ (SATA)", "sata", 1000.0, 10, 80, 2009],
	["ssd_120", "SSD 120 ГБ (SATA)", "sata", 120.0, 50, 150, 2011],
	["ssd_240", "SSD 240 ГБ (SATA)", "sata", 240.0, 50, 100, 2013],
	["ssd_512", "SSD 512 ГБ (SATA)", "sata", 512.0, 50, 120, 2015],
	["nvme_512", "NVMe 512 ГБ", "nvme", 512.0, 100, 150, 2017],
	["nvme_1t", "NVMe 1 ТБ", "nvme", 1000.0, 100, 110, 2019],
	["nvme_2t", "NVMe 2 ТБ", "nvme", 2000.0, 100, 150, 2021],
	["nvme_4t", "NVMe 4 ТБ", "nvme", 4000.0, 100, 280, 2024],
]
# --- Блоки питания: id, имя, Вт, КПД, дешёвый?, цена, год
const PSU_T := [
	["psu_at200", "AT 200 Вт", 200, 0.7, false, 40, 1995],
	["psu_atx250", "ATX 250 Вт", 250, 0.7, false, 40, 1997],
	["psu_atx300", "ATX 300 Вт", 300, 0.72, false, 45, 2000],
	["psu_noname400", "NoName 400 Вт «Супер-Мощь»", 400, 0.65, true, 20, 2002],
	["psu_350", "FSP 350 Вт", 350, 0.75, false, 50, 2003],
	["psu_450", "Thermaltake 450 Вт", 450, 0.78, false, 60, 2006],
	["psu_550b", "Corsair 550 Вт 80+ Bronze", 550, 0.85, false, 70, 2009],
	["psu_650b", "Seasonic 650 Вт 80+ Bronze", 650, 0.85, false, 75, 2012],
	["psu_750g", "Corsair RM750 80+ Gold", 750, 0.9, false, 110, 2015],
	["psu_850g", "be quiet! 850 Вт 80+ Gold", 850, 0.9, false, 130, 2018],
	["psu_1000g", "Corsair RM1000 80+ Gold", 1000, 0.9, false, 180, 2020],
	["psu_1200p", "Seasonic 1200 Вт 80+ Platinum", 1200, 0.92, false, 280, 2022],
]
# --- Кулеры: id, имя, охлаждение, цена, год
const COOL_T := [
	["cool_box95", "Боксовый радиатор с вентилятором", 20, 10, 1995],
	["cool_box05", "Боксовый кулер", 30, 10, 2005],
	["cool_zalman", "Zalman CNPS7700 (цветок)", 55, 50, 2005],
	["cool_212", "Cooler Master Hyper 212", 65, 35, 2010],
	["cool_d15", "Noctua NH-D15", 90, 100, 2014],
	["cool_aio240", "Водянка 240 мм", 85, 110, 2015],
	["cool_wraith", "AMD Wraith Prism (бокс)", 40, 15, 2017],
	["cool_aio360", "Водянка 360 мм", 100, 150, 2018],
]

# gen: 0 DOS, 1 Win95, 2 Win98, 3 Win2000, 4 XP, 5 Vista, 6 Win7, 7 Win8, 8 Win10/Linux, 9 Win11
var os_list := {
	"dos":    {"name": "MS-DOS 6.22", "year": 1995, "gen": 0, "price": 10, "min_ram": 0.002, "gb": 0.01, "time": 1.5, "fps": 1.0, "linux": false, "media": "floppy"},
	"win95":  {"name": "Windows 95", "year": 1995, "gen": 1, "price": 30, "min_ram": 0.008, "gb": 0.1, "time": 2.5, "fps": 1.0, "linux": false, "media": "floppy"},
	"win98":  {"name": "Windows 98", "year": 1998, "gen": 2, "price": 40, "min_ram": 0.016, "gb": 0.3, "time": 2.5, "fps": 1.0, "linux": false, "media": "cd"},
	"win2000":{"name": "Windows 2000", "year": 2000, "gen": 3, "price": 60, "min_ram": 0.064, "gb": 1.0, "time": 3.0, "fps": 1.0, "linux": false, "media": "cd"},
	"winxp":  {"name": "Windows XP", "year": 2001, "gen": 4, "price": 60, "min_ram": 0.064, "gb": 1.5, "time": 3.0, "fps": 1.0, "linux": false, "media": "cd"},
	"ubuntu": {"name": "Ubuntu Linux", "year": 2004, "gen": 8, "price": 0, "min_ram": 0.256, "gb": 5.0, "time": 3.0, "fps": 0.9, "linux": true, "media": "usb"},
	"mint":   {"name": "Linux Mint", "year": 2006, "gen": 8, "price": 0, "min_ram": 0.512, "gb": 8.0, "time": 2.5, "fps": 0.9, "linux": true, "media": "usb"},
	"vista":  {"name": "Windows Vista", "year": 2007, "gen": 5, "price": 80, "min_ram": 0.512, "gb": 15.0, "time": 3.5, "fps": 0.95, "linux": false, "media": "cd"},
	"win7":   {"name": "Windows 7", "year": 2009, "gen": 6, "price": 70, "min_ram": 1.0, "gb": 16.0, "time": 3.0, "fps": 1.0, "linux": false, "media": "usb"},
	"win8":   {"name": "Windows 8.1", "year": 2012, "gen": 7, "price": 70, "min_ram": 1.0, "gb": 20.0, "time": 3.0, "fps": 1.0, "linux": false, "media": "usb"},
	"win10":  {"name": "Windows 10", "year": 2015, "gen": 8, "price": 80, "min_ram": 2.0, "gb": 20.0, "time": 3.5, "fps": 1.0, "linux": false, "media": "usb", "min_cpu_year": 2004},
	"win11":  {"name": "Windows 11", "year": 2021, "gen": 9, "price": 100, "min_ram": 4.0, "gb": 27.0, "time": 4.0, "fps": 1.0, "linux": false, "media": "usb", "need_w11": true},
}

# Игры: название, год, «тяжесть» (0.3 лёгкая … 1.4 тяжёлая), цена, мин. ОС (gen), [макс. ОС], флаги
const GAME_T := [
	["doom2", "DOOM II", 1994, 0.8, 40, 0, 2],
	["warcraft2", "Warcraft II", 1995, 0.7, 40, 0, 4],
	["quake", "Quake", 1996, 1.0, 45, 0, 4],
	["diablo", "Diablo", 1996, 0.6, 45, 1],
	["redalert", "C&C: Red Alert", 1996, 0.6, 40, 0, 4],
	["fallout", "Fallout", 1997, 0.5, 40, 1],
	["halflife", "Half-Life", 1998, 1.0, 45, 1],
	["starcraft", "StarCraft", 1998, 0.4, 40, 1],
	["ut99", "Unreal Tournament", 1999, 1.1, 45, 1],
	["nfs4", "Need for Speed: High Stakes", 1999, 1.0, 40, 1],
	["sims", "The Sims", 2000, 0.7, 45, 1],
	["diablo2", "Diablo II", 2000, 0.6, 45, 1],
	["maxpayne", "Max Payne", 2001, 1.1, 45, 2],
	["gta3", "GTA III", 2002, 1.0, 45, 2],
	["warcraft3", "Warcraft III", 2002, 0.9, 45, 2],
	["cs16", "Counter-Strike 1.6", 2003, 0.4, 20, 2],
	["vicecity", "GTA Vice City", 2003, 1.0, 40, 2],
	["hl2", "Half-Life 2", 2004, 1.2, 50, 4],
	["wow", "World of Warcraft", 2004, 0.8, 50, 4],
	["farcry", "Far Cry", 2004, 1.3, 50, 3],
	["doom3", "Doom 3", 2004, 1.4, 50, 3],
	["gtasa", "GTA San Andreas", 2005, 1.0, 40, 4],
	["nfsmw", "NFS Most Wanted", 2005, 1.1, 50, 4],
	["roblox", "Roblox", 2006, 0.3, 0, 4],
	["stalker", "S.T.A.L.K.E.R.: Тень Чернобыля", 2007, 1.2, 50, 4],
	["crysis", "Crysis", 2007, 1.8, 50, 4],
	["cod4", "Call of Duty 4", 2007, 1.0, 50, 4],
	["gta4", "GTA IV", 2008, 1.4, 50, 4],
	["minecraft", "Minecraft", 2009, 0.4, 27, 4],
	["l4d2", "Left 4 Dead 2", 2009, 0.8, 30, 4],
	["skyrim", "Skyrim", 2011, 1.0, 60, 4],
	["bf3", "Battlefield 3", 2011, 1.3, 60, 5],
	["terraria", "Terraria", 2011, 0.2, 10, 4],
	["csgo", "CS:GO", 2012, 0.6, 15, 4],
	["dota2", "Dota 2", 2013, 0.6, 0, 6],
	["witcher3", "The Witcher 3", 2015, 1.3, 60, 6],
	["gta5", "GTA V", 2015, 1.0, 60, 6],
	["stardew", "Stardew Valley", 2016, 0.2, 15, 6],
	["pubg", "PUBG", 2017, 1.2, 30, 6, 99, "no_linux"],
	["fortnite", "Fortnite", 2017, 0.8, 0, 6, 99, "no_linux"],
	["hollowknight", "Hollow Knight", 2017, 0.3, 15, 6],
	["amongus", "Among Us", 2018, 0.2, 5, 6],
	["rdr2", "Red Dead Redemption 2", 2019, 1.2, 60, 8],
	["apex", "Apex Legends", 2019, 0.9, 0, 6, 99, "no_linux"],
	["cyberpunk", "Cyberpunk 2077", 2020, 1.4, 60, 8],
	["valorant", "Valorant", 2020, 0.5, 0, 6, 99, "no_linux"],
	["genshin", "Genshin Impact", 2020, 0.8, 0, 6],
	["eldenring", "Elden Ring", 2022, 1.1, 60, 8],
	["cs2", "Counter-Strike 2", 2023, 0.9, 0, 8],
	["starfield", "Starfield", 2023, 1.4, 70, 8],
	["wukong", "Black Myth: Wukong", 2024, 1.4, 60, 8],
	["stalker2", "S.T.A.L.K.E.R. 2", 2024, 1.5, 60, 8],
	["techverse", "miron1126 TechVerse", 2026, 0.4, 0, 8, 99, "miron"],
	["flashlab", "miron1126 Flash Lab", 2026, 0.4, 0, 8, 99, "miron"],
]
var games := {}

# level: 1 — ловит Free, 2 — нужен PRO, 3 — только переустановка ОС
var viruses := {
	"boot":    {"name": "Boot.Floppy", "fps": 0.9, "level": 1, "year": 1995, "desc": "загрузочный вирус с дискеты"},
	"macro":   {"name": "Macro.Docs", "fps": 0.95, "level": 1, "year": 1997, "desc": "портит документы Word"},
	"flip":    {"name": "Joke.FlipScreen", "fps": 0.95, "level": 1, "year": 1996, "desc": "переворачивает экран вверх ногами"},
	"cursor":  {"name": "Joke.CursorRunner", "fps": 0.95, "level": 1, "year": 1998, "desc": "курсор убегает от мышки"},
	"romance": {"name": "Romance.Worm", "fps": 0.85, "level": 1, "year": 2000, "desc": "рассылает «письма любви» всем контактам"},
	"worm":    {"name": "Worm.NetSpread", "fps": 0.85, "level": 1, "year": 2001, "desc": "размножается по сети"},
	"adware":  {"name": "Adware.PopUp", "fps": 0.9, "level": 1, "year": 2003, "desc": "реклама везде"},
	"kitty":   {"name": "Joke.KittyFlood", "fps": 0.9, "level": 1, "year": 2005, "desc": "котики по всему экрану (Буся ревнует)"},
	"rootkit": {"name": "Rootkit.Hidden", "fps": 0.8, "level": 2, "year": 2005, "desc": "прячется от простых антивирусов"},
	"spy":     {"name": "Spyware.KeyLogger", "fps": 0.95, "level": 2, "year": 2006, "desc": "ворует пароли"},
	"loud":    {"name": "Joke.LoudMusic", "fps": 0.95, "level": 1, "year": 2008, "desc": "включает музыку на полную"},
	"miner":   {"name": "Trojan.CoinMiner", "fps": 0.6, "level": 1, "year": 2011, "desc": "майнит крипту на видеокарте"},
	"ransom":  {"name": "Ransom.Locker", "fps": 0.0, "level": 3, "year": 2013, "desc": "зашифровал файлы и требует выкуп"},
	"cry":     {"name": "Ransom.WannaWeep", "fps": 0.0, "level": 3, "year": 2017, "desc": "шифровальщик-эпидемия"},
}

# как вирус выглядит в диспетчере задач / автозагрузке (ручное удаление)
const VPROC := {
	"boot": {"where": "mbr"},
	"macro": {"where": "template"},
	"flip": {"proc": "flipscr.exe", "cpu": 3},
	"cursor": {"proc": "mouserun.exe", "cpu": 4},
	"romance": {"proc": "wscript.exe", "cpu": 6, "file": "LOVE-LETTER-FOR-YOU.TXT.vbs"},
	"worm": {"proc": "netspread.exe", "cpu": 14, "mem": 30},
	"adware": {"proc": "PopUpHelper.exe", "cpu": 9, "mem": 40},
	"kitty": {"proc": "kitty_love.exe", "cpu": 5},
	"rootkit": {"where": "hidden"},
	"spy": {"proc": "svch0st.exe", "cpu": 2, "mem": 8},
	"loud": {"proc": "superplayer.exe", "cpu": 7},
	"miner": {"proc": "svchost.exe", "cpu": 93, "mem": 600, "file": "svchost.exe (в папке Temp!)"},
	"ransom": {"where": "locked"},
	"cry": {"where": "locked"},
}

var tools := {
	"screwdriver": {"name": "Отвёртка", "price": 0, "desc": "Снимать и ставить детали"},
	"usb":         {"name": "Загрузочная флешка", "price": 15, "desc": "Установка ОС с флешки", "year": 2003},
	"floppy":      {"name": "Загрузочные дискеты", "price": 5, "desc": "Для DOS и Windows 95"},
	"cdrom":       {"name": "CD-привод для мастерской", "price": 60, "desc": "Установка ОС с CD (98, 2000, XP, Vista)"},
	"av_free":     {"name": "Антивирус Free", "price": 0, "desc": "Ловит простые вирусы", "av": 1},
	"brush":       {"name": "Кисточка + сжатый воздух", "price": 20, "desc": "Чистка ПК от пыли"},
	"paste":       {"name": "Термопаста", "price": 10, "desc": "Замена термопасты на процессоре"},
	"cleaner":     {"name": "Программа очистки диска", "price": 25, "desc": "Удаляет весь мусор с диска", "year": 1998},
	"multimeter":  {"name": "Мультиметр", "price": 35, "desc": "Проверка блока питания"},
	"postcard":    {"name": "POST-карта", "price": 60, "desc": "Показывает, какая деталь сломана"},
	"compressor":  {"name": "Компрессор", "price": 150, "desc": "Сдувает пыль втрое быстрее"},
	"extdisk":     {"name": "Внешний диск для бэкапов", "price": 40, "desc": "Сохраняет файлы клиента перед переустановкой"},
	"av_pro":      {"name": "Антивирус PRO", "price": 120, "desc": "Находит руткиты и шпионов", "av": 2, "year": 2003},
}

## События эпох: год → текст
const EVENTS := {
	1995: "Вышла Windows 95! Кнопка «Пуск» покоряет мир.",
	1996: "3dfx Voodoo — первые 3D-ускорители. Все хотят Quake!",
	1998: "Вышла Windows 98 и Half-Life. Видеокарты переходят на AGP.",
	1999: "Паника «проблемы 2000 года»! Клиенты несут ПК на проверку.",
	2000: "Наступил 2000 год — ничего не сломалось :) Вышла Windows 2000.",
	2001: "Вышла Windows XP! Эпидемия червя-«любовного письма».",
	2003: "Запустился Steam и Miron1126 Launcher! Игры теперь можно качать.",
	2004: "Появился SATA и PCI Express. Half-Life 2 и Doom 3 требуют мощи.",
	2006: "Core 2 Duo и DirectX 10. Эпоха двухъядерных процессоров.",
	2007: "Вышла Windows Vista и Crysis. «А Crysis потянет?»",
	2009: "Вышла Windows 7. Появился биткоин — майнинг на процессоре!",
	2011: "SSD становятся доступными. Майнеры переходят на видеокарты.",
	2012: "Вышла Windows 8 с плиткой вместо «Пуска».",
	2014: "Закончилась поддержка Windows XP — все обновляются!",
	2015: "Вышла Windows 10. NVMe-диски на подходе.",
	2017: "Ryzen вернул AMD в игру. Эпидемия шифровальщика!",
	2018: "Крипто-крах: фермы невыгодны, видеокарты дешевеют.",
	2020: "Пандемия: все работают из дома — бум заказов на ПК и вебки. Закончилась поддержка Windows 7.",
	2021: "Вышла Windows 11 — нужен TPM 2.0 и новый процессор.",
	2022: "Ещё один крипто-крах. DDR5 и RTX 4090.",
	2025: "RTX 5090 — скальперы скупают всё в первый день!",
	2026: "Ты дошёл до 2026! Дальше — в обновлениях. Ждите!",
}

# Этапы мастерской: название, цена переезда, нужная репутация, аренда (раз в 5 дней), макс. верстаков, макс. работников, цена верстака
const STAGES := [
	{"name": "Комната", "cost": 0, "rep": 0, "rent": 0, "benches": 1, "workers": 0, "bench_cost": 0,
		"desc": "Твоя комната. Один стол, кошка Буся и большие мечты."},
	{"name": "Гараж", "cost": 1500, "rep": 15, "rent": 40, "benches": 3, "workers": 2, "bench_cost": 250,
		"desc": "Ворота-витрина, верстаки вдоль стен. Можно нанять первых помощников."},
	{"name": "Магазин", "cost": 9000, "rep": 50, "rent": 160, "benches": 5, "workers": 6, "bench_cost": 600,
		"desc": "Витрина на улице, больше клиентов. Сам ставишь цены на ремонт."},
	{"name": "Офис", "cost": 45000, "rep": 140, "rent": 650, "benches": 9, "workers": 15, "bench_cost": 1500,
		"desc": "Отделы ремонта и сборки, переговорка, кофемашина."},
	{"name": "Небоскрёб", "cost": 260000, "rep": 350, "rent": 3200, "benches": 17, "workers": 45, "bench_cost": 4000,
		"desc": "Этажи-отделы, дата-центр и кабинет директора с видом на Техноград."},
]

# Город Техноград: районы. dist: 0 рядом, 1 средне, 2 далеко. pos — место на карте (0..1)
const DISTRICTS := [
	{"id": "center", "name": "Центр", "dist": 0, "mult": 1.25, "year": 1995, "pos": Vector2(0.48, 0.42), "col": Color("#ff8a1f"),
		"clients": ["Офис «Ромашка»", "Бухгалтер Ольга", "Блогер Макс"]},
	{"id": "sleep", "name": "Спальный район", "dist": 0, "mult": 1.0, "year": 1995, "pos": Vector2(0.24, 0.62), "col": Color("#66bb6a"),
		"clients": ["Бабушка Галя", "Школьник Петя", "Сосед Серёга", "Дядя Коля"]},
	{"id": "students", "name": "Студгородок", "dist": 1, "mult": 0.95, "year": 1995, "pos": Vector2(0.72, 0.68), "col": Color("#4aa3ff"),
		"clients": ["Студентка Аня", "Геймер Тимур", "Программист Илья"]},
	{"id": "industry", "name": "Промзона", "dist": 1, "mult": 1.35, "year": 1997, "pos": Vector2(0.2, 0.25), "col": Color("#9aa0a8"),
		"clients": ["Дальнобойщик Гена", "Офис «Ромашка»"]},
	{"id": "cottage", "name": "Коттеджи", "dist": 2, "mult": 1.9, "year": 1999, "pos": Vector2(0.84, 0.2), "col": Color("#ffd54f"),
		"clients": ["Стример Кирилл", "Киберспортсмен Дима", "Блогер Макс"]},
	{"id": "city", "name": "Бизнес-сити", "dist": 2, "mult": 1.7, "year": 2008, "pos": Vector2(0.62, 0.16), "col": Color("#ab47bc"),
		"clients": ["Программист Илья", "Бухгалтер Ольга", "Офис «Ромашка»"]},
]

# Транспорт: название, с какого года, цена, до какого района доезжает, бонус к оплате
const TRANSPORT := [
	{"name": "Велосипед", "year": 1995, "price": 0, "reach": 0, "bonus": 0.0, "speed": 1.0},
	{"name": "Подержанная машина", "year": 1998, "price": 2500, "reach": 2, "bonus": 0.0, "speed": 1.8},
	{"name": "Фургон мастерской", "year": 2008, "price": 12000, "reach": 2, "bonus": 0.15, "speed": 2.2},
]

# Компьютерный клуб: хит эпохи, в который все хотят играть
const CLUB_HITS := [[1995, "doom2"], [1996, "quake"], [1998, "starcraft"], [1999, "halflife"], [2003, "cs16"], [2004, "wow"],
	[2007, "cod4"], [2012, "csgo"], [2013, "dota2"], [2017, "pubg"], [2018, "fortnite"], [2020, "valorant"], [2023, "cs2"]]
# уровни клуба: мест, цена улучшения, нужный этап мастерской
const CLUB_LEVELS := [
	{"name": "Подвал на 4 места", "seats": 4, "cost": 2000, "stage": 1},
	{"name": "Клуб на 10 мест", "seats": 10, "cost": 15000, "stage": 2},
	{"name": "Киберарена на 30 мест", "seats": 30, "cost": 80000, "stage": 3},
]
const CLUB_EXTRAS := {
	"bar": {"name": "Бар со снеками", "price": 800, "year": 1995, "desc": "Газировка и чипсы: +$2 с каждого посетителя"},
	"av": {"name": "Антивирус на все ПК", "price": 300, "year": 1995, "desc": "Вирусы на клубных ПК почти не заводятся"},
	"console": {"name": "Консольная зона", "price": 1500, "year": 2000, "desc": "Диван, телевизор и приставки: +$60 в день"},
	"vr": {"name": "VR-зона", "price": 6000, "year": 2016, "desc": "Шлемы виртуальной реальности: +$250 в день"},
}

const WORKER_NAMES := ["Антон", "Вика", "Егор", "Лена", "Паша", "Даша", "Костя", "Маша", "Влад", "Оля", "Артём", "Катя",
	"Гоша", "Света", "Рома", "Надя", "Слава", "Юля", "Миша", "Ира", "Денис", "Аня", "Стас", "Таня", "Женя", "Полина"]

const CLIENTS := [
	"Школьник Петя", "Бабушка Галя", "Стример Кирилл", "Офис «Ромашка»", "Геймер Тимур",
	"Дядя Коля", "Студентка Аня", "Бухгалтер Ольга", "Блогер Макс", "Сосед Серёга",
	"Программист Илья", "Киберспортсмен Дима", "Учительница Марина", "Дальнобойщик Гена",
]


func _init() -> void:
	for r in CPU_T:
		parts[r[0]] = {"slot": "cpu", "name": r[1], "socket": r[2], "score": r[3], "tdp": r[4], "price": r[5], "year": r[6], "w11": r[6] >= 2018}
	for r in MOBO_T:
		parts[r[0]] = {"slot": "mobo", "name": r[1], "socket": r[2], "ram": r[3], "bus": r[4], "stor": r[5], "tpm": r[6], "price": r[7], "year": r[8]}
	for r in RAM_T:
		parts[r[0]] = {"slot": "ram", "name": "%s %s" % [r[1], gb_text(r[2])], "ram": r[1], "gb": r[2], "price": r[3], "year": r[4]}
	for r in GPU_T:
		parts[r[0]] = {"slot": "gpu", "name": r[1], "bus": r[2], "score": r[3], "watt": r[4], "vram": r[5], "price": r[6], "year": r[7]}
	for r in STOR_T:
		parts[r[0]] = {"slot": "storage", "name": r[1], "iface": r[2], "gb": r[3], "speed": r[4], "price": r[5], "year": r[6]}
	for r in PSU_T:
		parts[r[0]] = {"slot": "psu", "name": r[1], "watt": r[2], "eff": r[3], "cheap": r[4], "price": r[5], "year": r[6]}
	for r in COOL_T:
		parts[r[0]] = {"slot": "cooler", "name": r[1], "cool": r[2], "price": r[3], "year": r[4]}
	for r in GAME_T:
		var y: int = r[2]
		var w: float = r[3]
		var g := {"name": r[1], "year": y, "price": r[4], "min_gen": r[5],
			"cpu": max(1.0, by_year(MID_CPU, y) * w), "gpu": max(1.0, by_year(MID_GPU, y) * w),
			"ram": by_year(MID_RAM, y) * clamp(w, 0.5, 1.3), "gb": by_year(MID_SIZE, y) * clamp(w, 0.2, 1.5)}
		if r.size() > 6:
			g["max_gen"] = r[6]
		if r.size() > 7:
			g[r[7]] = true
		games[r[0]] = g


static func by_year(table: Dictionary, year: int) -> float:
	var best := 0.0
	var by := -1
	for k in table:
		if int(k) <= year and int(k) > by:
			by = int(k)
			best = float(table[k])
	if by == -1:
		return float(table[table.keys().min()])
	return best


static func gb_text(gb: float) -> String:
	if gb < 1.0:
		return "%d МБ" % int(round(gb * 1000.0))
	if gb >= 1000.0:
		return "%s ТБ" % str(snapped(gb / 1000.0, 0.1)).trim_suffix(".0")
	return "%d ГБ" % int(gb)


func part(id: String) -> Dictionary:
	return parts.get(id, {})


## Цена детали в данном году: новинка дорогая, старое дешевеет
func price_in(id: String, year: int) -> int:
	var p := part(id)
	if p.is_empty():
		return 0
	var age: int = max(0, year - int(p["year"]))
	return max(1, int(float(p["price"]) * max(0.15, 1.0 - 0.13 * age)))


## Есть ли деталь в магазине в этом году (новые 8 лет, потом только барахолка)
func in_shop(id: String, year: int) -> bool:
	var y := int(part(id)["year"])
	return y <= year and year - y <= 8


func part_desc(id: String) -> String:
	var p := part(id)
	if p.is_empty():
		return "?"
	match p["slot"]:
		"mobo":
			return "%s · %s · %s · %s · %s%s" % [p["name"], p["socket"], p["ram"], p["bus"], "/".join(p["stor"]).to_upper(), " · TPM" if p["tpm"] else ""]
		"cpu":
			return "%s · %s · мощность %d · %d Вт" % [p["name"], p["socket"], p["score"], p["tdp"]]
		"cooler":
			return "%s · охлаждение %d" % [p["name"], p["cool"]]
		"ram":
			return p["name"]
		"gpu":
			return "%s · %s · мощность %d · %s · %d Вт" % [p["name"], p["bus"], p["score"], gb_text(p["vram"]), p["watt"]]
		"storage":
			return "%s · скорость %d" % [p["name"], p["speed"]]
		"psu":
			return p["name"] + (" (дешёвый, может бахнуть!)" if p["cheap"] else "")
	return p["name"]


func parts_for_slot(slot: String) -> Array:
	var res := []
	for id in parts:
		if parts[id]["slot"] == slot:
			res.append(id)
	res.sort_custom(func(a, b): return int(parts[a]["year"]) < int(parts[b]["year"]))
	return res


func available(slot: String, year: int) -> Array:
	return parts_for_slot(slot).filter(func(id): return in_shop(id, year))


func os_available(year: int) -> Array:
	return os_list.keys().filter(func(id): return int(os_list[id]["year"]) <= year)


func games_available(year: int) -> Array:
	var res := games.keys().filter(func(id): return int(games[id]["year"]) <= year)
	res.sort_custom(func(a, b): return int(games[a]["year"]) < int(games[b]["year"]))
	return res
