# Пример КАСТОМНОГО HUD на Verse: показывает каждому игроку счёт в правом верхнем углу
# и кнопку по центру. Демонстрирует player_ui, canvas, text_block, button_loud,
# anchors/offsets/alignment, реактивное обновление через SetText.
#
# ВАЖНО про текст: всё, что показывается на экране, должно быть message (локализуемая
# строка) — не string. Объявляется через <localizes>, значения подставляются через {}.

using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }                          # GetPlayerUI, button_loud
using { /UnrealEngine.com/Temporary/UI }            # canvas, text_block, anchors, margin
using { /UnrealEngine.com/Temporary/SpatialMath }   # vector2
using { /Verse.org/Colors }                         # NamedColors
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Локализуемое сообщение для счёта.
ScoreMessage<localizes>(Score : int) : message = "Счёт: {Score}"

# Текст кнопки.
ButtonLabel<localizes> : message = "Нажми меня"

custom_hud_device := class(creative_device):

    # Состояние счёта на каждого игрока (agent — ключ).
    var ScorePerAgent : [agent]int = map{}

    # Виджет текста на каждого игрока, чтобы потом обновлять его через SetText.
    var ScoreWidgetPerAgent : [agent]text_block = map{}

    OnBegin<override>()<suspends>:void=
        # Показать HUD всем, кто уже в игре, и всем, кто зайдёт позже.
        Playspace := GetPlayspace()
        for (Player : Playspace.GetPlayers()):
            ShowHUD(Player)
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerJoined)

    OnPlayerJoined(Player : player):void=
        ShowHUD(Player)

    # Строит и добавляет HUD конкретному игроку.
    # ВАЖНО: создаём НОВЫЙ экземпляр виджета на каждого игрока — нельзя шарить один
    # инстанс между игроками (обновления и удаление будут конфликтовать).
    ShowHUD(Player : player):void=
        if (PlayerUI := GetPlayerUI[Player]):

            # Текст счёта.
            ScoreText : text_block = text_block:
                DefaultText := ScoreMessage(0)
                DefaultTextColor := NamedColors.White
                DefaultJustification := text_justification.Right

            # Кнопка.
            MyButton : button_loud = button_loud{}
            MyButton.SetText(ButtonLabel)
            MyButton.OnClick().Subscribe(OnButtonClicked)

            # Canvas с двумя слотами: счёт справа-сверху, кнопка по центру.
            HudCanvas : canvas = canvas:
                Slots := array:
                    # Счёт: якорь в правом-верхнем углу экрана (1,0),
                    # выравнивание по правому-верхнему углу самого виджета,
                    # отступ 40px сверху и справа.
                    canvas_slot:
                        Anchors := anchors:
                            Minimum := vector2{X := 1.0, Y := 0.0}
                            Maximum := vector2{X := 1.0, Y := 0.0}
                        Alignment := vector2{X := 1.0, Y := 0.0}
                        Offsets := margin{Top := 40.0, Right := 40.0}
                        SizeToContent := true
                        Widget := ScoreText
                    # Кнопка: ровно по центру экрана (anchor 0.5,0.5 + alignment 0.5,0.5).
                    canvas_slot:
                        Anchors := anchors:
                            Minimum := vector2{X := 0.5, Y := 0.5}
                            Maximum := vector2{X := 0.5, Y := 0.5}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := MyButton

            # InputMode.All — чтобы кнопка ловила клики. Для чисто косметического HUD
            # без кнопок ставь ui_input_mode.None, иначе UI «съест» управление.
            PlayerUI.AddWidget(HudCanvas, player_ui_slot{InputMode := ui_input_mode.All})

            # Запоминаем виджет и стартовый счёт.
            if (set ScoreWidgetPerAgent[Player] = ScoreText) {}
            if (set ScorePerAgent[Player] = 0) {}

    OnButtonClicked(Message : widget_message):void=
        # Кто нажал.
        Player := Message.Player
        # Прибавляем счёт и обновляем текст ИМЕННО этому игроку.
        if (CurrentScore := ScorePerAgent[Player]):
            NewScore := CurrentScore + 10
            if (set ScorePerAgent[Player] = NewScore) {}
            if (Widget := ScoreWidgetPerAgent[Player]):
                Widget.SetText(ScoreMessage(NewScore))
            Print("Счёт игрока обновлён: {NewScore}")
