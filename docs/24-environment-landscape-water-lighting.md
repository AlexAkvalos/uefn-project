# 24. Окружение, ландшафт, вода и Lumen-освещение

Создание мира в UEFN: террейн, листва, вода и свет. В основном — **инструменты редактора**
(Verse тут минимален; время суток см. в конце). Актуально на v39.x.

---

## A. Ландшафт / террейн

### Landscape Mode
Режим террейна (дропдаун режимов, рядом с Selection/Foliage/Modeling). Три подрежима:
- **Manage** — создать ландшафт, компоненты, **edit layers**, **сплайны**, импорт/экспорт heightmap.
- **Sculpt** — высота.
- **Paint** — слои материала (трава/камень/грязь).

**Инструменты Sculpt:** **Sculpt** (поднять/опустить, Shift=инверт), **Smooth**, **Flatten**, **Ramp** (рампа между 2 точками),
**Erosion** (термальная), **Hydro Erosion** (водная), **Noise**, **Retopologize** (перераспределить вершины на крутых склонах),
**Visibility** (дырки/пещеры), **Select/Copy-Paste Region**, **Mirror**.
**Настройки кисти:** Brush Size, Falloff, Tool Strength, тип кисти, Clay Brush.

**Размер/компоненты:** ландшафт = сетка **компонентов** (секции в **квадах**). Базлайн: секция **63×63 квада** (64×64 вершины);
макс. секция 256×256; до ~**1024 компонентов** на большой ландшафт.

### Материалы и слои
- **Paint** красит **weight-слои** (Landscape Layer Blend ноды).
- **Edit Layers** — недеструктивное разделение грубой формы и деталей.
- **v39 — переработка weight-blending:** новые методы **None** и **Advanced Weight Blending** (совместим с edit layers),
  концепт **blend group** (блендить подмножество слоёв), опция **Sort by Blend Method**. Лечит «битый блендинг с edit layers».

### Сплайны, heightmap, листва
- **Landscape Splines** (Manage) — дороги/тропы/реки; точки с шириной/falloff, деформируют террейн или ставят spline-меши.
- **Heightmap import/export** в Manage (серый PNG/RAW → высоты).
- **Листва на ландшафте** через Foliage Mode с **Inclusion/Exclusion Landscape Layers** (растёт только на нужном слое).

**Лимиты:** жёсткий **бюджет памяти** (≤ ~99.99/100). Держи секции 63×63, лимит компонентов/слоёв, включи **World Settings → Enable Streaming**.
Мобилки: высокое разрешение + много слоёв — главный риск.

---

## B. Листва и арт окружения

### Foliage Mode
Красит/стирает **Static Mesh / Actor Foliage**. Перетащи меши в **Mesh List**. ⚠️ **Не работает с Fortnite Props**
(их Blueprint-скриптинг, напр. ветер, ломает инстансинг).
**Инструменты:** Paint, Single, Fill, Reapply, Erase, Remove; Select/All/Deselect/Invalid/Lasso/Move.
**Распределение:** Density/1Kuu, Radius (мин. расстояние), Scale X/Y/Z, Z Offset, Align to Normal, Random Yaw/Pitch,
**Ground Slope Angle**, **Height** (диапазон Z), Inclusion/Exclusion Landscape Layers.
**Перф:** Cast Shadow, Cull Distance, Enable Density Scaling/Cull Distance Scaling — для мобилок выключай тени/ставь cull.

> ⚠️ **Процедурная листва в UEFN официально НЕ поддерживается** (Procedural Foliage Spawner UE не выведен).
> Приближай через Fill + density + exclusion-слои.

### Галереи, префабы, Modeling Mode
- Сотни **галерей**/тысячи ассетов; v39 добавил **Pacific Break** (Гл. 7): 30+ галерей, 6 POI, декали/листва/текстуры.
- **Modeling Mode** — лепка кастомных мешей (скалы, утёсы) прямо в редакторе.

---

## C. Вода

Пять инструментов воды (Content Browser → Environment). Кроме бассейна — **авто-поднимают/опускают террейн**:
1. **River** — сплайн, течение, прорезает террейн.
2. **Lake** — вода внутри сплайна.
3. **Ocean** — вода **снаружи** сплайна (обычно один на уровень, волны/течения).
4. **Island** — ставится **внутри** воды, **защищает землю** от прорезания.
5. **Swimming Pool** — свободный прямоугольный объём, **не трогает террейн**.

**Сплайны:** ПКМ по точке — delete/duplicate, тангенсы (кривая/линия), snap/align, визуализация velocity/width/depth.
**v39:** уточнён underwater-детект — пост-обработка под водой больше не включается, когда камера вне коллизии воды.

**Геймплей:** игроки автоматически плавают; глубокая вода → подводная пост-обработка. v39-физика (`fort_character`/`creative_prop`
velocity/impulse) пригодна для buoyancy-механик.
**Лимиты:** у Swimming Pool сплайн-контролы фактически не работают (только translate/rotate/scale); обычно один Ocean; перекрытия лечит Island.

---

## D. Освещение (Lumen)

