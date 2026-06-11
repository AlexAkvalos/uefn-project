# 21. Аудио и Patchwork

Звук в UEFN: аудио-устройства, Verse-API, импорт, и **Patchwork** — система живой адаптивной музыки.
Пример: [`../verse/audio/music_manager.verse`](../verse/audio/music_manager.verse).

---

## A. Аудио

### Устройства
| Устройство | Verse-класс | Роль |
| --- | --- | --- |
| **Audio Player** | `audio_player_device` | современный, рекомендуемый — играет sound wave/cue: SFX, музыка, цикл, спатиализация, аттенюация, фейды, per-player |
| **Audio Mixer** | `audio_mixer_device` | баланс громкости групп звуков через control buses (footsteps/weapons/music/vehicles) |
| **Radio** | `radio_device` | легаси, играет лицензированные треки; Epic советует Audio Player |
| **Speaker** | (Patchwork) | вывод звука Patchwork (не Audio Player) |

**Ключевые опции Audio Player** (в Details, не из Verse): Volume (линейно: 0.5 = половина), Playback Speed,
Restart Audio when Activated, Fade In/Out Duration, **Enabled During Phase**, **Enable Spatialization**,
**Enable Volume Attenuation** (+ Min/Falloff Distance), **Can be Heard By** (Everyone/Instigator/Registered…),
**Play Location**. Зацикливание — свойство **ассета** (sound wave/cue), не чекбокс девайса.

### Verse-API `audio_player_device`
```verse
Play() / Play(Agent:agent)       # для всех / для конкретного игрока
Stop() / Stop(Agent:agent)
Enable() / Disable()  Show() / Hide()
Register(Agent) / Unregister(Agent) / UnregisterAll()   # per-player набор
GetTransform() / MoveTo(...) / TeleportTo[](...)        # позиционирование
```
⚠️ **Чего НЕТ в Verse** (частые неверные предположения):
- **`SetVolume()`** — громкость/фейды/аттенюация только в Details, не из кода.
- **`AudioFinishedEvent`** — события окончания нет.
- **`PlaySoundAtLocation` / `FSoundAttenuationSettings`** — это C++ Unreal, в UEFN недоступно.
  «Звук в точке» = **поставить/телепортировать сам девайс** туда и `Play()`.

**`audio_mixer_device`:** `ActivateMix()` / `DeactivateMix()` / `Register`/`Unregister`/`UnregisterAll`.

