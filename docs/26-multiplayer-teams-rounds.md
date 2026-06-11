# 26. Мультиплеер: команды, раунды, победа

Game flow в UEFN: команды, плейспейс, классы, раунды, условия победы, фазы.
Пример: [`../verse/games/team_match_manager.verse`](../verse/games/team_match_manager.verse).

---

## 1. Команды

Настраиваются в **Island Settings → Game** (число команд, индексы с **1**). На команду — один **Team Settings & Inventory device** (имя/цвет/инвентарь).

### `fort_team_collection` (через `GetPlayspace().GetTeamCollection()`)
```verse
GetTeams() : []team                                    # ВСЕ команды (НЕ failable)
GetTeam[Agent : agent] : team                          # команда агента (failable)
GetAgents[Team : team] : []agent                       # агенты команды (failable)
AddToTeam[Agent : agent, Team : team] : void           # назначить в команду (failable)
IsOnTeam[Agent : agent, Team : team] : logic
GetTeamAttitude[A : team, B : team] : team_attitude     # дружеств./враждебн.
GetTeamAttitude[A : agent, B : agent] : team_attitude
```
`[]` = failable (в `if`/`for`); `GetTeams()` с `()` — безопасен.

**`team` — непрозрачный объект** (не int). Сравнение `=` работает. 1-based индекс команды:
```verse
if (PT := TC.GetTeam[Player], Idx := TC.GetTeams().Find[PT]):
    CreativeIndex := Idx + 1     # массивы 0-based, команды 1-based
```

**Смена команды в рантайме:** `TC.AddToTeam[Agent, Team]` (чистый Verse) или
`class_and_team_selector_device.ChangeTeam(Agent)` (с инвентарём/классом устройства).

---

## 2. Playspace и игроки
```verse
GetPlayspace() : fort_playspace                        # метод creative_device
# fort_playspace:
GetPlayers() : []player                                # только люди
GetParticipants() : []agent                            # люди + AI
GetTeamCollection() : fort_team_collection
PlayerAddedEvent() : listenable(player)
PlayerRemovedEvent() : listenable(player)
```
- **`agent`** — абстрактная личность (человек/ИИ); большинство API берут agent.
- **`player`** — человек (подтип agent); из `GetPlayers()`.
- **`fort_character`** — пешка в мире (урон/хил/элиминация): `Agent.GetFortCharacter[]` (failable).
- ⚠️ **Гоча:** `GetFortCharacter[]` **проваливается в `PlayerAddedEvent`** (пешка ещё не заспавнена) — жди `SpawnedEvent` Player Spawner или ретрай в цикле.

---

## 3. Классы
**Class Designer device** (определяет класс) + селектор.
**`class_and_team_selector_device`:**
```verse
ChangeClass(Agent) / ChangeTeam(Agent) / ChangeTeamAndClass(Agent) : void
ClassSwitchedEvent / TeamSwitchedEvent : listenable(agent)
Enable() / Disable()
```
⚠️ Прочитать класс из Verse нельзя — **веди свою `[agent]…` map**, если нужно знать класс.

---

## 4. Раунды — `round_settings_device`
```verse
RoundBeginEvent : listenable(payload)        # старт раунда (RoundEnded НЕТ!)
EndRound(Agent : agent) : void               # завершить; команда агента = победитель
DisableEndRoundConditions() : void
EnableMatchmaking() / DisableMatchmaking() / ToggleMatchmaking()
Enable() / Disable()
```
**User Options (в редакторе):** Keep Items/Resources Between Rounds, **Reset Class Each Round**. **Round Settings перекрывает Island Settings**.

**v39 — матчмейкинг на Round Settings** (можно менять по раундам, перекрывает Island Settings):
- **MMS Backfill** (добор пустых слотов), **Social Joining**, **Join In Progress Behavior**
  (**Spawn During New Round** / **Spawn Immediately** / **Watch Only**), **Join In Progress Assigned Team**.
- ⚠️ Баг: «Spawn During New Round» может насильно кидать вошедших в **Team 1** — балансируй поздних в Verse.

---

