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
