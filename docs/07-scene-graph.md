# 07. Scene Graph: устройства vs компоненты

Scene Graph — современная архитектура UEFN (вышла из эксперимента, публикация островов на Scene Graph в бете).
Это сдвиг от модели «большое устройство `creative_device`» к **entity + components** (как в «настоящем» Unreal).

---

## Два подхода

### Старый: Verse-устройство (`creative_device`)

```verse
my_device := class(creative_device):
    OnBegin<override>()<suspends>:void=
        Print("Запуск")
```

Одно устройство = вся логика. Просто, но плохо масштабируется и переиспользуется.

### Новый: Verse-компонент (`component`)

```verse
my_component := class<final_super>(component):
    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()

    OnSimulate<override>()<suspends>:void =
        loop:
            Sleep(1.0)

    OnEndSimulation<override>():void =
        (super:)OnEndSimulation()
```

Компонент навешивается на **сущность (entity)**. Несколько маленьких компонентов
комбинируются на одной сущности — модульно и переиспользуемо.

Полный пример: [`../verse/components/disappear_on_loop_component.verse`](../verse/components/disappear_on_loop_component.verse).

---

## Ключевые понятия

| Термин | Что это |
| --- | --- |
| **Entity** (`entity`) | контейнер для компонентов; может содержать вложенные сущности. С v39 `agent` тоже подкласс entity |
| **Component** (`component`) | единица поведения/данных, навешивается на сущность |
| **Prefab** | переиспользуемая иерархия сущностей+компонентов; редактируется в **Prefab Editor** |

## Жизненный цикл компонента

```
Initialized → AddedToScene → BeginSimulation
            → EndSimulation → RemovingFromScene → Uninitializing
```

Главные методы для переопределения:

- `OnBeginSimulation<override>()` — старт (вызови `(super:)OnBeginSimulation()` внутри).
- `OnSimulate<override>()<suspends>` — основная async-логика (loop/Sleep); отменяется при удалении.
- `OnEndSimulation<override>()` — очистка.

## Нужные модули

```verse
using { /Verse.org }
using { /Verse.org/Native }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SceneGraph }
```

## Доступ к сущности и соседним компонентам

```verse
# Получить сущность, на которой висит компонент:
Entity := GetEntity()

# У NPC можно получить сущность из поведения / персонажа:
# npc_behavior.GetEntity[]   или   fort_character.GetEntity[]
```

---

## Когда что использовать

- **Учишься / простой прототип** → начни с `creative_device` (проще, больше туториалов).
- **Сложный/масштабируемый проект, кастомные предметы, новый AI/физика** → Scene Graph компоненты.
- Есть **bridge-компонент** для частичной совместимости устройств и Scene Graph.

> ⚠️ `Scene Events` и `Custom Items` местами ещё экспериментальные — сверяйся со свежими релиз-ноутами.

---

## Источники

- Официальная дока (создание компонента): https://dev.epicgames.com/documentation/en-us/fortnite/creating-your-own-component-using-verse-in-unreal-editor-for-fortnite
- Новость: Scene Graph в бете для публикации: https://www.fortnite.com/news/publish-fortnite-islands-created-with-scene-graph-now-in-beta
- Romero Blueprints — Introduction to Scene Graph: https://romeroblueprints.blogspot.com/2025/11/uefn-verse-sg-introduction-to-scene.html
- Community tutorial (Components vs Entities): https://dev.epicgames.com/community/learning/tutorials/3JoR/fortnite-components-vs-entities-a-closer-look-at-the-prefab-scene-graph-example-in-uefn
