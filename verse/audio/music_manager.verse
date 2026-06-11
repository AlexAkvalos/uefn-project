# Пример: менеджер фоновой музыки + one-shot SFX на событие подбора.
# Зацикленная BGM, остановка, и звук подбора, который слышит только подобравший игрок.
#
# ⚠️ ВАЖНО: у audio_player_device в Verse НЕТ SetVolume / AudioFinishedEvent.
#    Громкость, фейды, аттенюация, спатиализация настраиваются в панели Details устройства,
#    НЕ из кода. Для фоновой музыки в опциях устройства ОТКЛЮЧИ
#    Enable Volume Attenuation и Enable Spatialization (чтобы слышно по всему острову ровно).

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

music_manager := class(creative_device):

    # BGM: назначь ЗАЦИКЛЕННЫЙ sound wave/cue (зацикливание — свойство ассета, не девайса).
    @editable
    BgmPlayer : audio_player_device = audio_player_device{}

    # SFX подбора: короткий НЕзацикленный звук.
    @editable
    PickupSfx : audio_player_device = audio_player_device{}

    # Источник события подбора (грантер/кнопка/триггер).
    @editable
    PickupItem : item_granter_device = item_granter_device{}

    OnBegin<override>()<suspends>:void=
        StartMusic()
        PickupItem.ItemReceivedEvent.Subscribe(OnPickup)

    StartMusic():void=
        BgmPlayer.Play()        # зациклится, т.к. ассет зациклен

    StopMusic():void=
        BgmPlayer.Stop()

    # ItemReceivedEvent отдаёт агента, который подобрал.
    OnPickup(Agent : agent):void=
        PickupSfx.Play(Agent)   # one-shot, слышит только этот игрок

    # Пример смены трека на «боевой» (вызывай из своей логики).
    # Для второго трека добавь ещё один @editable audio_player_device.
    SwitchTrack(NewTrack : audio_player_device):void=
        BgmPlayer.Stop()
        NewTrack.Play()
