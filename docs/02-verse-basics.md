# 02. Основы Verse

Verse — язык программирования Epic Games для UEFN. Шпаргалка по базовому синтаксису.

## Подключение модулей

```verse
using { /Fortnite.com/Devices }                       # устройства Fortnite
using { /Verse.org/Simulation }                        # базовая логика
using { /UnrealEngine.com/Temporary/Diagnostics }      # Print()
```

## Переменные и константы

```verse
X : int = 5            # константа (нельзя менять)
var Y : int = 0        # переменная (можно менять через set)
set Y = 10             # присваивание
set Y += 1             # Y становится 11
```

## Базовые типы

| Тип | Пример | Описание |
| --- | --- | --- |
| `int` | `42` | целое число |
| `float` | `3.14` | число с плавающей точкой |
| `logic` | `true`, `false` | булево значение |
| `string` | `"текст"` | строка |
| `agent` | — | агент (обычно игрок) |
| `[]int` | `array{1, 2, 3}` | массив целых |

## Строки и интерполяция

```verse
Name : string = "мир"
Print("Привет, {Name}!")        # подставит значение Name
Print("2 + 2 = {2 + 2}")        # выражение в {} вычисляется
```

## Функции

```verse
# Обычная функция, возвращает int
Add(A : int, B : int) : int =
    return A + B

# <suspends> — функция может приостанавливаться (async)
DoWork()<suspends>:void=
    Sleep(1.0)
    Print("Прошла секунда")
```

## Управление потоком

```verse
if (Score > 100):
    Print("Победа!")
else:
    Print("Ещё рано")

# Цикл (часто бесконечный игровой loop)
loop:
    Sleep(1.0)
    if (Done?):
        break
```

## Особенности Verse: failure (`?`) и `<decides>`

Многие выражения в Verse могут «провалиться» (fail) вместо возврата ошибки.
Вопросительный знак и контексты `if`/`for` обрабатывают такую возможность:

```verse
# Floor[] может провалиться, поэтому используем `or` как значение по умолчанию
Seconds : int = Floor[10.7] or 0     # 10
```

## Специфика — спецификаторы (`<...>`)

| Спецификатор | Значение |
| --- | --- |
| `<override>` | переопределяет метод базового класса |
| `<suspends>` | функция асинхронная, может приостанавливаться |
| `<decides>` | функция может провалиться (используется в `if`/`for`) |
| `<transacts>` | функция меняет состояние и может откатываться |

## Полезные ссылки

- Verse Language Reference: https://dev.epicgames.com/documentation/en-us/uefn/verse-language-reference
- Quick Reference: https://dev.epicgames.com/documentation/en-us/fortnite/verse-language-quick-reference
- Verse Glossary: https://dev.epicgames.com/documentation/en-us/fortnite/verse-glossary
