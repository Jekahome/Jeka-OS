# How to create your own OS

[The little book about OS development](https://littleosbook.github.io/)

[OSDev Wiki — техническая библия для самописных ОС](https://wiki.osdev.org/Expanded_Main_Page)


## Multiboot и MBR


#### MBR-загрузчик (классический путь)

**MBR (Master Boot Record)** — это первые 512 байт жёсткого диска, где хранится маленькая программа-загрузчик.

**Особенности:**

1. **Размер ограничен**: всего 512 байт, из которых 446 байт реально кода.
2. **Очень низкоуровневое программирование**: приходится писать весь загрузчик вручную на ассемблере, чтобы:
   * перевести процессор в защищённый режим,
   * настроить стек,
   * загрузить ваше ядро в память,
   * обработать переход из реального режима x86.
3. **Нет стандартного интерфейса**: вся логика загрузки, поддержка модулей, карты памяти — всё делает разработчик сам.
4. **Совместимость**: MBR работает практически на всех BIOS, но UEFI уже не поддерживает напрямую MBR (или требует CSM).

То есть, если делать ОС через MBR, вы сами делаете «весь стек» загрузки и очень быстро упираетесь в ассемблер.


#### Multiboot / Multiboot2

**Multiboot2** — это стандарт между загрузчиком (например, GRUB) и ядром ОС.

**Преимущества:**

1. **Грузчик делает всю грязную работу**:
   * переводит процессор в защищённый режим,
   * настраивает память,
   * отключает прерывания,
   * передаёт карту памяти, командную строку и фреймбуфер (VGA/UEFI) в ядро.
2. **Стандартизированный интерфейс**: ядро просто проверяет «заголовок Multiboot2» и получает все данные от GRUB.
3. **Поддержка модулей и фреймбуфера**: GRUB может подгружать драйверы, initrd, шрифты и т.д., передавая их ядру.
4. **Простота разработки**: можно писать ядро почти на C, не заморачиваясь с реальным режимом и MBR.

**Минусы:**

* Нужно использовать загрузчик (GRUB или Limine).
* Немного больше зависимость от стандарта (не полностью «чистое» MBR-загрузочное ядро).


**Итоговое сравнение**

| Характеристика         | MBR                  | Multiboot2                                 |
| ---------------------- | -------------------- | ------------------------------------------ |
| Размер загрузчика      | ≤446 байт            | ~неограничен (GRUB)                        |
| Уровень сложности      | Очень низкоуровневый | Средний/высокий (C)                        |
| Стандарт/совместимость | С BIOS почти везде   | Только с загрузчиком                       |
| Передача данных ядру   | Своими силами        | Стандартизированно через Multiboot2 header |
| Работа с модулями      | Своими силами        | Поддержка GRUB                             |
| Простота разработки    | Тяжело               | Проще, C, почти без ассемблера             |

Вывод: **Multiboot2 удобнее для новичков и для разработки ОС на C**, потому что освобождает от низкоуровневых деталей MBR.

 
---


## QEMU

Install:
```
sudo apt update
sudo apt install qemu-kvm qemu-system qemu-system-common qemu-system-gui qemu-utils virt-manager bridge-utils libvirt-daemon-system libvirt-clients qemu-system-i386
```


|Пакет              |Зачем нужен|
|-------------------|-----------|
|qemu-kvm           | Основной ускоритель KVM (аппаратная виртуализация)|
|qemu-system        | "Метапакет, который тянет все qemu-system-* (x86_64, arm, riscv и т.д.)"|
|qemu-system-common | Общие файлы|
|qemu-system-gui    | Встроенный графический интерфейс QEMU (окно с видео)|
|qemu-utils         | Утилиты вроде qemu-img (создание/конвертация дисков)|
|virt-manager       | Самый удобный графический менеджер виртуальных машин |(virt-manager + virt-viewer)|
|libvirt-daemon-system + libvirt-clients,Демон libvirt |(нужен для работы virt-manager и команды virsh)|
|bridge-utils        |Утилиты для создания сетевых мостов (если хочешь нормальный интернет в ВМ)|
|qemu-system-i386    |это только 32-битный x86|

Если нужно запускать QEMU «вручную» без virt-manager
```
sudo apt install qemu-kvm qemu-system qemu-utils
```

После установки всех пакетов просто запустить из меню или терминала:
```
virt-manager
```

---

## 16-битное ядро (способ MBR)

Для запуска вашей примитивной операционной системы, которая просто выводит "Hello, World!", вам действительно потребуется загрузчик (bootloader), написанный на ассемблере.

1. Загрузочный Сектор (Boot Sector)
   Первая вещь, которую будет искать BIOS или UEFI на вашем диске (физическом или виртуальном), — это загрузочный сектор (первые 512 байт).
   * Назначение: Этот сектор должен содержать ваш загрузчик.
   * Магическое число: Чтобы BIOS/UEFI посчитал сектор загрузочным, последние два байта должны быть `0xAA55`


   **Ассемблер (16-битный режим)**

   Ваш загрузчик запускается в реальном (16-битном) режиме процессора.
   * Адрес: Он загружается по фиксированному адресу: `0x7C00`
   * Задача: Основная задача вашего примитивного загрузчика — это вывод строки на экран.

   **Пример кода (NASM синтаксис)**

   Для вывода символов на экран в 16-битном режиме вы будете использовать прерывания BIOS, в частности, функцию `0x10` (видеосервисы).

   ```
    ; file: boot_sect.asm

    org 0x7c00          ; Загружаем по адресу 0x7c00

    ; Вывод строки 'Hello, World!'
    mov si, hello_msg   ; Загружаем адрес строки в регистр SI
    call print_string   ; Вызываем нашу процедуру вывода

    jmp $               ; Бесконечный цикл, чтобы процессор не продолжил выполнение мусора

    print_string:
        mov ah, 0x0e    ; Функция Teletype output (BIOS int 0x10)
    .loop:
        lodsb           ; Загрузить байт из [si] в AL, увеличить SI
        cmp al, 0       ; Сравнить AL с нулём (null-terminator)
        je .done        ; Если равно нулю, завершить
        int 0x10        ; Вызвать прерывание BIOS
        jmp .loop
    .done:
        ret

    hello_msg db 'Hello, World!', 0  ; Строка, завершенная нулём

    ; Заполнение оставшихся байтов нулями и 'магическое число'
    times 510 - ($ - $$) db 0
    dw 0xaa55           ; Магический загрузочный номер
    ```

2. Сборка и Запуск

После написания кода вам нужно будет:

   * Собрать (скомпилировать) загрузчик: Используйте ассемблер, например NASM.

    ```
    $ sudo apt install nasm
    $ nasm -f bin boot_sect.asm -o boot.bin
    ```
    
    потом проверяешь размер:
    ```
    $ ls -l boot.bin        # должен быть ровно 512 байт

       -rw-rw-r-- 1 jeka jeka 512 Dec  2 16:38 boot.bin

    $ hexdump -C boot.bin | tail -n 2   # в конце должны быть 55 AA

       000001f0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 55 aa  |..............U.|
       00000200
    ```



   * Создать образ диска: Ваш boot.bin должен стать первым сектором образа диска. Вы можете просто скопировать его в файл образа, поскольку он уже имеет размер 512 байт.

   * Запустить на виртуальной машине: Используйте эмулятор, например QEMU или VirtualBox, чтобы загрузить ваш образ.

    Пример для QEMU:
    ```
    $ qemu-system-i386 -fda boot.bin

    WARNING: Image format was not specified for 'boot.bin' and probing guessed raw.
             Automatically detecting the format is dangerous for raw images, write operations on block 0 will be restricted.
             Specify the 'raw' format explicitly to remove the restrictions.


    Выход:
    Ctrl+Alt+2
    quit
    ``` 
    

## Кросс-Компилятор для 32-х битного защищенного режима

Переход в 32-битный Защищенный Режим (Protected Mode): Это необходимо, чтобы работать с современными возможностями процессора, использовать больше оперативной памяти и запускать более сложный код (например, написанный на C).
 
Основная часть ОС на C: После перехода в 32-битный режим, ваш загрузчик на ассемблере может загрузить и передать управление более сложной части вашей ОС, написанной на C.
 

В 32-битном режиме вы получаете доступ ко всей памяти (более $1$ МБ), и можете начать писать более сложный код на C.
 
### Кросс-Компилятор i686-elf-gcc

Вам понадобится кросс-компилятор для i686-elf (или i386-elf), так как стандартный GCC на вашей машине не генерирует 32-битные ELF-файлы без стандартной библиотеки.

<details>

<summary>Установка Кросс-Компилятора i686-elf-gcc</summary>


Пошаговый план, чтобы вы могли собрать необходимые инструменты. **Вам не нужно искать никаких файлов**, кроме исходного кода самих инструментов, который вы скачаете.

Давайте сфокусируемся на инструментах **Binutils** и **GCC** и том, как их собрать, чтобы получить команду `i686-elf-gcc`.


#### Подробная Инструкция по Сборке Кросс-Компилятора

Для создания кросс-компилятора `i686-elf-gcc` вам нужно собрать два основных пакета:

1.  **Binutils (GNU Binary Utilities):** Содержит компоновщик (`ld`), ассемблер (`as`) и другие инструменты для работы с бинарными файлами.

2.  **GCC (GNU Compiler Collection):** Сам компилятор C.

#### Предварительная подготовка

Предполагается, что вы используете Linux (или WSL). Убедитесь, что у вас установлен `build-essential` и инструменты для разработки:

```bash
sudo apt install build-essential bison \
flex libgmp3-dev libmpc-dev libmpfr-dev texinfo wget
```

#### Шаг 1: Загрузка Исходного Кода

Сначала создадим рабочую директорию и скачаем исходники.

```bash
# 1. Создаем рабочую папку
mkdir -p $HOME/os_dev/src
cd $HOME/os_dev/src

# 2. Скачиваем исходники (актуальные версии, например)
wget https://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.xz
wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz

# 3. Распаковываем
tar -xf binutils-2.40.tar.xz
tar -xf gcc-13.2.0.tar.xz
```

#### Шаг 2: Настройка Переменных Среды

Это очень важный шаг. Мы определяем, как будет называться наш компилятор (`i686-elf`) и куда он будет установлен (`$HOME/os_dev/cross`).

```bash
# Определяем целевую архитектуру
export TARGET=i686-elf

# Определяем папку, куда будут установлены инструменты
export PREFIX="$HOME/os_dev/cross"

# Добавляем путь установки в PATH (чтобы инструменты были доступны)
export PATH="$PREFIX/bin:$PATH"
```

> **Внимание:** После перезапуска терминала вам нужно будет снова выполнить команду `export PATH="$PREFIX/bin:$PATH"`.

#### Шаг 3: Сборка Binutils

Мы собираем Binutils, указывая, что он должен работать с целью `i686-elf`.

```bash
cd $HOME/os_dev/src

# 1. Создаем отдельную папку для сборки Binutils (для чистоты)
mkdir build-binutils
cd build-binutils

# 2. Конфигурируем Binutils
# Указываем целевую архитектуру (--target) и папку установки (--prefix)
../binutils-2.40/configure --target=$TARGET --prefix=$PREFIX --disable-werror

# 3. Компилируем и устанавливаем
make
make install
```

**Что вы получили:** Теперь у вас в папке `$HOME/os_dev/cross/bin/` должны появиться исполняемые файлы, такие как `i686-elf-ld`, `i686-elf-as` и другие.

#### Шаг 4: Сборка GCC (Компилятора C)

Мы собираем GCC. Он найдет инструменты, собранные на Шаге 3, и будет использовать их.

```bash
cd $HOME/os_dev/src

# 1. Создаем отдельную папку для сборки GCC
mkdir build-gcc
cd build-gcc

# 2. Конфигурируем GCC
# --without-headers: Говорит GCC не пытаться использовать стандартные заголовочные файлы ОС.
../gcc-13.2.0/configure --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages=c,c++ --without-headers

# 3. Компилируем и устанавливаем
# Нам нужно собрать только компилятор (gcc) и его базовую библиотеку (libgcc)
make all-gcc
make all-target-libgcc
make install-gcc
make install-target-libgcc
```

Мы включаем libgcc, потому что это минимальная необходимая зависимость, которая нужна самому компилятору для генерации рабочего кода C (целочисленная арифметика, функции для сравнения 64-битных чисел, операции с плавающей точкой), но не является частью высокоуровневой стандартной библиотеки C, зависящей от ОС.

libgcc содержит низкоуровневые вспомогательные функции, которые компилятор (GCC) использует для генерации корректного кода, даже если он работает в автономном режиме (Freestanding Environment)

#### 5. Проверка


```bash
# Проверка, что компилятор теперь найден
which i686-elf-gcc
    /home/jeka/os_dev/cross/bin/i686-elf-gcc

# Проверка версии
i686-elf-gcc --version
    i686-elf-gcc (GCC) 13.2.0
    Copyright (C) 2023 Free Software Foundation, Inc.
    This is free software; see the source for copying conditions.  There is NO
    warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```
 
---

</details>


#### Добавление кросс-компилятора в PATH

<details>

<summary>Временное Добавление в PATH для i686-elf-gcc</summary>

```
# Устанавливаем переменные в текущей сессии
export TARGET=i686-elf
export PREFIX="$HOME/os_dev/cross"

# Добавляем путь установки в начало PATH
export PATH="$PREFIX/bin:$PATH"

# Проверка
i686-elf-gcc --version
    i686-elf-gcc (GCC) 13.2.0
    Copyright (C) 2023 Free Software Foundation, Inc.
    This is free software; see the source for copying conditions.  There is NO
    warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

```

---

</details>


<details>

<summary>Постоянное Решение, переменная среды PATH для i686-elf-gcc</summary>

Откройте файл конфигурации
```
nano ~/.bashrc
```

Добавьте следующие строки в конец файла:
```
# === Настройки для разработки JEKA_OS ===
export TARGET=i686-elf
export PREFIX="$HOME/os_dev/cross"
export PATH="$PREFIX/bin:$PATH"
# ========================================
```

Сохраните файл и закройте редактор
```
source ~/.bashrc

# Проверка
which i686-elf-gcc
```

---

</details>

## 32-битное ядро (способ Multiboot)

[Bare Bones OS/Голое ядро](https://wiki.osdev.org/Bare_Bones)

[wiki.osdev.org](https://wiki.osdev.org/Bare_Bones)

[Limine Bare Bones 64-bit](https://wiki.osdev.org/Limine_Bare_Bones)

Это нормальное multiboot-ядро, оно не является загрузчиком.

Его нельзя запускать напрямую как MBR.

Его должен загрузить Multiboot-загрузчик (GRUB).


Загрузчик [GRUB](https://wiki.osdev.org/GRUB) для загрузки ядра с использованием протокола [Multiboot](https://wiki.osdev.org/Multiboot), который переводит нас в 32-битный защищенный режим с отключенной [подкачкой страниц](https://wiki.osdev.org/Paging).

Формат [ELF](https://wiki.osdev.org/ELF) — это формат исполняемых файлов , который позволяет нам контролировать, куда и как загружается ядро.

**Загрузка операционной системы**

Для запуска операционной системы потребуется уже существующее программное обеспечение, которое её загрузит. Оно называется загрузчиком, и в этом руководстве вы будете использовать GRUB. Операционная система должна обрабатывать момент, когда загрузчик передаст ей управление. Ядру передаётся минимальная среда, в которой стек ещё не настроен, виртуальная память ещё не активирована, оборудование ещё не инициализировано и так далее.
 
Первая задача, с которой вы столкнетесь, — это то, как загрузчик запускает ядро. Разработчикам ОС повезло, потому что существует стандарт мультизагрузки (Multiboot Standard), описывающий простой интерфейс между загрузчиком и ядром операционной системы. Он работает путем добавления нескольких «магических» значений в некоторые глобальные переменные (известные как заголовок мультизагрузки), которые ищет загрузчик. Когда он видит эти значения, он распознает ядро ​​как совместимое с мультизагрузкой и знает, как его загрузить.

Multiboot Specification - является соглашением между разработчиками ядер ОС и разработчиками загрузчиков (например, GRUB).


Три входных файла минимального ядра:
* boot.s — сборка загрузчика, точка входа в ядро, которая настраивает среду процессора
* kernel.c — ваши фактические подпрограммы ядра
* linker.ld - для связывания указанных выше файлов


### 1. Сборка загрузчика

Заготовка ассемблерного кода, которая настраивает процессор таким образом, чтобы можно было использовать языки высокого уровня, такие как C. Также возможно использование других языков, например, C++.

Различия между спецификациями Multiboot

| Характеристика         | Multiboot (MB1)            | Multiboot2 (MB2)                                                          |
| ---------------------- | ---------------------- | -------------------------------------------------------------------- |
| Магическое число       | `0x1BADB002`           | `0xE85250D6`                                                         |
| Архитектура            | неявно x86             | явно через поле `architecture` (0 = i386)                            |
| Длина заголовка        | фиксированная          | явно указывается: `total length = mb2_header_end - mb2_header_start` |
| Контрольная сумма      | `-(MAGIC + FLAGS)`     | `-(magic + arch + total_length)`                                     |
| Теги                   | только флаги (`FLAGS`) | гибкая система тегов (END, FRAMEBUFFER, MODULES и др.)               |
| Выравнивание заголовка | 32-битное (`.align 4`) | 64-битное (`.align 8`)                                               |
| Поддержка расширений   | ограничена             | полностью модульная: можно добавлять теги без изменения ядра         |


<details>

<summary>Файл boot.s для Multiboot (MB1)</summary>


```asm

/* File boot.s */
/* используется ассемблер GNU */
/* Объявляем константы для заголовка Multiboot (MB1). */
.set ALIGN, 1<<0               /* выровнять загруженные модули по границам страниц */
.set MEMINFO, 1<<1             /* предоставить карту памяти */
.set FLAGS, ALIGN | MEMINFO    /* это поле 'флагов' Multiboot (MB1) */
.set MAGIC, 0x1BADB002         /* 'магическое число' позволяет загрузчику найти заголовок */
.set CHECKSUM, -(MAGIC + FLAGS) /* контрольная сумма вышеперечисленного, чтобы доказать, что мы multiboot */

/*
Объявляем заголовок Multiboot (MB1), который помечает программу как ядро.
Это "магические" значения, задокументированные в стандарте Multiboot (MB1).
Загрузчик будет искать эту сигнатуру в первых 8 KiB файла ядра, выровненную по 32-битной границе. 
Сигнатура находится в своей секции, чтобы гарантировать, что заголовок будет 
принудительно размещен в пределах первых 8 KiB файла ядра.
*/
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

/*
Стандарт Multiboot не определяет значение регистра указателя стека (esp), 
и предоставление стека ложится на ядро. Здесь выделяется место для небольшого стека: 
создается символ в его нижней части (stack_bottom), затем выделяется 16384 байта (16 KiB) для него, 
и, наконец, создается символ в верхней части (stack_top). Стек на x86 растет вниз. 
Стек находится в своей секции (.bss), чтобы его можно было пометить как nobits, 
что уменьшает размер файла ядра, поскольку он не содержит неинициализированный стек. 
Стек на x86 должен быть выровнен по 16-байтовой границе, согласно стандарту System V ABI.
*/
.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

/*
Скрипт линковщика (линкера) указывает _start как точку входа в ядро,
и загрузчик перейдет к этой позиции, как только ядро будет загружено.
Нет смысла возвращаться из этой функции, так как загрузчик уже ушел.
*/
.section .text
.global _start
.type _start, @function
_start:
	/*
	Загрузчик загрузил нас в 32-битный защищенный режим на машине x86.
	Прерывания отключены. Страничная адресация (Paging) отключена. 
    Ядро имеет полный контроль над ЦП, без каких-либо функций ОС или библиотек. 
	*/

	/*
	Чтобы настроить стек, мы устанавливаем регистр esp (указатель стека)
	на верхнюю границу стека (stack_top), поскольку на системах x86 он
	растет вниз. Это обязательно делается на ассемблере, так как языки,
	такие как C, не могут функционировать без стека.
	*/
	mov $stack_top, %esp

	/*
	Это хорошее место для инициализации критического состояния процессора
	(например, загрузка GDT, включение Paging) перед входом в
	высокоуровневое ядро.
	*/

	/*
	Вход в высокоуровневое ядро. ABI требует, чтобы стек был 16-байтно
	выровнен во время вызова `call`. Поскольку мы не меняли выравнивание
	после установки `esp`, вызов является корректным.
	*/
	call kernel_main

	/*
	Если система завершила работу (вернулась из kernel_main, что
	нелогично для ОС), переводим компьютер в бесконечный цикл.
	1) cli: отключает прерывания.
	2) hlt: останавливает ЦП, ожидая прерывания.
	3) jmp 1b: возвращается к hlt в случае немаскируемого прерывания.
	*/
	cli
1:	hlt
	jmp 1b

/*
Устанавливаем размер символа _start. Полезно для отладки.
*/
.size _start, . - _start
```

Сборка:

```
i686-elf-as boot.s -o boot.o
```

</details>


Назначение каждой части спецификации Multiboot2 (MB2)

| Часть                               | Назначение                                                                                  |
| ----------------------------------- | ------------------------------------------------------------------------------------------- |
| `.section .multiboot / .multiboot2` | Заголовок Multiboot, который **GRUB проверяет**, чтобы понять, что это ядро OS              |
| `.align`                            | Выравнивание заголовка в памяти (важно для загрузчика)                                      |
| `MAGIC` / `magic`                   | Магическое число, проверяемое GRUB                                                          |
| `FLAGS` (MB1)                       | Опции загрузки (например, выдавать карту памяти)                                            |
| `architecture` (MB2)                | Определяет, на какой архитектуре загружается ядро                                           |
| `total length`                      | Размер всего заголовка MB2 (нужно для тегов)                                                |
| `checksum`                          | Контрольная сумма, чтобы GRUB проверил корректность заголовка                               |
| `END tag` (MB2)                     | Завершение списка тегов, обязательно для MB2                                                |
| `.bss` с `stack_bottom`/`stack_top` | Выделение памяти для стека CPU                                                              |
| `_start:`                           | Точка входа ядра: установка стека, переход в `kernel_main`, бесконечный цикл после возврата |

Дополнительные теги MB2

Multiboot2 позволяет добавлять теги, которые сообщают загрузчику дополнительную информацию о ядре или просят его сделать что-то заранее:

| Тег            | Назначение                                                                            |
| -------------- | ------------------------------------------------------------------------------------- |
| `MEMORY_MAP`   | Попросить GRUB передать карту памяти (`tag type = 6`)                                 |
| `BOOT_DEVICE`  | Информация о том, с какого диска/раздела загружено ядро                               |
| `COMMAND_LINE` | Передать командную строку ядру                                                        |
| `MODULE`       | Ссылки на дополнительные модули, которые нужно загрузить (например, драйверы, initrd) |
| `FRAMEBUFFER`  | Настройка графического фреймбуфера для видео                                          |


<details>

<summary>Файл boot.s для Multiboot2 (MB2)</summary>


```asm
/* boot.s - Multiboot2 Header */
.section .multiboot2
.align 8
mb2_header_start:
    .long 0xE85250D6       # magic
    .long 0                # architecture (0 = i386)
    .long mb2_header_end - mb2_header_start  # total length
    .long -(0xE85250D6 + 0 + (mb2_header_end - mb2_header_start))  # checksum

# END tag
.align 8
mb2_header_end:
    .long 0  # type = END
    .long 8  # size = 8

# простой стек
.section .bss
.align 16
stack_bottom:
.skip 16384
stack_top:

.section .text
.global _start
.type _start, @function
_start:
    mov $stack_top, %esp
    call kernel_main
    cli
1:  hlt
    jmp 1b
.size _start, .-_start


```

---

</details>

**В более «полном» ядре еще добавляют:**
* Настройку GDT (глобальная таблица дескрипторов)
* Включение IDT (таблицы прерываний)
* Включение Paging (виртуальной памяти)


### 2. Написание ядра на языке C

kernel.c — это:

* не “программа”
* не “приложение”
* не “пользовательский код”

kernel.c  — это первый слой абстракции поверх железа

Он:
* не знает про Multiboot напрямую
* не знает про диски
* не знает про память
* просто пишет байты в физическую память



VGA — ваш первый “драйвер”.
Это ядро ​​использует буфер текстового режима VGA (расположенный по адресу `0xB8000`) в качестве устройства вывода.
Оно настраивает простой драйвер, который запоминает местоположение следующего символа в этом буфере и предоставляет примитив для добавления нового символа. Примечательно, что отсутствует поддержка переносов строк ('\n') (и при записи этого символа будет отображаться какой-либо символ, специфичный для VGA) и отсутствует поддержка прокрутки, когда экран заполнен. Добавление этих функций будет вашей первой задачей.

ВАЖНОЕ ЗАМЕЧАНИЕ: текстовый режим VGA (а также BIOS) устарел на более новых машинах, а UEFI поддерживает только пиксельные буферы. Для обеспечения обратной совместимости, возможно, стоит начать с этого. Попросите GRUB настроить фреймбуфер, используя соответствующие флаги мультизагрузки, или вызовите [VESA VBE](https://wiki.osdev.org/Vesa) самостоятельно. В отличие от текстового режима VGA, фреймбуфер имеет пиксели, поэтому вам придется рисовать каждый глиф самостоятельно. Это означает, что вам понадобится другой формат terminal_putcharи шрифт (растровые изображения для каждого символа). Все дистрибутивы Linux поставляются с [PC Screen Fonts](https://wiki.osdev.org/PC_Screen_Font), которые вы можете использовать, а в статье в вики есть простой пример использования putchar(). В остальном все описанное здесь остается в силе (вам нужно отслеживать положение курсора, реализовать переносы строк и прокрутку и т. д.).

```c
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY 0xB8000
```

Это железо, не API:
* `0xB8000` — физический адрес VGA text buffer
* каждый символ = 2 байта
    * байт 0 — ASCII
    * байт 1 — цвет

`enum vga_color { BLACK=0, BLUE=1 ...`  это чистые числа, которые VGA ожидает.

VGA формат цвета:
```
bits 0..3 → foreground
bits 4..7 → background

# Пример формирование VGA-ячейки, вызов vga_entry_color:
LIGHT_GREY = 7
BLACK = 0

color = 7 | (0 << 4) = 0x07
```



В отличии от хостируемуй среды (Hosted Environment) где есть стандартная библиотека C (libc), в автономной версии, которая нам доступна тут, нет стандартной библиотеки C (libc), но есть некоторые другие библиотеки C.

В обычной программе, libc вызывает ядро. Но мы пишем само ядро. Нельзя, чтобы ядро вызывало код, который, в свою очередь, ждет вызовов от ядра. И стандартная библиотека C (такая как GLibc в Linux или MSVCRT в Windows) — это не просто набор функций, это интерфейс между пользовательской программой и операционной системой (ОС). Функции вроде malloc(), fopen(), printf() и fork() полагаются на системные вызовы (syscalls), которые предоставляет ядро, но у нас нет ОС мы ее только начали создавать.

Автономная версия (Freestanding Environment - freestanding-ядро, флаг компилятора `-ffreestanding`) означает отсутствие стандартной библиотеки C, только то, что вы предоставляете сами. Однако некоторые заголовочные файлы на самом деле не являются частью стандартной библиотеки C, а входят в состав компилятора. Они остаются доступными даже в автономном исходном коде C. В данном случае вы используете **stdbool.h** для получения типа данных bool, **stddef.h** для получения типов данных size_t и NULL, и **stdint.h** для получения типов данных intx_t и uintx_t, которые бесценны для разработки операционных систем, где необходимо убедиться, что переменная имеет точный размер (если бы вы использовали short вместо uint16_t, и размер short изменился бы, ваш драйвер VGA здесь перестал бы работать!). Кроме того, вы можете получить доступ к заголовочным файлам **float.h, iso646.h, limits.h** и **stdarg.h**, поскольку они также являются независимыми. 

Таких функций как strlen, memcpy, printf, malloc — нет, мы обязаны писать их сами.

Обратите внимание, что в коде вы хотели использовать распространенную в C функцию strlen, но эта функция является частью стандартной библиотеки C, которая у вас недоступна. Вместо этого вы полагались на отдельный заголовочный файл **stddef.h** для предоставления типа size_t и просто объявили свою собственную реализацию функции strlen. Вам придется делать это для каждой функции, которую вы хотите использовать (поскольку отдельные заголовочные файлы предоставляют только макросы и типы данных).


kernel.c — это первый C-код, в который мы попадаем после _start из boot.s. Последовательность такая: `GRUB → boot.s → kernel_main`

* Здесь нет libc
* Здесь нет ОС

Всё, что работает — это:
* CPU в 32-бит protected mode
* стек, который мы сами задали
* память, загруженная GRUB



<details>

<summary>Файл kernel.c Multiboot1</summary>

```c
/* File kernel.c */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Check if the compiler thinks you are targeting the wrong operating system. */
#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

/* This tutorial will only work for the 32-bit ix86 targets. */
#if !defined(__i386__)
#error "This tutorial needs to be compiled with a ix86-elf compiler"
#endif

/* Hardware text mode color constants. */
enum vga_color {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_BLUE = 1,
    VGA_COLOR_GREEN = 2,
    VGA_COLOR_CYAN = 3,
    VGA_COLOR_RED = 4,
    VGA_COLOR_MAGENTA = 5,
    VGA_COLOR_BROWN = 6,
    VGA_COLOR_LIGHT_GREY = 7,
    VGA_COLOR_DARK_GREY = 8,
    VGA_COLOR_LIGHT_BLUE = 9,
    VGA_COLOR_LIGHT_GREEN = 10,
    VGA_COLOR_LIGHT_CYAN = 11,
    VGA_COLOR_LIGHT_RED = 12,
    VGA_COLOR_LIGHT_MAGENTA = 13,
    VGA_COLOR_LIGHT_BROWN = 14,
    VGA_COLOR_WHITE = 15,
};

static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) {
    return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) {
    return (uint16_t) uc | (uint16_t) color << 8;
}

size_t strlen(const char* str) {
    size_t len = 0;
    while (str[len])
        len++;
    return len;
}

#define VGA_WIDTH   80
#define VGA_HEIGHT  25
#define VGA_MEMORY  0xB8000 

size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer = (uint16_t*)VGA_MEMORY;

void terminal_initialize(void) {
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
    
    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            const size_t index = y * VGA_WIDTH + x;
            terminal_buffer[index] = vga_entry(' ', terminal_color);
        }
    }
}

void terminal_setcolor(uint8_t color) {
    terminal_color = color;
}

void terminal_putentryat(char c, uint8_t color, size_t x, size_t y) {
    const size_t index = y * VGA_WIDTH + x;
    terminal_buffer[index] = vga_entry(c, color);
}

void terminal_putchar(char c) {
    // Временно проигнорируем символ новой строки, как указано в туториале.
    // Заметка: здесь нужно было бы реализовать перенос строки.
    if (c == '\n') {
        terminal_column = 0;
        if (++terminal_row == VGA_HEIGHT)
            terminal_row = 0; // Скроллинг не реализован, просто возвращаемся наверх
        return;
    }
    
    terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
    
    if (++terminal_column == VGA_WIDTH) {
        terminal_column = 0;
        if (++terminal_row == VGA_HEIGHT)
            terminal_row = 0; // Скроллинг не реализован, просто возвращаемся наверх
    }
}

void terminal_write(const char* data, size_t size) {
    for (size_t i = 0; i < size; i++)
        terminal_putchar(data[i]);
}

void terminal_writestring(const char* data) {
    terminal_write(data, strlen(data));
}

void kernel_main(void) {
    /* Initialize terminal interface */
    terminal_initialize();

    /* Newline support is left as an exercise. */
    terminal_writestring("Hello, kernel World!\n");
}
```

Компиляция:

```
i686-elf-gcc -c kernel.c -o kernel.o -std = gnu99 -ffreestanding -O2 -Wall -Wextra
```

---

</details>


 

<details>

<summary>Файл kernel.c Multiboot2</summary>

```c
 
/* 
Первый уровень логики ядра.

Для Multiboot2 GRUB передаёт структуру multiboot2_info_t, если вы хотите использовать карту памяти, но для минимального ядра это не обязательно. 
*/
 
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY 0xB8000

// Секция ELF .bss
size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
// Секция ELF .data
// память VGA
// [CPU] ──► [physical RAM] ──► [VGA text buffer @ 0xB8000]
uint16_t* terminal_buffer = (uint16_t*)VGA_MEMORY;

enum vga_color { BLACK, BLUE, GREEN, CYAN, RED, MAGENTA, BROWN, LIGHT_GREY, DARK_GREY, LIGHT_BLUE, LIGHT_GREEN, LIGHT_CYAN, LIGHT_RED, LIGHT_MAGENTA, LIGHT_BROWN, WHITE };

// Формирование VGA-ячейки
static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) { return fg | bg << 4; }

// собирает 2 байта VGA символа
// [ color ][ ASCII ]
static inline uint16_t vga_entry(unsigned char uc, uint8_t color) { return (uint16_t) uc | (uint16_t) color << 8; }

size_t strlen(const char* str) { size_t len = 0; while (str[len]) len++; return len; }


void terminal_initialize(void) {
    // сбрасываем курсор
    // выбираем цвет
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = vga_entry_color(LIGHT_GREY, BLACK);

    // очистка экрана
    // прямое заполнение VGA памяти
    for (size_t y = 0; y < VGA_HEIGHT; y++)
        for (size_t x = 0; x < VGA_WIDTH; x++)
            terminal_buffer[y * VGA_WIDTH + x] = vga_entry(' ', terminal_color);
}

/*
Примитивный перенос строки:
* нет скроллинга
* нет CR/LF
* экран просто “перепрыгивает вверх”
*/
void terminal_putchar(char c) {
    if (c == '\n') { terminal_column = 0; if (++terminal_row == VGA_HEIGHT) terminal_row = 0; return; }
    // прямое обращение к памяти VGA
    terminal_buffer[terminal_row * VGA_WIDTH + terminal_column] = vga_entry(c, terminal_color);
    if (++terminal_column == VGA_WIDTH) { terminal_column = 0; if (++terminal_row == VGA_HEIGHT) terminal_row = 0; }
}

/*
Минимальный аналог puts
* крайне неэффективный (strlen вызывается каждый раз)
* но идеален для обучения
*/
void terminal_writestring(const char* data) {
    for (size_t i = 0; i < strlen(data); i++)
        terminal_putchar(data[i]);
}

/* 

Точка входа C

Это первый C-код ОС после:
* GRUB
* Multiboot2
* boot.s
* установки стека

kernel_main не возвращается логически, если вернётся — попадём в cli; hlt
*/
void kernel_main(void) {
    terminal_initialize();
    terminal_writestring("Hello, Multiboot2 World!\n");
}
```

Компиляция:

```
i686-elf-gcc -c kernel.c -o kernel.o -std = gnu99 -ffreestanding -O2 -Wall -Wextra
```

---

</details>

 

**Что обычно добавляют следующим шагом:**
* Передача multiboot2_info* в kernel_main
* Парсинг memory (RAM) map
* Реальный скроллинг
* IDT + IRQ
* Paging
* Heap
* Framebuffer вместо VGA
* графический вывод
* собственный шрифт
* оконная система
* управление прерываниями

---


### 3. Linking the Kernel

(линковка ядра)

Теперь вы можете собрать boot.s и скомпилировать kernel.c. В результате будут созданы два объектных файла, каждый из которых содержит часть ядра. Для создания полного и окончательного ядра вам потребуется связать эти объектные файлы с окончательной программой ядра, используемой загрузчиком.

Файл linker.ld задаёт разметку адресов и секций в итоговом бинарнике.


<details>

<summary>Файл linker.ld Multiboot1</summary>

```
/* 
    Загрузчик просмотрит этот образ и начнет выполнение с символа, обозначенного как точка входа. 

    Указывает точку входа для линковщика, в нашем случае _start из boot.s.

    Без этого линковщик выбрал бы «какой-то первый символ» или _start по умолчанию, что может сработать случайно, но не гарантированно.
*/
ENTRY(_start)

/* 
    Укажите, куда будут помещены различные разделы объектных файлов (.text, .rodata, .data и .bss) в итоговом образе ядра. 
*/
SECTIONS
{
    /* 
     Раньше повсеместно рекомендовали использовать 1M в качестве стартового смещения, 
     так как он был фактически гарантирован доступен в системах BIOS. Однако UEFI усложнил ситуацию,
     и экспериментальные данные явно указывают на то, что 2M — более безопасное место для загрузки. 
     В 2016 году в спецификацию multiboot2 была введена новая функция, информирующая загрузчиков, 
     что ядро можно загрузить в любом месте в пределах диапазона адресов и сможет переместиться для 
     работы с такого адреса, выбранного загрузчиком, чтобы дать загрузчику свободу при выборе памяти, 
     который подтверждается прошивкой, чтобы обойти эту проблему. Здесь эта функция не используется, 
     поэтому 2M был выбран более безопасным вариантом, чем традиционный 1M

     . = 2M;

     GRUB обычно не знает, что ядро ожидает именно этот адрес.
     QEMU/VirtualBox — прощают, просто загружают ядро куда захотят.
     Bochs — строгий, прыгает по адресу, который указал multiboot header → тут начинается мусор → трипл-фолт.
     Вывод: 2MB слишком далеко, нужно либо: оставить 1M (0x00100000), проверенный BIOS-safe вариант,
     либо явно использовать multiboot 2 с load_addr, чтобы GRUB загружал туда, куда надо

     . = 1M;

    Или явно задаём адрес начала .text  
     . = 0x00100000;   
    */
    
    . = 2M;

	/* 
        Сначала разместим заголовок multiboot, так как его необходимо разместить в самом начале образа, 
        иначе загрузчик не распознает формат файла. Далее добавим раздел .text

        ALIGN(4K) — выравнивание секции на границу страницы (важно для работы с памятью, Paging и MMU)

        KEEP(*(.multiboot)) — гарантирует, что Multiboot заголовок останется в бинарнике и не будет оптимизирован компоновщиком
    */
    .text ALIGN(4K) : {
        KEEP(*(.multiboot))   /* multiboot header всегда первые 4/12 байт */
        _start = .;           /* ENTRY(_start) = начало кода */
        *(.text*)
    }

    /* Данные доступны только для чтения. */
    .rodata ALIGN(4K) : {
        *(.rodata*)
    }

    /* Данные для чтения и записи (инициализированы) */
    .data ALIGN(4K) : {
        *(.data*)
    }

    /* Чтение и запись данных (неинициализированных) и стека. */
    .bss ALIGN(4K) : {
        *(COMMON)
        *(.bss*)
    }
}

```

Линковка:

```
i686-elf-gcc -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc
```

Проверим адреса секций для Multiboot1:
```
# для дебага нужно скомпилировать с отладочной информацией
i686-elf-gcc -c kernel.c -std=gnu99 -ffreestanding -O0 -g -Wall -Wextra -o kernel.o
i686-elf-gcc -T linker.ld -o myos.bin -ffreestanding -O0 -nostdlib boot.o kernel.o -lgcc
make iso
qemu-system-i386 -cdrom myos.iso -s -S
# -s — включает gdbserver на TCP порт 1234.
# -S — не запускает CPU сразу, чтобы мы могли подключиться через GDB.

gdb myos.bin
target remote localhost:1234


Reading symbols from myos.bin...
(gdb) target remote localhost:1234
Remote debugging using localhost:1234
0x00100018 in _start ()

# Точка входа
(gdb) info files
Symbols from "/home/jeka/Projects/JEKA_OS/wiki_osdev_multiboot1/myos.bin".
Remote target using gdb-specific protocol:
	`/home/jeka/Projects/JEKA_OS/wiki_osdev_multiboot1/myos.bin', file type elf32-i386.
	Entry point: 0x10000c
	0x00100000 - 0x00100292 is .text
	0x00101000 - 0x00101016 is .rodata
	0x00102000 - 0x00102004 is .data
	0x00103000 - 0x00107009 is .bss
	While running this, GDB does not access memory from...
Local exec file:
	`/home/jeka/Projects/JEKA_OS/wiki_osdev_multiboot1/myos.bin', file type elf32-i386.
	Entry point: 0x10000c
	0x00100000 - 0x00100292 is .text
	0x00101000 - 0x00101016 is .rodata
	0x00102000 - 0x00102004 is .data
	0x00103000 - 0x00107009 is .bss

# Адрес функции    
(gdb) info address _start
Symbol "_start" is at 0x10000c in a file compiled without debugging.

(gdb) info address kernel_main
Symbol "kernel_main" is a function at address 0x10027a.

# Просмотр Multiboot1 заголовка в памяти (первые 4 слова по 32 бита)
(gdb) x/4wx 0x00100000
0x100000:	0x1badb002	0x00000003	0xe4524ffb	0x107000bc

# 0x1badb002 — магическое число MB1
# 0x00000003 — флаги (ALIGN | MEMINFO)
# 0xe4524ffb — контрольная сумма (-(MAGIC + FLAGS))
# четвёртое слово может быть 0x0 (резерв или адрес возврата)

# Адреса .text, .data, .bss, стека — проверяются точно так же:

(gdb) info address terminal_initialize
Symbol "terminal_initialize" is a function at address 0x100074.
(gdb) info address stack_top
Symbol "stack_top" is at 0x107000 in a file compiled without debugging.
(gdb) info address stack_bottom
Symbol "stack_bottom" is at 0x103000 in a file compiled without debugging.

```

---

</details>


<details>

<summary>Файл linker.ld Multiboot2</summary>

```
ENTRY(_start)

SECTIONS
{
    . = 0x00100000;

    .text ALIGN(4K) : {
        KEEP(*(.multiboot2))
        _start = .;
        *(.text*)
    }

    .rodata ALIGN(4K) : { *(.rodata*) }
    .data ALIGN(4K) : { *(.data*) }
    .bss ALIGN(4K) : { *(COMMON) *(.bss*) }
}

```

Линковка:

```
i686-elf-gcc -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc
```


Проверим адреса секций для Multiboot2:
```

readelf -S myos.bin
    There are 16 section headers, starting at offset 0x3be0:

    Section Headers:
    [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
    [ 0]                   NULL            00000000 000000 000000 00      0   0  0
    [ 1] .text             PROGBITS        00100000 001000 00023a 00  AX  0   0  8
    [ 2] .rodata           PROGBITS        00101000 002000 00001a 00   A  0   0  1
    [ 3] .data             PROGBITS        00102000 003000 000004 00  WA  0   0  4
    [ 4] .bss              NOBITS          00103000 003004 004009 00  WA  0   0 16
    [ 5] .debug_info       PROGBITS        00000000 003004 0002a9 00      0   0  1
    [ 6] .debug_abbrev     PROGBITS        00000000 0032ad 00014b 00      0   0  1
    [ 7] .debug_aranges    PROGBITS        00000000 0033f8 000020 00      0   0  1
    [ 8] .debug_line       PROGBITS        00000000 003418 0001a2 00      0   0  1
    [ 9] .debug_str        PROGBITS        00000000 0035ba 0001d2 01  MS  0   0  1
    [10] .debug_line_str   PROGBITS        00000000 00378c 000089 01  MS  0   0  1
    [11] .comment          PROGBITS        00000000 003815 000012 01  MS  0   0  1
    [12] .debug_frame      PROGBITS        00000000 003828 000100 00      0   0  4
    [13] .symtab           SYMTAB          00000000 003928 000130 10     14   9  4
    [14] .strtab           STRTAB          00000000 003a58 0000eb 00      0   0  1
    [15] .shstrtab         STRTAB          00000000 003b43 00009a 00      0   0  1
    Key to Flags:
    W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
    L (link order), O (extra OS processing required), G (group), T (TLS),
    C (compressed), x (unknown), o (OS specific), E (exclude),
    D (mbind), p (processor specific)

 
gdb myos.bin
target remote localhost:1234


# Остановка на точке входа
(gdb) break _start
Breakpoint 1 at 0x100018
(gdb) c
Continuing.

# Просмотр точек входа
Breakpoint 1, 0x00100018 in _start ()
(gdb) info address _start
Symbol "_start" is at 0x100018 in a file compiled without debugging.

(gdb) info address kernel_main
Symbol "kernel_main" is a function at address 0x100222.

(gdb) info address terminal_initialize
Symbol "terminal_initialize" is a function at address 0x100080.

(gdb) info address terminal_putchar
Symbol "terminal_putchar" is a function at address 0x10010f.

(gdb) info address terminal_writestring
Symbol "terminal_writestring" is a function at address 0x1001e4.

# Просмотр содержимого секций по адресам
# .text
(gdb) x/32bx 0x00100000 
0x100000 <mb2_header_start>:	0xd6	0x50	0x52	0xe8	0x00	0x00	0x00	0x00
0x100008 <mb2_header_start+8>:	0x10	0x00	0x00	0x00	0x1a	0xaf	0xad	0x17
0x100010 <mb2_header_end>:	0x00	0x00	0x00	0x00	0x08	0x00	0x00	0x00
0x100018 <_start>:	0xbc	0x00	0x70	0x10	0x00	0xe8	0x00	0x02

# Заголовок MB2 найден (последовательно наоборот)
# 0x100000
# 0xd6 50 52 e8 00 00 00 00
# 0xe85250d6 — магическое число MB2 (little-endian)
# То есть первые 16 байт — это сам заголовок MB2, который видит только GRUB при загрузке. CPU после загрузки не использует его.


# .rodata нужно использовать адреса из вывода команды readelf, так как меток нет
    (gdb) info address _rodata
    No symbol "_rodata" in current context.

(gdb) x/32bx 0x00101000   
0x101000:	0x48	0x65	0x6c	0x6c	0x6f	0x2c	0x20	0x4d
0x101008:	0x75	0x6c	0x74	0x69	0x62	0x6f	0x6f	0x74
0x101010:	0x32	0x20	0x57	0x6f	0x72	0x6c	0x64	0x21
0x101018:	0x0a	0x00	0xa5	0x02	0x00	0x00	0x05	0x00

# .data
# Это глобальные переменные с инициализацией
(gdb) x/32bx 0x00102000
0x102000 <terminal_buffer>:	0x00	0x80	0x0b	0x00	0x00	0x00	0x00	0x00
0x102008:	0x00	0x00	0x00	0x00	0x00	0x00	0x00	0x00
0x102010:	0x00	0x00	0x00	0x00	0x00	0x00	0x00	0x00
0x102018:	0x00	0x00	0x00	0x00	0x00	0x00	0x00	0x00

# terminal_buffer = (uint16_t*)0xB8000
# 0xB8000 = 0x000B8000 -> 00 80 0B 00
# 0x00 0x80 0x0b 0x00 — это сама запись адреса 0xB8000, little-endian
# Остальные байты нули, потому что больше инициализированных данных нет.



# .bss
# это неинициализированные глобальные переменные
(gdb) x/32bx 0x00103000
0x103000:	0x00	0x00	0x00	0x00	0x00	0x00	0x00	0x00
0x103008:	0x00	0x00	0x00	0x00	0x00	0x00	0x00	0x00
0x103010:	0x00	0x00	0x00	0x00	0x00	0x00	0x00	0x00
0x103018:	0x00	0x00	0x00	0x00	0x00	0x00	0x00	0x00
(gdb) 

# Просмотр память для стека CPU (если определён через stack_top/stack_bottom)
# Метки из ассемблера (stack_top/stack_bottom) не имеют типа, поэтому GDB требует явный адрес.
# stack_top
(gdb) info address stack_top
Symbol "stack_top" is at 0x107000 in a file compiled without debugging.

# stack_bottom
(gdb) info address stack_bottom
Symbol "stack_bottom" is at 0x103000 in a file compiled without debugging.
# Смотрим первые 32 слова (по 4 байта) начиная с stack_bottom
# Стек ещё не использован (нет push/pop, вызовов функций) поэтому все нули.
# Это покажет память от нижней границы стека вверх
(gdb) x/32wx 0x00103000
0x103000:	0x00000000	0x00000000	0x00000000	0x00000000
0x103010:	0x00000000	0x00000000	0x00000000	0x00000000
0x103020:	0x00000000	0x00000000	0x00000000	0x00000000
0x103030:	0x00000000	0x00000000	0x00000000	0x00000000
0x103040:	0x00000000	0x00000000	0x00000000	0x00000000
0x103050:	0x00000000	0x00000000	0x00000000	0x00000000
0x103060:	0x00000000	0x00000000	0x00000000	0x00000000
0x103070:	0x00000000	0x00000000	0x00000000	0x00000000

# посмотреть стек вверх до stack_top
x/128wx 0x00103000

```

---

</details>

 

**Что можно ещё добавить в linker.ld**:
* Stack section: явно выделяют .stack и ставят stack_top/stack_bottom.
* Фреймбуфер или другие буферы: можно зарезервировать в .bss.
* Секции для драйверов или модулей: .modules или .init.
* Разные адреса для разных архитектур: если ядро 32-битное и 64-битное.



---

Теперь файл myos.bin — это ваше ядро ​​(все остальные файлы больше не нужны). Обратите внимание, что мы используем библиотеку libgcc , которая реализует различные подпрограммы времени выполнения, от которых зависит ваш кросс-компилятор. Отсутствие этой библиотеки может привести к проблемам в будущем. Если вы не собрали и не установили libgcc в составе вашего кросс-компилятора, вам следует вернуться к этому шагу и собрать кросс-компилятор с libgcc. Компилятор зависит от этой библиотеки и будет использовать её независимо от того, предоставите вы её или нет.
 

**Создание загрузочного образа CD-ROM**

Файл grub.cfg:

```
set timeout=0
set default=0

menuentry "myos" {
    multiboot /boot/myos.bin
}
```


```
mkdir -p isodir/boot/grub
cp myos.bin isodir/boot/myos.bin
cp grub.cfg isodir/boot/grub/grub.cfg

# grub-mkrescue использует лицензию GNU GPL !
grub-mkrescue -o myos.iso isodir 
```

**Тестирование вашей операционной системы (QEMU)**

```
# запустить новую виртуальную машину, содержащую только ваш ISO-образ в виде CD-ROM
qemu-system-i386 -cdrom myos.iso

# QEMU поддерживает прямую загрузку мультизагрузочных ядер без использования загрузочного носителя
qemu-system-i386 -kernel myos.bin

```
  
---

 
## Tools

gdb-multiarch — это версия отладчика GDB, скомпилированная со специальной поддержкой множества целевых архитектур (multi-target support). 

gdb-multiarch позволяет загружать и интерпретировать отладочную информацию (символы, точки останова) из бинарника, скомпилированного для другой архитектуры ($i686$) и другого формата (ELF), нежели ваша хост-система.

```
sudo apt install gdb-multiarch
gdb-multiarch --version
    GNU gdb (Ubuntu 15.0.50.20240403-0ubuntu1) 15.0.50.20240403-git
    Copyright (C) 2024 Free Software Foundation, Inc.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.

```

Процесс отладки:
1. Вы запускаете QEMU с флагом отладки (например, -s или -S). QEMU ждет подключения GDB.
2. Вы запускаете gdb-multiarch и даете ему команду подключиться к QEMU:
```
gdb-multiarch myos.bin
(gdb) target remote localhost:1234
```



<details>

<summary>Обзор 32-битного ядра (Protected Mode) MBR </summary>

### Обзор 32-битного ядра (Protected Mode)
Чтобы запустить C-код, нам нужно четыре основных компонента, работающих в следующем порядке:
* loader.asm (MBR, 16-бит): Читает ядро с диска и переходит в 32-битный режим
* kernel_entry.asm (32-бит): Устанавливает 32-битный стек и вызывает kernel_main()
* kernel.c (32-бит): Основной код ядра, работающий с памятью и устройствами
* linker.ld: Определяет, куда в памяти поместить ядро (адрес $0x10000$)

Любая ОС должна пройти через четыре этапа, прежде чем она сможет выполнить ваш код на C:
* Real Mode (16-бит): BIOS запускает MBR ($0x7C00$). MBR должен прочитать ядро с диска (Int $0x13$).
* Protected Mode (32-бит): Необходимо настроить Global Descriptor Table (GDT) и переключить бит в регистре CR0.
* Переход в C: Необходимо инициализировать 32-битный стек и установить сегментные регистры.
* Запуск C-кода: Ваш код ядра должен иметь возможность хоть что-то сделать (например, вывести текст), чтобы показать, что он работает.


Критические точки отладки (Checkpoint)
* Пример отладки: Загрузчик (MBR): Проверить, что BIOS передал управление на $0x7C00$

    ```
    # после запуска qemu в режиме отладки `qemu-system-i386 -fda os_image.bin -boot a -s -S`, открыть gdb в другом терминале 
    gdb -ex "target remote localhost:1234"

    # Можно сразу узнать адресс нужной инструкции чтобы потом установить на нее точку останова
     x /50i $pc
    

    # установить breakpoint на адрес $0x7C00$ загрузчика (MBR)
    (gdb) b *0x7c00
    (gdb) c
    Continuing.

    Breakpoint 1, 0x00007c00 in ?? ()

    # Проверить первые инструкции MBR
    (gdb) x /10i $pc
    => 0x7c00:	cli
    0x7c01:	xor    %eax,%eax
    0x7c03:	mov    %eax,%ds
    0x7c05:	mov    %eax,%es
    0x7c07:	mov    %eax,%ss
    0x7c09:	mov    $0x2b47c00,%esp
    0x7c0e:	mov    $0x14,%al
    0x7c10:	mov    $0x0,%ch
    0x7c12:	mov    $0x2,%cl
    0x7c14:	mov    $0x0,%dh

    ```

* Точка 2: Загрузка ядра: Проверить, что чтение диска завершилось и код ядра находится в $0x10000$

```
# Ставим точку останова на ядре. 
(gdb) b *0x10000
Breakpoint 2 at 0x10000
(gdb) c
Continuing.

Breakpoint 1, 0x00007c00 in ?? ()

# Проверить регистр управления CR0. Должен быть включен бит $0x1$ (Protected Mode Enable)
(gdb) i r cr0
cr0            0x10                [ ET ]

# Смотрим первые инструкции ядра (из kernel_entry.asm)
(gdb) x /10i $pc
=> 0x7c00:	cli
   0x7c01:	xor    %eax,%eax
   0x7c03:	mov    %eax,%ds
   0x7c05:	mov    %eax,%es
   0x7c07:	mov    %eax,%ss
   0x7c09:	mov    $0x2b47c00,%esp
   0x7c0e:	mov    $0x14,%al
   0x7c10:	mov    $0x0,%ch
   0x7c12:	mov    $0x2,%cl
   0x7c14:	mov    $0x0,%dh

# Должен появиться синий экран с зеленым текстом в окне QEMU
(gdb) c
Continuing.

Breakpoint 1, 0x00007c00 in ?? ()

```
 
---

</details>

## Что вам нужно сделать дальше?

* Очистка и базовый вывод текста  
* Начать настройку таблицы прерываний (IDT), чтобы ваша ОС могла реагировать на внешние события клавиатуры и ошибки

[Дальнейшее развитие архитектуры x86](https://wiki.osdev.org/Going_Further_on_x86)