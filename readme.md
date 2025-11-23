# Generator pliku Makefile

Skrypt `generate_makefile.sh` automatycznie tworzy plik Makefile dla projektu w języku C.

Na podstawie zawartości katalogu źródłowego wykrywa pliki .c, plik z funkcją main(), lokalne nagłówki oraz generuje zależności pomiędzy nimi.

## Wymagania

- bash w wersji co najmniej 4.0
- Zainstalowany kompilator C (gcc lub clang)

## Użycie

Nadaj uprawnienia do uruchomienia:

```bash
chmod +x generate_makefile.sh
```

Uruchom skrypt, podając katalog projektu:

```
./generate_makefile.sh <ścieżka_do_katalogu>
```

Przykład:

```
./generate_makefile.sh example-c-project
```

Po wykonaniu w katalogu projektu pojawi się plik Makefile, gotowy do użycia z poleceniem make.

## Lista zmian

Tak jak rozmawialismy, wprowadzam 2 glowne poprawki.

### 1. Korzystanie z `basename` do oczyszczenia rozszerzenia `.c` w jednej linijce

```
main_basename=$(basename "${main_files[0]}")
exe_name="${main_basename%.*}"
```

zamienilem na:

```
exe_name=$(basename "${main_files[0]}" .c)
```

### 2. Naprawienie regexa - wykrywa `void main()` i `main()`

Sprawdzilem i kompiluje poprawnie `void main()` i `main()`:

```
if grep -Eq '^[[:space:]]*int[[:space:]]+main[[:space:]]*(' "$f"; then
    main_files+=("$f")
fi
```

zamienione na:

```
if grep -Eq '^[[:space:]]*(int|void)?[[:space:]]*main[[:space:]]*\(' "$f"; then
    main_files+=("$f")
fi
```
