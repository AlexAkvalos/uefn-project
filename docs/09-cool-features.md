# 09. Классные фишки и приёмы (из YouTube и X)

Подборка крутых техник, которые активно используют топовые UEFN-разработчики. Собрано из YouTube-туториалов 2026, постов в X (Twitter) и комьюнити.

---

## ⭐ Verse Fields — реактивные данные для UI

Самая горячая фишка 2026. **Verse Fields** (поля/`subscribable`-переменные) создают
реактивный источник данных: меняешь значение в коде — UI обновляется автоматически.

Идея:
- объявляешь поле (например, счёт, здоровье, таймер);
- привязываешь к нему текст/иконку виджета через `SetText()` / MVVM-биндинг;
- меняешь поле → виджет сам перерисовывается.

Применение: динамические HUD, счётчики, полоски здоровья, мультиплеер-поля (общие для всех игроков).

> Туториалы: [Dynamic UI with Verse Fields](https://www.youtube.com/watch?v=bWrRQv8htOU) ·
> [Verse Field Events + Multiplayer Fields](https://www.youtube.com/watch?v=K8ACEUiPMH4)

---

## 🎮 Кастомные/прямые инпуты в Verse

Можно ловить ввод игрока напрямую и строить свои схемы управления:
- **Input Trigger device** — подписка на нажатия, направленный ввод (виртуальный джойстик на мобилках).
- Кастомные кнопки с разными состояниями (pressed/released), своими иконками и раскладкой.

Открывает: tycoon/RPG/паззлы с нестандартным управлением, мобильный геймплей.

> [Creating DIRECT INPUTS in Verse](https://www.youtube.com/watch?v=vEeU1ln2DGU)

---

## 🎯 Entity Raycasting через Scene Graph

Разработчики (напр. **@hoskij** в X) показывают **рейкастинг на 100% в Verse**
через экспериментальные функции Scene Graph: пускаешь луч/sweep, получаешь
**hit entity** из результата — и делаешь с ним что угодно (урон, подсветка, взаимодействие).

Применение: стрельба-хитскан, выделение объектов, взаимодействие «по взгляду», кастомные коллизии.

> [Ray-Casting, Proximity и Linear Collision для UEFN/Verse](https://dev.epicgames.com/community/learning/tutorials/mzwL/fortnite-ray-casting-proximity-and-linear-collision-detections-for-uefn-verse) ·
> [пост @hoskij в X](https://x.com/hoskij/status/1864950878756876616)

---

## 🚗 Кастомный HUD транспорта

В Verse API добавили данные транспорта: **скорость, топливо, буст, HP машины**.
Плюс UI-материал для датчиков/спидометров. Итог — полностью свой HUD для гонок/машин
(как в шаблоне User Interfaces).

Бонус: **HUD Controller device** умеет скрывать/показывать UI транспорта.

---

## 🎬 Чистые кинематики

- **HUD Controller** / **Cinematic Sequence device** скрывают элементы HUD во время кат-сцены.
- Новая опция прячет неиспользуемые мобильные инпуты на время катсцены/попапа.
- **Sequencer** + анимация скелетных мешей + **MetaHumans** → кинематографичные сцены и сторителлинг.

> [How to Hide the HUD/UI During a Cinematic](https://www.youtube.com/watch?v=qSnfRBSbCOI)

---

## 🧩 Готовые «продвинутые системы», которые делают создатели

Популярные системы из туториалов — хорошие цели для практики:

| Система | Суть |
| --- | --- |
| **Advanced Revive** | многоуровневое воскрешение: больше тиммейтов рядом → сильнее эффект |
| **Rank System** | динамический ранг с UI на Verse Fields |
| **Day/Night & Weather** | Time of Day device + Verse-менеджер состояния времени/погоды |
| **Leaderboards** | таблицы лидеров на персистентности |
| **NPC AI системы** | спавн, поведение, реакция (через Scene Graph AI-компоненты) |

> [Advanced Revive System](https://www.youtube.com/watch?v=aJBSzEx4XQg) ·
> [Advanced Rank System](https://www.youtube.com/watch?v=eKtGDfGpbog) ·
> [Day/Night Events](https://uefncentral.com/blog/how-to-build-advanced-daynight-cycle-events-in-uef)

---

## ⚡ Оптимизация (то, что отличает профи)

- **Lighting Scalability Manager** — баланс качество/производительность от ПК до мобилок.
- **Distance-based culling** — прятать далёкие объекты, чтобы не рендерить лишнее.
- **Текстуры по размеру** — высокое разрешение только там, где видно вблизи; сжатие текстур.
- **Fortnite Tools** — Optimize Textures / Optimize Static Mesh / Add Physics (см. [05-latest-tech.md](05-latest-tech.md)).
- **Spatial Profiler** + Memory Diagnostics — находить узкие места и следить за памятью.
- **Mobile Preview** — проверять, как игра выглядит и тянет на телефоне.

> [Optimizing Performance in UEFN: Best Practices](https://thecreativeblok.com/optimizing-performance-in-uefn-best-practices/) ·
> [Optimize Islands for Mobile](https://www.fortnite.com/news/optimize-fortnite-islands-for-mobile-with-new-tools-in-uefn)

---

## 🧱 Контент-фишки

- **LEGO-ассеты и механики** прямо в UEFN: кубики, минифигурки, физика, разрушаемость.
- **MetaHumans** — гипер-реалистичные персонажи для катсцен.
- **Galleries/Prefabs** новых сезонов (Pacific Break, Brutal Bastion) — быстрый качественный арт.
- **Patchwork** — музыкальная система для динамического звука.

---

## 🐦 Кого читать в X (Twitter)

| Аккаунт | Чем полезен |
| --- | --- |
| [@FNCreate](https://x.com/FNCreate) | официальный — анонсы, сниппеты Verse+Scene Graph, роадмап |
| [@hoskij](https://x.com/hoskij) | продвинутый Verse/Scene Graph (raycasting и эксперименты) |
| [@SenkoUefn](https://x.com/senkouefn) | UEFN-разработка, приёмы |
| [@UnrealEditorFN](https://twitter.com/unrealeditorfn) | новости UEFN |
| [@_UEFN_](https://x.com/_UEFN_) | комьюнити, гайды |
| [@TheAweDam](https://twitter.com/theawedam) | UEFN/Fortnite Creative туториалы |

Хэштеги для поиска и постинга: **#UEFN**, **#FortniteCreative**, **#Verse**.

---

## 🔧 Инструменты комьюнити

- **UEFN Central** — 1200+ примеров Verse, гайды с кодом: https://uefncentral.com/examples
- **UEFN TOOLBELT** — 287+ Python-инструментов для world-building и Verse-автоматизации (open-source):
  https://forums.unrealengine.com/t/open-source-project-uefn-toolbelt-287-python-tools-for-world-building-verse-automation/2709005
- **Официальные сниппеты Epic**: https://dev.epicgames.com/community/fortnite/snippets