### Импорт кастомного аудио
- Форматы: **WAV, AIF, FLAC, OGG**; макс. длина **300 сек**.
- Drag-and-drop / Import в Content Browser → получаешь **Sound Wave**; из нескольких можно собрать **Sound Cue**
  (рандомные one-shot'ы с весами). Зацикливание — свойство wave/cue.
- Назначь ассет в опции Audio Player; в Verse прокидывай **ссылку на устройство** через `@editable`.

### 3D-звук, кинематика, паттерны
- 3D = **Enable Spatialization** + **Enable Volume Attenuation** (+ Min/Falloff Distance).
- Фоновая музыка = **выключить** аттенюацию и спатиализацию (ровно по всему острову).
- Кинематика: привязать Audio Player к актёру в **Sequencer** (звук следует за позицией).
- Паттерны: **BGM-менеджер** (один зацикленный плеер, `Play`/`Stop` по состоянию игры);
  **SFX на события** (`Play()` всем / `Play(Agent)` одному на подбор/элиминацию); **per-player** через `Register`+`Play`.

---

## B. Patchwork — живая адаптивная музыка

### Что это
Набор музыкальных + визуальных устройств для создания **оригинальной музыки**, синхронной с геймплеем
(ритм-игры, адаптивный саундтрек, реактивные хазарды). Отличие от Audio Player:
Audio Player играет **готовый файл**, а Patchwork **генерирует музыку вживую** из секвенсоров/инструментов,
держа всё в темпе и тональности через Music Manager. Вывод — через **Speaker**, не Audio Player.

### Устройства (14)
Distortion/Echo Effect, **Drum Player**, **Drum Sequencer**, **Instrument Player**, **LFO Modulator**,
**Music Manager (M-MGR)**, **Note Progressor**, **Note Sequencer**, **Note Trigger**, **Omega Synthesizer**,
**Speaker**, **Step Modulator**, **Value Setter** (+ **Song Sync** для MIDI в Creative).

Главные:
- **Music Manager (M-MGR)** — мастер-часы/тональность: **Key** (12 нот + Random), **Mode** (Major/Minor),
  **Tempo** 60–180 BPM, **Time Signature**, **Enabled Switch** (старт с бита 0). Держит всё в темпе и в ключе.
- **Note Sequencer** — мелодические паттерны; **Drum Sequencer/Player** — ритм.
- **Instrument Player / Omega Synthesizer** — источники звука (через Note-кабели).
- **Note Trigger** — ловит ноты и **шлёт события геймплейным девайсам** (мост музыка→геймплей).
- **Modulators** (LFO/Step/Value Setter) — модуляция параметров; **Speaker** — вывод.

### Сборка музыки
1. Расставь устройства. 2. Патчи через **Details → User Options → Port Connections** (Audio/Note/Modulator Out).
3. Добавь **Speaker**. 4. Настрой **Music Manager** (темп/ключ). 5. Запусти **Live Edit** — только там слышно.
Слои = несколько секвенсоров/инструментов; адаптивная интенсивность = вкл/выкл слоёв или модуляция.

⚠️ **Гочи UEFN:** кабели **визуально не соединяются** в редакторе и **звука в редакторе нет** —
связи и звук работают только в **Live Edit / Create-сессии** (там авто-выдаётся Patchwork Tool).

### Управление из Verse
Класс **`music_manager_device`**: прокинь через `@editable` и `Enable()`/`Disable()` — старт/стоп всего микса.
```verse
music_controller := class(creative_device):
    @editable MusicManager : music_manager_device = music_manager_device{}
    StartMusic():void = MusicManager.Enable()    # старт с бита 0
    StopMusic():void  = MusicManager.Disable()
```
Для реакций музыка→геймплей в основном используют **Note Trigger** в графе (событие на ноте) + direct event binding,
а не подписку на бит в Verse.

> ⚠️ Точный набор событий/функций тайминга у `music_manager_device` сверх `Enable`/`Disable`
> (пер-бит событие, рантайм-сеттеры темпа/ключа) зависит от версии — сверяй в Verse Explorer своей сборки.
> Смену темпа/ключа/интенсивности гони через опции девайсов + Note Trigger + модуляторы.

### Зачем
Динамический саундтрек (боевой слой вкл/выкл), ритм-игры (Festival-стиль), платформеры с хазардами «в бит», гонки с музыкой.

---

## C. Best practices, лимиты, лицензии

**Best practices:** Audio Player вместо Radio/легаси; для BGM выключай аттенюацию+спатиализацию;
баланс через Audio Mixer + control buses (а не громкость по одному); рандомные one-shot — Sound Cue с весами;
движущийся звук — привязка к актёру в Sequencer; per-player через `Play(Agent)`/`Register`.

**Лимиты/гочи:** нет рантайм-`SetVolume`; нет `PlaySoundAtLocation`/`FSoundAttenuationSettings`;
аудио только WAV/AIF/FLAC/OGG ≤ 300 сек; Patchwork без звука/кабелей в редакторе — только Live Edit.
«Нет звука» обычно из-за: неверной **Enabled During Phase**, Volume = 0, аттенюации, отсутствия триггера/Auto Play.

**Лицензии:** импортируешь только то, на что есть **права** — иначе **провал валидации** при публикации
(Fortnite Developer Rules / UEFN Supplemental Terms). **Patchwork-музыка обходит лицензирование** (ты её авторишь сам) —
сильный довод делать оригинальный саундтрек через Patchwork.

---

## Разбор примера (`music_manager.verse`)
- Два `audio_player_device`: зацикленный BGM (аттенюация выкл) + one-shot SFX подбора.
- `OnBegin` стартует музыку и подписывается на `ItemReceivedEvent` грантера.
- На подборе `PickupSfx.Play(Agent)` — слышит только подобравший. **Нет `SetVolume`** — его нет в API.

---

## Источники
- Audio Player device: https://dev.epicgames.com/documentation/fortnite/using-audio-player-devices-in-unreal-editor-for-fortnite
- audio_player_device (Verse API): https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/audio_player_device
- Audio Mixer device: https://dev.epicgames.com/documentation/fortnite/using-audio-mixer-devices-in-unreal-editor-for-fortnite
- Импорт кастомного аудио: https://dev.epicgames.com/documentation/en-us/fortnite/importing-custom-audio-in-unreal-editor-for-fortnite
- Patchwork в UEFN: https://dev.epicgames.com/documentation/en-us/uefn/using-fortnite-patchwork-in-unreal-editor-for-fortnite
- Composing with Patchwork: https://dev.epicgames.com/documentation/en-us/fortnite/composing-with-patchwork-in-fortnite-creative
- Music Manager device: https://dev.epicgames.com/documentation/en-us/fortnite/using-patchwork-music-manager-devices-in-fortnite-creative
- Note Trigger device: https://dev.epicgames.com/documentation/en-us/fortnite/using-patchwork-note-trigger-devices-in-fortnite-creative
- Syncing music & gameplay (Patchwork + Verse): https://dev.epicgames.com/community/snippets/GRGz/syncing-music-and-gameplay-using-fortnite-patchwork-and-verse