### Lumen GI и отражения
- **Lumen** — динамическое глобальное освещение + отражения (мягкие тени + Virtual Shadow Maps).
- **Включён по умолчанию**, но активен только при **Global Illumination = High или Epic**. На Low/Medium динамического GI нет (фолбэк — Sky Light).
- **Тиры GI:** Low/Medium (все консоли), **High** (средние/топ консоли), **Epic** (только ПК).
- Software ray tracing по умолчанию; hardware RT — для топ-платформ. Мобилки/Switch — **без Lumen**.

### Устройства и акторы света
- **Day Sequence device** — основная система времени суток/неба (нажми **1** для базовой локации в центре острова).
  Авто-цикл 24ч; настройки look: exposure, saturation, bloom, white balance, vignette, film grain, shadow contrast.
  Несколько Day Sequence + **Trigger Volumes** = свет по биомам.
- **Environment Light Rig device** — для **полностью кастомного** света (когда Time-of-Day менеджеры выключены):
  DirectionalLight (солнце/луна), SkyAtmosphere, SkyLight, ExponentialHeightFog, LumenExposure, BasicExposure, ColorGradient.
- **Акторы:** Directional Light, Sky Light, Sky Atmosphere, Exponential Height Fog, Point/Spot/Rect Light.
  ⚠️ **НЕ свети остров только Point/Spot/Rect** — без Directional+Sky+Atmosphere остров рендерится **чёрным**.
- **Lighting Scalability Manager** — консистентность света по тирам платформ.

### Post Process
- **Post Process device:** Duration, Blend In/Out, Priority; область (игроки/остров/команда); 40+ пресетов (Film Noir, Sepia, Nightvision…).
- **Post Process Volume** (актор): bloom, exposure/auto-exposure, color grading, chromatic aberration, vignette, film grain, DoF, motion blur, white balance.
- **Lumen Exposure Manager device:** два пути экспозиции — **LumenPostProcess** (топ, histogram Auto Exposure, дорого по памяти) и
  **NonLumenPostProcess** (Switch/мобилки, Basic Exposure). Использовать, когда Time-of-Day менеджеры выключены.

### Перф/масштабируемость
- Lumen **полностью динамический** (без запекания в day-cycle workflow). Тестируй на тирах консолей;
  крути **Project Settings → Viewport Scalability → Global Illumination**. Мобилки/Switch — Sky Light + Basic Exposure.

---

## E. Время суток из Verse (с оговоркой)

⚠️ Member-список `day_sequence_device` на справке Epic рендерится через JS — точные сигнатуры **сверяй на live-странице**.
Ожидаемый паттерн (проверь имена!):
```verse
using { /Fortnite.com/Devices }
@editable DaySeq : day_sequence_device = day_sequence_device{}
# CurrentTime := DaySeq.GetTimeOfDay()   # <-- СВЕРИТЬ имя/тип
# DaySeq.SetTimeOfDay(12.0)              # <-- СВЕРИТЬ параметры (часы float?)
```
Для надёжной логики по времени сегодня комбинируют **Day Sequence + Trigger Volumes** или используют
**`real_time_clock_device`** (у него подтверждённый Verse-класс) с событиями sunrise/sunset/noon/midnight.

---

## Best practices (сводка)
- **Бюджет памяти — главное:** Enable Streaming, секции 63×63, лимит компонентов/слоёв/сложности материала.
- **Свет:** всегда Directional + Sky + Atmosphere (Day Sequence или Light Rig); GI = High/Epic для Lumen.
- **Паритет платформ:** Lumen Exposure Manager + Lighting Scalability Manager; тестируй Switch/мобилки (там без Lumen).
- **Вода:** используй **Island** против прорезания; Swimming Pool не меняет форму.
- **Ландшафт v39:** Advanced Weight Blending + edit layers + blend groups.
- **Листва:** для мобилок выключай тени/ставь cull/density scaling; процедурной листвы официально нет.

---

## Источники
- Environments and Landscapes: https://dev.epicgames.com/documentation/en-us/uefn/environments-and-landscapes-in-unreal-editor-for-fortnite
- Landscape Mode: https://dev.epicgames.com/documentation/fortnite/landscape-mode-in-unreal-editor-for-fortnite
- Foliage Mode: https://dev.epicgames.com/documentation/en-us/fortnite/foliage-mode-in-unreal-editor-for-fortnite
- Water Tools: https://dev.epicgames.com/documentation/en-us/fortnite/water-tools-in-unreal-editor-for-fortnite
- Lighting and Lumen Quick Start: https://dev.epicgames.com/documentation/fortnite/lighting-and-lumen-quick-start-guide-in-unreal-editor-for-fortnite
- Lighting in UEFN: https://dev.epicgames.com/documentation/en-us/fortnite/lighting-in-unreal-editor-for-fortnite
- Day Sequence device: https://dev.epicgames.com/documentation/en-us/fortnite/day-sequence-device-in-unreal-editor-for-fortnite
- Lumen Exposure Manager: https://dev.epicgames.com/documentation/en-us/fortnite/using-the-lumen-exposure-manager-in-unreal-editor-for-fortnite
- Post Processing devices: https://dev.epicgames.com/documentation/fortnite/using-post-processing-devices-in-fortnite-creative
- v39.00 release notes: https://dev.epicgames.com/documentation/fortnite/39-00-fortnite-ecosystem-updates-and-release-notes
