# Пример мультиплеера: балансировка по двум командам на заходе + победа по выбиванию команды.
# Демонстрирует: team_collection, playspace-события, безопасный доступ к fort_character,
# подсчёт живых по командам в [team]int, end_game_device.Activate.
#
# ⚠️ GetFortCharacter[] часто ПРОВАЛИВАЕТСЯ внутри PlayerAddedEvent (пешка ещё не заспавнена) —
#    поэтому ждём её в цикле. Альтернатива — подписка на SpawnedEvent у Player Spawner.

using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Teams }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

team_match_manager := class(creative_device):

    @editable
    EndGame : end_game_device = end_game_device{}

    var Teams : []team = array{}

    # Число живых игроков по команде.
    var AliveByTeam : [team]int = map{}

    OnBegin<override>()<suspends>:void=
        TC := GetPlayspace().GetTeamCollection()
        set Teams = TC.GetTeams()
        for (T : Teams):
            if (set AliveByTeam[T] = 0) {}
        # Уже присутствующие игроки (напр. перезагрузка сессии).
        for (P : GetPlayspace().GetPlayers()):
            OnPlayerAdded(P)
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)

    # ЗАХОД: в наименьшую команду, затем отложенный трекинг персонажа.
    OnPlayerAdded(InPlayer : player):void=
        TC := GetPlayspace().GetTeamCollection()
        TargetTeam := FindSmallestTeam()
        if (TC.AddToTeam[InPlayer, TargetTeam]):
            Print("Игрок назначен в команду")
        spawn { TrackCharacterWhenReady(InPlayer) }

    FindSmallestTeam():team=
        TC := GetPlayspace().GetTeamCollection()
        var Best : team = Teams[0]
        var BestSize : int = 0x7fffffff
        for (T : Teams):
            if (Agents := TC.GetAgents[T], Agents.Length < BestSize):
                set BestSize = Agents.Length
                set Best = T
        Best

    # Ждём fort_character, затем подписываемся на его элиминацию.
    TrackCharacterWhenReady(InPlayer : agent)<suspends>:void=
        var MaybeChar : ?fort_character = false
        loop:
            if (FC := InPlayer.GetFortCharacter[]):
                set MaybeChar = option{ FC }
                break
            Sleep(0.25)
        if (FC := MaybeChar?, Team := GetPlayspace().GetTeamCollection().GetTeam[InPlayer]):
            if (Current := AliveByTeam[Team], set AliveByTeam[Team] = Current + 1) {}
            FC.EliminatedEvent().Subscribe(OnEliminated)

    # ЭЛИМИНАЦИЯ: уменьшить счётчик команды, проверить выбивание.
    OnEliminated(Result : elimination_result):void=
        DeadChar := Result.EliminatedCharacter
        if:
            DeadAgent := DeadChar.GetAgent[]
            DeadTeam  := GetPlayspace().GetTeamCollection().GetTeam[DeadAgent]
            Current   := AliveByTeam[DeadTeam]
        then:
            NewCount := Current - 1
            if (set AliveByTeam[DeadTeam] = NewCount) {}
            if (NewCount <= 0):
                DeclareWinnerAgainst(DeadTeam)

    # Найти выжившую команду и завершить игру в её пользу.
    DeclareWinnerAgainst(LosingTeam : team):void=
        TC := GetPlayspace().GetTeamCollection()
        for (T : Teams, T <> LosingTeam):
            if (Agents := TC.GetAgents[T], Survivor := Agents[0]):
                EndGame.Activate(Survivor)   # команда выжившего объявляется победителем
                Print("Игра завершена — победитель определён")
                return
