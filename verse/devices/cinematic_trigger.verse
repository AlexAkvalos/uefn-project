# Пример: по триггеру проигрывает кинематику и скрывает HUD на время катсцены.
# ⚠️ GetHUDController().HideElements бьёт по ВСЕМ игрокам (известный баг). Для per-player
#    скрытия используй (PlayerUI:player_ui).HideHUDElements. Здесь — простой общий вариант.

using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Simulation }

cinematic_trigger := class(creative_device):

    @editable Trigger   : trigger_device            = trigger_device{}
    @editable Cinematic : cinematic_sequence_device = cinematic_sequence_device{}

    OnBegin<override>()<suspends>:void=
        Trigger.TriggeredEvent.Subscribe(OnTriggered)
        # Вернуть управление, когда кинематика закончится.
        Cinematic.StoppedEvent.Subscribe(OnCinematicStopped)

    OnTriggered(Agent : ?agent):void=
        HUDController := GetPlayspace().GetHUDController()
        Hidden : []hud_element_identifier = array{ creative_hud_identifier_all{} }
        HUDController.HideElements(Hidden)

        if (Player := Agent?):
            Cinematic.Play(Player)     # проиграть для инициатора
        else:
            Cinematic.Play()

    OnCinematicStopped(InPayload : payload):void=
        HUDController := GetPlayspace().GetHUDController()
        Shown : []hud_element_identifier = array{ creative_hud_identifier_all{} }
        HUDController.ResetElementVisibility(Shown)
