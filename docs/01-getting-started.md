# 01. С чего начать

Краткий путь от нуля до первого работающего Verse-устройства в UEFN.

## Что установить

1. **Epic Games Launcher** → вкладка *Unreal Editor for Fortnite* → установить **UEFN**.
2. **Visual Studio Code** — редактор для Verse-кода.
   Официальное расширение Verse устанавливается автоматически при первом запуске UEFN.
3. Аккаунт Epic Games с принятым соглашением создателя (Creator Agreement).

## Создание проекта

1. Запусти UEFN → откроется **Project Browser**.
2. Выбери шаблон. Для обучения удобны:
   - **Blank** — пустой остров;
   - **Feature Examples → Verse Device** — примеры устройств на Verse.
3. Задай имя проекта (например, `MyVerseProject`) и нажми **Create**.

## Первое устройство на Verse

1. В меню: **Verse → Verse Explorer**.
2. ПКМ по имени проекта → **Add new Verse file to project**.
3. Выбери шаблон **Verse Device**, задай имя (например, `hello_world_device`) → **Create**.
4. Открой файл двойным кликом — он откроется в VS Code.
5. Вставь код из [`../verse/devices/hello_world_device.verse`](../verse/devices/hello_world_device.verse).
6. Сохрани файл (`Ctrl+S`).
7. В UEFN: **Verse → Build Verse Code**. Должна появиться зелёная галочка.
8. В **Content Browser** найди скомпилированное устройство и перетащи его на уровень.
9. Нажми **Launch Session** → в Fortnite **Start Game**.
10. Открой лог (**Island Settings → Log**) — увидишь `Hello, world!`.

## Цикл разработки

- **Build Verse Code** — компиляция всего Verse-кода.
- **Push Verse Changes** — быстрая отправка только изменений кода в запущенную сессию (без полной перезагрузки).
- **Push Changes** — отправка всех изменений (ассеты, свойства, код).

## Дальше

- [02. Основы Verse](02-verse-basics.md)
- [03. Устройства и события](03-devices.md)
- [04. Структура проекта на диске](04-project-structure.md)
