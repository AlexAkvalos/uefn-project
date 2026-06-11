# Пример ПЕРСИСТЕНТНОЙ системы прогресса игрока (уровень/XP/монеты) С ВЕРСИОНИРОВАНИЕМ.
# Сохраняется между сессиями. Спроектировано так, чтобы схему можно было безопасно
# расширять ПОСЛЕ публикации (иначе ловишь ошибку "Unable to update map already published").
#
# Ключевые правила персистентности:
#   - данные хранятся ТОЛЬКО в module-scoped `var weak_map(player, T)`;
#   - T — класс с <final><persistable>, БЕЗ var-полей (только неизменяемые), без суперкласса;
#   - после публикации МОЖНО добавлять новое поле с дефолтом; НЕЛЬЗЯ менять тип/удалять/двигать файл.

using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# ---------- ВЕРСИОНИРОВАННАЯ СХЕМА ----------

# v1 — как было опубликовано изначально. НИКОГДА не редактируем после публикации.
progress_v1 := class<final><persistable>:
    Level : int = 1
    XP    : int = 0
    Coins : int = 0

# v2 — добавили Prestige и Playtime. Это НОВЫЙ класс, а не правка v1.
progress_v2 := class<final><persistable>:
    Level        : int = 1
    XP           : int = 0
    Coins        : int = 0
    Prestige     : int = 0
    PlaytimeSecs : int = 0

# Внешняя обёртка: по одному option-слоту на версию. Заполнен всегда только один.
# Добавить позже V3:?progress_v3 = false — это ЛЕГАЛЬНОЕ изменение после публикации
# (новое поле + дефолт). Поэтому схема растёт без поломок сохранений.
player_save := class<final><persistable>:
    V1 : ?progress_v1 = false
    V2 : ?progress_v2 = false

# ЕДИНСТВЕННОЕ место, где данные сохраняются (module scope).
var SaveMap : weak_map(player, player_save) = map{}

# ---------- ЛОГИКА ПРОГРЕССА ----------

XP_PER_LEVEL : int = 100

# Загрузить и при необходимости мигрировать до текущей версии (v2).
LoadProgress(Player : player)<transacts>:progress_v2 =
    if (Save := SaveMap[Player]):
        if (Cur := Save.V2?):
            return Cur                       # уже актуальная версия
        else if (Old := Save.V1?):           # миграция v1 -> v2
            return progress_v2:
                Level := Old.Level
                XP    := Old.XP
                Coins := Old.Coins
                # Prestige / PlaytimeSecs берут дефолты
    progress_v2{}                            # новый игрок

# Записать актуальные данные обратно (всегда под V2).
SaveProgress(Player : player, Data : progress_v2):void =
    set SaveMap[Player] = player_save:
        V1 := false
        V2 := option{ Data }

# Начислить XP, обработать апы уровня, сохранить.
GrantXP(Player : player, Amount : int):void =
    P := LoadProgress(Player)
    var NewXP    : int = P.XP + Amount
    var NewLevel : int = P.Level
    loop:
        if (NewXP >= XP_PER_LEVEL):
            set NewXP    -= XP_PER_LEVEL
            set NewLevel += 1
        else:
            break
    Updated := progress_v2:
        Level := NewLevel
        XP    := NewXP
        Coins := P.Coins
        Prestige := P.Prestige
        PlaytimeSecs := P.PlaytimeSecs
    SaveProgress(Player, Updated)
    Print("Игрок: уровень {Updated.Level}, XP {Updated.XP}")

GrantCoins(Player : player, Amount : int):void =
    P := LoadProgress(Player)
    Updated := progress_v2:
        Level := P.Level
        XP    := P.XP
        Coins := P.Coins + Amount
        Prestige := P.Prestige
        PlaytimeSecs := P.PlaytimeSecs
    SaveProgress(Player, Updated)

# ---------- УСТРОЙСТВО ----------

progress_device := class(creative_device):

    @editable{ ToolTip := "Кнопка: начислить XP." }
    XPButton : button_device = button_device{}

    @editable{ ToolTip := "Кнопка: начислить монеты." }
    CoinButton : button_device = button_device{}

    @editable{ ToolTip := "Табло для показа прогресса." }
    InfoBoard : billboard_device = billboard_device{}

    @editable
    XPReward : int = 25

    @editable
    CoinReward : int = 50

    InfoText<localizes>(Lvl : int, XP : int, Coins : int):message =
        "Уровень {Lvl}  |  XP {XP}  |  Монеты {Coins}"

    Refresh(Player : player):void =
        P := LoadProgress(Player)
        InfoBoard.SetText(InfoText(P.Level, P.XP, P.Coins))

    # Новый игрок не получает запись автоматически — инициализируем.
    EnsurePlayer(Player : player):void =
        if (not SaveMap[Player]):
            set SaveMap[Player] = player_save{}   # оба option = false

    OnXP(Agent : agent):void =
        if (Player := player[Agent]):
            GrantXP(Player, XPReward)
            Refresh(Player)

    OnCoins(Agent : agent):void =
        if (Player := player[Agent]):
            GrantCoins(Player, CoinReward)
            Refresh(Player)

    OnPlayerAdded(Player : player):void =
        EnsurePlayer(Player)
        Refresh(Player)

    OnBegin<override>()<suspends>:void=
        Sleep(0.0)
        XPButton.InteractedWithEvent.Subscribe(OnXP)
        CoinButton.InteractedWithEvent.Subscribe(OnCoins)
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
        for (Player : GetPlayspace().GetPlayers()):
            OnPlayerAdded(Player)
