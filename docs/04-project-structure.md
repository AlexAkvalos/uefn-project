# 04. Структура проекта UEFN на диске

Когда UEFN создаёт проект, на диске появляется набор папок. Важно понимать,
что версионировать в git, а что — нет.

## Типичная структура проекта UEFN

```
MyVerseProject/
├── MyVerseProject.uefnproject     ← файл проекта UEFN
├── Content/                       ← карты, ассеты (.umap, .uasset)
├── Plugins/
│   └── MyVerseProject/
│       ├── MyVerseProject.uplugin
│       └── Content/
│           └── *.verse            ← ЗДЕСЬ живёт твой Verse-код
├── Intermediate/                  ← кэш сборки (НЕ версионировать)
├── Saved/                         ← автосейвы, логи (НЕ версионировать)
└── DerivedDataCache/              ← кэш данных (НЕ версионировать)
```

## Что класть в git

| Путь | В git? | Почему |
| --- | --- | --- |
| `*.verse` | ✅ да | исходный код — главное, что версионируем |
| `*.uefnproject`, `*.uplugin` | ✅ да | описание проекта (текстовые) |
| `Content/**/*.umap`, `*.uasset` | ⚠️ опционально | бинарники; лучше через **Git LFS** |
| `Intermediate/`, `Saved/`, `DerivedDataCache/` | ❌ нет | генерируются автоматически |
| `Binaries/`, `Build/` | ❌ нет | результаты сборки |

Эти правила уже учтены в корневом [`.gitignore`](../.gitignore).

## Связь с этим репозиторием

Этот репозиторий — **рабочее пространство для кода и заметок**, а не сам проект UEFN.
Папка [`verse/`](../verse/) содержит эталонные `.verse`-файлы.

Два рабочих варианта:

1. **Репозиторий отдельно от проекта** (текущая структура).
   Копируй код из `verse/` в `.verse`-файлы, созданные внутри UEFN.

2. **Репозиторий = корень проекта UEFN.**
   Инициализируй git прямо в папке проекта UEFN (`MyVerseProject/`),
   используя этот `.gitignore`. Тогда `Plugins/<Project>/Content/*.verse`
   попадут в историю автоматически.

## Git LFS для ассетов (опционально)

Если нужно хранить `.uasset`/`.umap` в git, настрой [Git LFS](https://git-lfs.com/):

```bash
git lfs install
git lfs track "*.uasset"
git lfs track "*.umap"
```

И убери соответствующие строки из `.gitignore`.

## Полезные ссылки

- Документация UEFN: https://dev.epicgames.com/documentation/en-us/uefn/unreal-editor-for-fortnite-documentation
- Совместная работа и публикация: https://dev.epicgames.com/documentation/en-us/fortnite/collaborate-in-unreal-editor-for-fortnite
