# 19. Как делать игру жанра «Steal a Brainrot»

Гайд по сборке популярного жанра (tycoon + кража юнитов) в UEFN. Каркас экономики:
[`../verse/games/brainrot_income.verse`](../verse/games/brainrot_income.verse).

> Жанр — клон роблоксовой «Steal a Brainrot»: у каждого игрока **база со слотами**,
> юниты («бреинроты») покупаются с **конвейера/шопа** и **генерируют валюту/сек**,
> а главный крючок — **кража** чужих юнитов с переносом дохода себе.

---

## 1. Игровой цикл

1. **Спавн/клейм базы** — каждому игроку выдаётся пустая база.
2. **Пассивный доход** — твои юниты тикают валюту каждые N секунд.
3. **Покупка** юнитов с конвейера/шопа → в следующий свободный слот.
4. **Кража** — заходишь в чужую *незапертую* базу, берёшь юнит, несёшь к себе, ставишь в слот (доход переходит тебе).
5. **Защита** — кнопка поднимает лазерный барьер; только владелец проходит N секунд (≈60с + 10с за rebirth).
6. **Апгрейд/Rebirth** — сброс ради старших юнитов, доп. этажей, длиннее лок, множители дохода.

Баланс из tycoon-гайдов: ранние покупки окупаются за ~1–3 мин, поздние ~10–20 мин; цена `Cost = Base × Mult^Level`, Mult ≈ 1.8.

---

## 2. Базы/плоты на игрока

Менеджер хранит список физических плотов и map `player → плот`. Два способа клейма:
- **по зоне:** на каждом плоте `mutator_zone_device`/`trigger_device`, первый вошедший = владелец;
- **по входу:** на `PlayerAddedEvent` берём следующий свободный плот из массива.

```verse
base_manager := class(creative_device):
    @editable Plots : []plot = array{}
    var PlotByPlayer : [player]plot = map{}
    OnBegin<override>()<suspends>:void =
        GetPlayspace().PlayerAddedEvent().Subscribe(OnJoined)
    OnJoined(Player : player):void =
        for (P : Plots, not P.Owner?):
            set P.Owner = option{Player}
            if (set PlotByPlayer[Player] = P) {}
            break
```

---

## 3. Юниты — пропы vs NPC

- **Пропы (рекомендуется для слотов):** дёшево, легко менять модель, легко «взять/нести/поставить».
  Спавн через `SpawnProp(Asset, Pos, Rot)` → получаешь `creative_prop` (`MoveTo`/`Hide`/`Dispose`).
- **NPC (`npc_spawner_device`):** если юниты ходят/анимируются; тяжелее, по устройству на тип.

Слоты — предразмещённые маркеры/`prop_manipulator_device`; на покупке заполняешь следующий индекс.

---

## 4. Экономика и стат-таблица

Сердце жанра — **стат-таблица** юнитов (есть официальный туториал Epic «Steal the Brainrot Stat Table»):

```verse
unit_rarity := enum { Common, Rare, Epic, Legendary, Mythic, BrainrotGod }
unit_def := struct:
    Name : string
    Rarity : unit_rarity
    Cost : int
    IncomeRate : int        # доход/тик
UnitTable : []unit_def = array{ ... }
```

- **Доход = сумма `IncomeRate` по юнитам в слотах игрока** — поэтому кража мгновенно влияет на доход.
- **Покупка только через `<decides><transacts>`** — чтобы валюта не уходила в минус/не дублировалась (классический дюп-баг).
- **Кнопки покупки:** `spawn{}` на каждую (в Verse нет замыканий — индекс захватывается через отдельную задачу).

Полный рабочий каркас (доход + покупка + персистентность) — в [`brainrot_income.verse`](../verse/games/brainrot_income.verse).

---

## 5. Механика кражи (определяет жанр)

1. **Взять:** на юните интеракция (`button_device`/`trigger`/зона). На взаимодействии, если не несёшь уже:
   помечаешь юнит «в переносе», убираешь его доход у владельца.
2. **Нести:** визуально «на спине» — варианты: выдать back-bling/косметику, или `MoveTo` пропа за игроком каждый тик, или скрыть проп + маркер над головой. *(Готового API «нести проп на спине» нет — фейкаешь.)*
3. **Положить:** при входе в свою зону — передать владение: поставить юнит в свой слот, прибавить его `IncomeRate`, сбросить состояние переноса.
4. **Ограничения:** один юнит за раз; войти можно только в базу с опущенным локом.