## 5. Победа и счёт
**`end_game_device`:**
```verse
Activate(Agent : agent) : void   # завершить игру; команда агента = победитель (GameEnded НЕТ)
Enable() / Disable()
```
**Детект элиминаций — `fort_character.EliminatedEvent()`:**
```verse
EliminatedEvent() : listenable(elimination_result)
elimination_result:
    EliminatedCharacter  : fort_character    # кто погиб
    EliminatingCharacter : ?fort_character   # убийца (false при environmental)
```
Команда убийцы:
```verse
if (Killer := Result.EliminatingCharacter?, KA := Killer.GetAgent[], KT := TC.GetTeam[KA]):
    # счёт команде KT
```
Прочее: **Score Manager**, **Elimination Manager**. Last-team-standing — считай живых в `[team]int`, при 0 → `EndGame.Activate(выживший)`.

---

## 6. Фазы игры
Pre-game / gameplay + раунды. У устройств опция **Enabled During Phase**. В Verse: `OnBegin` (старт рантайма),
подписки на `RoundBeginEvent` / `PlayerAddedEvent`; конец игры **ты сам** инициируешь (`Activate`/`EndRound`).
Единого «GameStartedEvent» нет — опирайся на `RoundBeginEvent` + Enabled During Phase.

---

## 7. Спавн
**Player Spawner device** с **team index** (+ class index). `SpawnedEvent` — **безопасное место** для `GetFortCharacter[]`:
```verse
@editable Spawner : player_spawner_device = player_spawner_device{}
Spawner.SpawnedEvent.Subscribe(OnSpawn)
```
Респаун — Island Settings (вкл/время/иммунитет) + команда спавн-пэдов.

---

## 8. Паттерны
- **TDM:** 2 команды, Team Settings на каждую, Score Manager на килл, End Game по порогу.
- **FFA:** много команд по одному или single hostile pool.
- **Round elimination:** Round Settings + Reset Class Each Round, победа last-team-standing → `EndRound(выживший)`.
- **Балансировка на заходе (v39):** на `PlayerAddedEvent` найти команду с наим. `GetAgents[T].Length` → `AddToTeam`.

---

## 9. Лимиты, гочи, best practices
- `GetFortCharacter[]` падает в `PlayerAddedEvent` — используй `SpawnedEvent` или ретрай-цикл.
- failable: `GetTeam[]`/`GetAgents[]`/`AddToTeam[]`/`IsOnTeam[]`/`GetTeamAttitude[]`; `GetTeams()` — безопасен.
- `team` непрозрачен → индекс через `GetTeams().Find[]` + 1.
- Нет `GameEndedEvent`/`RoundEndedEvent` — конец **инициируешь сам**; есть только `RoundBeginEvent`.
- `end_game_device.Activate` требует **agent** (его команда побеждает).
- Класс из Verse не читается — веди свою map.
- Версии UEFN/клиента/MMS должны совпадать, иначе матчмейкинг/JIP ломается.

---

## Разбор примера (`team_match_manager.verse`)
- На заходе: балансировка в наименьшую команду (`FindSmallestTeam` + `AddToTeam`).
- Отложенный `TrackCharacterWhenReady` (ретрай-цикл вокруг `GetFortCharacter[]`) → подписка на `EliminatedEvent`.
- Счёт живых в `[team]int`; при 0 → `DeclareWinnerAgainst` → `EndGame.Activate(выживший)`.

---

## Источники
- fort_team_collection: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/teams/fort_team_collection
- fort_playspace: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/playspaces/fort_playspace
- elimination_result: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/game/elimination_result
- end_game_device: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/end_game_device
- round_settings_device: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/round_settings_device
- Team Multiplayer Balancing: https://dev.epicgames.com/documentation/en-us/fortnite/team-multiplayer-balancing-in-verse
- Team Elimination (туториал): https://dev.epicgames.com/documentation/en-us/fortnite/team-elimination-4-tracking-players-using-maps-in-verse
- v39.00 release notes: https://dev.epicgames.com/documentation/en-us/fortnite/39-00-fortnite-ecosystem-updates-and-release-notes