**Лазерный лок базы:**
```verse
LockBase(P : plot, Owner : player)<suspends>:void =
    P.LockGate.Enable()                              # барьер; только владелец
    Sleep(60.0 + RebirthCount(Owner) * 10.0)         # окно защиты
    P.LockGate.Disable()                             # снова уязвима
```
Проход «только владелец» — `barrier_device` с per-player классом/командой ИЛИ Verse-зона, выкидывающая чужих.
⚠️ Принудительный кулдаун обязателен — иначе базу запечатывают навсегда и цикл кражи ломается.

---

## 6. Конвейер покупки
- **Статичные станции:** ряд `conditional_button_device` с ценами (просто и надёжно).
- **Движущийся конвейер:** лента (static mesh + `prop_mover_device` или `MoveTo`-цикл);
  спавнер периодически кидает **взвешенно-случайный** юнит (`GetRandomInt` из `/Verse.org/Random`) — даёт эффект «10x редкий бреинрот».

---

## 7. Лидерборды и персистентность

- Данные — в **module-scoped `var weak_map(player, t)`**, тип — `class<final><persistable>` с дефолтами и `Version`.
- ⚠️ **Лимиты:** 256 КБ на игрока на weak_map; **макс. 4 weak_map на остров** → пакуй деньги+юниты+rebirth в ОДИН класс.
- Купленные юниты храни как **массив id (int)**, на заходе пересоздавай пропы.
- Лидерборд — `leaderboard_device` по стату (нетворс), или свой `billboard` из отсортированного `PlayerData`.

Подробно про сохранения — [15-data-and-persistence.md](15-data-and-persistence.md).

---

## 8. Девайсы по системам

| Система | Девайсы | Verse |
| --- | --- | --- |
| Клейм базы | `mutator_zone_device`, `trigger_device` | `PlayerAddedEvent`, `AgentEntersEvent`, `[player]plot` |
| Юниты | пропы / `prop_manipulator_device` / `npc_spawner_device` | `SpawnProp`, `creative_prop.MoveTo/Dispose` |
| Доход | `billboard_device`, `hud_message_device` | `weak_map`, persistable, `Sleep`, `Floor[]`, `<decides><transacts>` |
| Шоп | `conditional_button_device`, `button_device`, `item_granter_device` | `InteractedWithEvent.Await()`, `spawn{}` |
| Кража | интеракция на пропе, косметика-грантер | follow-`MoveTo`, своп владения |
| Лок | `barrier_device`, `button_device` | `Enable/Disable`, `Sleep` кулдаун |
| Лидерборд | `leaderboard_device` | сорт `PlayerData` |

---

## 9. Туториалы, шаблоны, монетизация

- **Epic (офиц.):** «How to Make a Steal the Brainrot Stat Table in UEFN» — самый авторитетный brainrot-специфичный источник.
- **Шаблоны:** Delta «Steal A Brainrot» (Kixov & Jop), UEFN Academy MAP PROJECT (Patreon).
- **GitHub-каркасы tycoon:** `KalikHub/UEFN-Tycoon-framework`, `ICrxzy/UEFN-Verse-WIP-Tycoon-System`.
- **Живая карта-референс:** `3225-0366-8885` «STEAL THE BRAINROT».
- **Монетизация:** Engagement Payouts (доля по минутам вовлечённости); tycoon/sim — длинные сессии + ~1.3× множитель.
  Крючки удержания жанра: rebirth, нетворс, лидерборды, лимит-ивенты «magical brainrot», дейлики.

> ⚠️ Самые слабодокументированные части — **механика переноса/кражи** и **owner-only барьер**;
> их почти всегда дорабатывают под конкретный шаблон. Код дохода/покупки/персистентности — надёжен.

---

## Источники
- Epic — Steal the Brainrot Stat Table: https://dev.epicgames.com/community/learning/tutorials/a6e9/fortnite-how-to-make-a-steal-the-brainrot-stat-table-in-uefn-verse-tutorial
- SpawnProp: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/spawnprop
- npc_spawner_device: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/npc_spawner_device
- Using Persistable Data: https://dev.epicgames.com/documentation/fortnite/using-persistable-data-in-verse
- UEFN Central — tycoon systems: https://uefncentral.com/blog/how-to-build-creative-tycoon-game-systems-in-uefn
- KalikHub/UEFN-Tycoon-framework: https://github.com/KalikHub/UEFN-Tycoon-framework
