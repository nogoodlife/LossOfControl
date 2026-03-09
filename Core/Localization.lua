--[[
 Copyright (c) 2026 s0high
 https://github.com/s0h2x/LossOfControl
    
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
]]

--@class Engine<ns>
local Engine = select(2, ...);

--@natives<lua,wow>
local GetLocale = GetLocale;
local pairs = pairs;
local rawget = rawget;
local setmetatable = setmetatable;
local tostring = tostring;

--@class Localization<core>
local L10N = {};
Engine.Localization = L10N;


-- Locale Index Map
----------------------------------------------------------------
local LOCALE_INDEX = {
	enUS = 1, enGB = 1,
	ruRU = 2,
	deDE = 3,
	frFR = 4,
	esES = 5, esMX = 5,
	itIT = 6,
	ptBR = 7,
	zhCN = 8,
	zhTW = 9,
	koKR = 10,
};


-- Localization Data
-- Index: 1=enUS,  2=ruRU,  3=deDE,  4=frFR,  5=esES,  6=itIT,  7=ptBR,  8=zhCN,  9=zhTW,  10=koKR
----------------------------------------------------------------
local TRANSLATIONS = {
	--                       enUS               ruRU                  deDE                  frFR                esES                itIT                  ptBR                zhCN           zhTW             koKR
	STUN                 = { "Stunned",         "Оглушение",          "Betäubt",            "Étourdissement",   "Aturdido",         "Stordito",           "Atordoado",        "昏迷",        "昏迷",          "기절" },
	FEAR                 = { "Feared",          "Страх",              "Verängstigt",        "Peur",             "Asustado",         "Impaurito",          "Amedrontado",      "恐惧",        "恐懼",          "공포" },
	HORROR               = { "Horrified",       "Ужас",               "Entsetzt",           "Horreur",          "Horrorizado",      "Terrorizzato",       "Horrorizado",      "惊骇",        "受驚",          "두려움" },
	ROOT                 = { "Rooted",          "Обездвиженность",    "Bewegungsunfähig",   "Immobilisation",   "Enraizado",        "Immobilizzato",      "Enraizado",        "被定身",      "定身",          "이동 불가" },
	SILENCE              = { "Silenced",        "Немота",             "Stille",             "Silence",          "Silenciado",       "Silenziato",         "Silenciado",       "沉默",        "沉默",          "침묵" },
	DISARM               = { "Disarmed",        "Без оружия",         "Entwaffnet",         "Désarmement",      "Desarmado",        "Disarmato",          "Desarmado",        "缴械",        "繳械",          "무장 해제" },
	POLYMORPH            = { "Polymorphed",     "Превращение",        "Verwandelt",         "Métamorphose",     "Polimorfado",      "Metamorfato",        "Polimorfado",      "变形",        "變形",          "변이" },
	FREEZE               = { "Frozen",          "Заморозка",          "Eingefroren",        "Gel",              "Congelado",        "Congelato",          "Congelado",        "被冻结",      "冰凍",          "빙결" },
	CYCLONE              = { "Cycloned",        "Смерч",              "Außer Gefecht",      "Cyclone",          "Ciclón",           "Ciclonato",          "Ventaneado",       "旋风",        "陷入颶風術",    "회오리바람" },
	BANISH               = { "Banished",        "Изгнание",           "Verbannt",           "Bannissement",     "Desterrado",       "Esiliato",           "Banido",           "放逐",        "放逐",          "추방" },
	CHARM                = { "Charmed",         "Подчинение",         "Betört",             "Charme",           "Embelesado",       "Ammaliato",          "Enfeitiçado",      "魅惑",        "魅惑",          "현혹" },
	CONFUSE              = { "Confused",        "Растерянность",      "Verwirrt",           "Confusion",        "Confundido",       "Confuso",            "Confuso",          "迷惑",        "困惑",          "혼란" },
	DISORIENT            = { "Disoriented",     "Дезориентация",      "Desorientiert",      "Désorientation",   "Desorientado",     "Disorientato",       "Desnorteado",      "迷惑",        "困惑",          "방향 감각 상실" },
	INCAP                = { "Incapacitated",   "Паралич",            "Handlungsunfähig",   "Stupéfaction",     "Incapacitado",     "Inabilitato",        "Incapacitado",     "瘫痪",        "癱瘓",          "행동 불가" },
	SAP                  = { "Sapped",          "Ошеломление",        "Ausgeschaltet",      "Assommement",      "Aporreado",        "Tramortito",         "Aturdido",         "被闷棍",      "中了悶棍",      "혼절" },
	SLEEP                = { "Asleep",          "Сон",                "In Schlaf versetzt", "Sommeil",          "Dormido",          "Addormentato",       "Dormindo",         "沉睡",        "沉睡",          "수면" },
	SNARE                = { "Snared",          "Замедление",         "Verlangsamt",        "Piège",            "Frenado",          "Rallentato",         "Lerdo",            "诱捕",        "緩速",          "감속" },
	DAZE                 = { "Dazed",           "Головокружение",     "Benommen",           "Hébétement",       "Atontado",         "Frastornato",        "Estonteado",       "眩晕",        "暈眩",          "멍해짐" },
	SHACKLE              = { "Shackled",        "Оковы",              "Gefesselt",          "Entraves",         "Encadenado",       "Incatenato",         "Agrilhoado",       "束缚",        "禁錮",          "속박" },
	POSSESS              = { "Possessed",       "Одержимость",        "Besessen",           "Possédé",          "Poseído",          "Posseduto",          "Possuído",         "被占据",      "附身",          "빙의" },
	PACIFY               = { "Pacified",        "Усмирение",          "Befriedet",          "Pacification",     "Pacificado",       "Pacificato",         "Pacificado",       "平静",        "平靜",          "평정" },
	DISTRACT             = { "Distracted",      "Отвлечение",         "Abgelenkt",          "Distraction",      "Distraído",        "Distratto",          "Distraído",        "被吸引",      "分心",          "견제" },
	TAUNT                = { "Taunted",         "Провокация",         "Verspottet",         "Raillé",           "Provocado",        "Provocato",          "Provocado",        "被嘲讽",      "被嘲諷",        "도발당함" },
	INVULNERABILITY      = { "Invulnerable",    "Неуязвимость",       "Unverwundbar",       "Invulnérabilité",  "Invulnerable",     "Invulnerabile",      "Invulnerável",     "无敌",        "免傷",          "무적" },
	-- Interrupt
	SCHOOL_INTERRUPT     = { "Interrupted",     "Прерывание",         "Unterbrochen",       "Interruption",     "Interrumpido",     "Interrotto",         "Interrompido",     "打断",        "中斷",          "차단" },
	INTERRUPT_FMT        = { "%s Locked",       "%s: недоступно",     "%s gesperrt",        "%s verrouillé",    "Bloqueo: %s",      "%s bloccati",        "%s Bloqueado",     "%s被锁定",    "禁用%s法術",     "%s 차단됨" },
	-- Misc
	SECONDS              = { "seconds",         "сек.",               "Sek.",               "secondes",         "segundos",         "secondi",            "segundos",         "秒",          "秒",            "초" },
	-- Options/UI
	ADDON_TITLE          = { "Loss of Control", "Потеря контроля",    "Kontrollverlust",    "Perte de contrôle","Pérdida control",  "Perdita controllo",  "Perda de controle"," 失控警报",   "喪失控制",       "제어 불가" },

	-- Options: Sections
	OPT_GENERAL          = { "General",          "Основные",           "Allgemein",          "Général",          "General",          "Generale",           "Geral",            "常规",        "一般",           "일반" },
	OPT_VISUAL           = { "Visual",           "Визуальные",         "Visuell",            "Visuel",           "Visual",           "Visuale",            "Visual",           "视觉",        "視覺",           "시각" },
	OPT_CC_DISPLAY       = { "CC Type Display",  "Типы контроля",      "CC-Typen",           "Types de CC",      "Tipos de CC",      "Tipi di CC",         "Tipos de CC",      "CC类型",      "CC類型",         "CC 유형" },
	OPT_CUSTOM_AURAS     = { "Custom Auras",     "Свои ауры",          "Eigene Auren",       "Auras perso.",     "Auras custom",     "Aure custom",        "Auras custom",     "自定义",      "自訂",           "사용자 정의" },
	OPT_ADVANCED         = { "Advanced",         "Дополнительно",      "Erweitert",          "Avancé",           "Avanzado",         "Avanzate",           "Avançado",         "高级",        "進階",           "고급" },
	-- Options: Settings
	OPT_ENABLED          = { "Enabled",          "Включено",           "Aktiviert",          "Activé",           "Habilitado",       "Abilitato",          "Habilitado",       "启用",        "啟用",           "활성화" },
	OPT_SOUND            = { "Sound",            "Звук",               "Ton",                "Son",              "Sonido",           "Suono",              "Som",              "声音",        "聲音",           "소리" },
	OPT_MOVE_FRAME       = { "Move frame",       "Переместить",        "Bewegen",            "Déplacer",         "Mover marco",      "Sposta",             "Mover quadro",     "移动框体",    "移動框架",       "프레임 이동" },
	OPT_RESET_POS        = { "Reset position",   "Сбросить",           "Zurücksetzen",       "Réinitialiser",    "Restablecer",      "Reimposta",          "Redefinir",        "重置位置",    "重置位置",       "위치 초기화" },
	OPT_FRAME_SCALE      = { "Frame scale",      "Масштаб",            "Skalierung",         "Échelle",          "Escala",           "Scala",              "Escala",           "缩放",        "縮放",           "크기" },
	OPT_BACKGROUND       = { "Background",       "Фон",                "Hintergrund",        "Arrière-plan",     "Fondo",            "Sfondo",             "Fundo",            "背景",        "背景",           "배경" },
	OPT_RED_LINES        = { "Red lines",        "Красные линии",      "Rote Linien",        "Lignes rouges",    "Líneas rojas",     "Linee rosse",        "Linhas vermelhas", "红线",        "紅線",           "빨간 선" },
	OPT_ANIMATIONS       = { "Animations",       "Анимации",           "Animationen",        "Animations",       "Animaciones",      "Animazioni",         "Animações",        "动画",        "動畫",           "애니메이션" },
	OPT_PULSE            = { "Pulse",            "Пульсация",          "Pulsieren",          "Pulsation",        "Pulso",            "Impulso",            "Pulsar",           "脉冲",        "脈衝",           "펄스" },
	OPT_DYNAMIC_TEXT     = { "Dynamic text",     "Динамический текст", "Dynamischer Text",   "Texte dynamique",  "Texto dinámico",   "Testo dinamico",     "Texto dinâmico",   "动态文本",    "動態文字",       "동적 텍스트" },
	OPT_TIMER_DECIMAL    = { "Decimal timer",    "Дробный таймер",     "Dezimaltimer",       "Timer décimal",    "Timer fraccional", "Timer decimale",     "Timer fracionário","小数计时",    "小數計時",       "소수 타이머" },
	OPT_LOG_UNKNOWN      = { "Log unknown",      "Информировать неизвестные","Unbekannte loggen","Journal inconnus","Log desconocidos", "Log sconosciuti",    "Log desconhecidos","记录未知",    "記錄未知",       "알 수 없는 기록" },
	OPT_AURA_MANAGER     = { "Aura Manager",     "Управление аурами",       "Auren verwalten",    "Gérer auras",      "Gestionar auras",  "Gestisci aure",      "Gerenciar auras",  "管理自定义",  "管理自訂",       "관리" },
	OPT_PRIORITY         = { "Priority",         "Приоритет",          "Priorität",          "Priorité",         "Prioridad",        "Priorità",           "Prioridade",       "优先级",      "優先級",         "우선순위" },
	-- Options: Custom Auras
	OPT_SPELL_ID         = { "Spell ID:",        "ID заклинания:",     "Zauber-ID:",         "ID sort:",         "ID hechizo:",      "ID incantesimo:",    "ID feitiço:",      "法术ID：",     "法術ID：",       "주문 ID:" },
	OPT_TYPE             = { "Type:",            "Тип:",               "Typ:",               "Type:",            "Tipo:",            "Tipo:",              "Tipo:",            "类型：",        "類型：",         "유형:" },
	OPT_ADD_AURA         = { "Add Aura",         "Добавить",           "Hinzufügen",         "Ajouter",          "Añadir",           "Aggiungi",           "Adicionar",        "添加",         "新增",           "추가" },
	OPT_REMOVE           = { "Remove",           "Удалить",            "Entfernen",          "Retirer",          "Quitar",           "Rimuovi",            "Remover",          "移除",         "移除",           "제거" },
	OPT_CLEAR_ALL        = { "Clear All",        "Очистить всё",       "Alle löschen",       "Tout effacer",     "Borrar todo",      "Cancella tutto",     "Limpar tudo",      "全部清除",     "全部清除",       "전체 삭제" },
	OPT_CLEAR_AURAS      = { "Clear Auras",      "Очистить ауры",      "Auren löschen",      "Effacer auras",    "Borrar auras",     "Cancella aure",      "Limpar auras",     "清除光环",     "清除光環",       "오라 삭제" },
	OPT_CURRENT_AURAS    = { "Current Auras:",   "Текущие ауры:",      "Aktuelle Auren:",    "Auras actuelles:", "Auras actuales:",  "Aure attuali:",      "Auras atuais:",    "当前自定义：",  "目前自訂：",     "현재 목록:" },
	OPT_UNKNOWN          = { "Unknown",          "Неизвестно",         "Unbekannt",          "Inconnu",          "Desconocido",      "Sconosciuto",        "Desconhecido",     "未知",         "未知",          "알 수 없음" },
	OPT_ALREADY_IN_CC    = { "Already in built-in CC list", "Уже в списке CC", "Bereits in CC-Liste", "Déjà dans la liste CC", "Ya en lista CC", "Già in lista CC", "Já na lista CC", "已在CC列表中", "已在CC列表中", "기본 CC 목록에 있음" },
	OPT_ALREADY_IN_INTERRUPT = { "Already in built-in interrupt list", "Уже в списке прерываний", "Bereits in Unterbrechungsliste", "Déjà dans la liste interruptions", "Ya en lista interrupciones", "Già in lista interruzioni", "Já na lista interrupções", "已在打断列表中", "已在打斷列表中", "기본 차단 목록에 있음" },
	-- Options: Custom Interrupts
	OPT_CUSTOM_INTERRUPTS = { "Custom Interrupts", "Свои прерывания", "Eigene Unterbrechungen", "Interruptions perso.", "Interrupciones custom", "Interruzioni custom", "Interrupções custom", "自定义打断", "自訂打斷", "사용자 정의 차단" },
	OPT_DURATION         = { "Duration (sec):",   "Длительность (сек):", "Dauer (Sek):",       "Durée (sec):",      "Duración (seg):",   "Durata (sec):",      "Duração (seg):",   "持续时间(秒)：", "持續時間(秒)：", "지속 시간(초):" },
	OPT_ADD_INTERRUPT    = { "Add Interrupt",    "Добавить",           "Hinzufügen",         "Ajouter",           "Añadir",           "Aggiungi",           "Adicionar",        "添加打断",  "新增打斷",       "차단 추가" },
	OPT_CURRENT_INTERRUPTS = { "Current interrupts:", "Текущие прерывания:", "Aktuelle Unterbrechungen:", "Interruptions actuelles:", "Interrupciones actuales:", "Interruzioni attuali:", "Interrupções atuais:", "当前自定义打断：", "目前自訂打斷：", "현재 목록:" },
	OPT_NO_CUSTOM_INTERRUPTS = { "No custom interrupts defined.", "Нет своих прерываний.", "Keine Unterbrechungen.", "Aucune interruption.", "Sin interrupciones.", "Nessuna interruzione.", "Nenhuma interrupção.", "未定义打断。", "未定義打斷。", "정의된 차단 없음." },
	OPT_CLEAR_INTERRUPTS  = { "Clear Interrupts", "Очистить прерывания", "Interrupts löschen", "Effacer interruptions", "Borrar interrupciones", "Cancella interruzioni", "Limpar interrupções", "清除打断", "清除打斷", "차단 삭제" },
	-- Options: Display modes
	OPT_DISPLAY_OFF          = { "Off",              "Выкл",               "Aus",                "Désactivé",        "Desactivado",      "Disattivato",        "Desligado",        "关闭",        "關閉",           "끔" },
	OPT_DISPLAY_ALERT        = { "Alert only",       "Только оповещение",  "Nur Warnung",        "Alerte seule",     "Solo alerta",      "Solo avviso",        "Apenas alerta",    "仅提醒",      "僅提醒",         "알림만" },
	OPT_DISPLAY_FULL         = { "Full display",     "Полное отображение", "Vollständig",        "Affichage complet","Completo",         "Completo",           "Completo",         "完整显示",    "完整顯示",       "전체 표시" },

	-- Options: Desc
	OPT_CC_DESC = {
		"Display mode and priority for each CC type.",
		"Режим отображения и приоритет для каждого типа контроля.",
		"Anzeigemodus und Priorität für jeden CC-Typ.",
		"Mode et priorité par type de CC.",
		"Modo y prioridad por tipo de CC.",
		"Modalità e priorità per tipo di CC.",
		"Modo e prioridade por tipo de CC.",
		"每种CC类型的显示模式和优先级。",
		"每種CC類型的顯示模式和優先級。",
		"CC 유형별 표시 모드 및 우선순위."
	},
	OPT_NO_CUSTOM_AURAS  = {
		"No custom auras defined.\nUse the form above to add.",
		"Нет своих аур.\nИспользуйте форму выше.",
		"Keine Auren definiert.\nFormular oben nutzen.",
		"Aucune aura.\nUtilisez le formulaire ci-dessus.",
		"Sin auras.\nUse el formulario de arriba.",
		"Nessuna aura.\nUsa il modulo sopra.",
		"Nenhuma aura.\nUse o formulário acima.",
		"未定义自定义。\n使用上方表单添加。",
		"未定義自訂。\n使用上方表單新增。",
		"정의된 aura 없음.\n위 양식을 사용하세요."
	},

	OPT_CUSTOM_AURAS_DESC = {
		"Add custom CC spells to track. Use the button below or /loc auras.",
		"Добавьте свои заклинания для отслеживания. Кнопка ниже или /loc auras.",
		"Eigene CC-Zauber hinzufügen. Button unten oder /loc auras.",
		"Ajoutez des sorts CC personnalisés. Bouton ci-dessous ou /loc auras.",
		"Añade hechizos CC personalizados. Botón abajo o /loc auras.",
		"Aggiungi incantesimi CC personalizzati. Pulsante sotto o /loc auras.",
		"Adicione feitiços CC personalizados. Botão abaixo ou /loc auras.",
		"添加自定义CC法术。使用下方按钮或 /loc auras。",
		"新增自訂CC法術。使用下方按鈕或 /loc auras。",
		"추적할 맞춤 CC 주문 추가. 아래 버튼 또는 /loc auras."
	},
	-- Options: Tooltips
	OPT_DYNAMIC_TEXT_TIP  = { "Position 'seconds' next to the number. When off, use fixed offset.", "Располагать «сек.» рядом с числом. Выкл — фиксированный отступ.", "Positioniere 'Sek.' neben der Zahl. Aus: fester Abstand.", "Positionner 'secondes' à côté du nombre. Désactivé: décalage fixe.", "Posicionar 'segundos' junto al número. Desactivado: desplazamiento fijo.", "Posiziona 'secondi' accanto al numero. Disattivato: offset fisso.", "Posicionar 'segundos' ao lado do número. Desativado: deslocamento fixo.", "将“秒”放在数字旁边。关闭：固定偏移。", "將「秒」放在數字旁邊。關閉：固定偏移。", "숫자 옆에 '초' 배치. 끄면 고정 오프셋." },
	OPT_TIMER_DECIMAL_TIP = { "Show decimal (e.g. 9.5) for remaining time under 10 seconds.", "Показывать дробную часть (напр. 9.5) для оставшегося времени менее 10 сек.", "Dezimalstelle (z.B. 9,5) für Restzeit unter 10 Sek. anzeigen.", "Afficher les décimales (ex. 9,5) pour le temps restant sous 10 s.", "Mostrar decimales (ej. 9,5) para tiempo restante bajo 10 s.", "Mostra decimali (es. 9,5) per tempo rimanente sotto 10 sec.", "Mostrar decimais (ex. 9,5) para tempo restante abaixo de 10 s.", "剩余时间少于10秒时显示小数（如9.5）。", "剩餘時間少於10秒時顯示小數（如9.5）。", "10초 미만 남은 시간에 소수점 표시(예: 9.5)." },
};


local fallbackMT = { __index = function(_, key)
		return tostring(key);
	end
};

function L10N:Init()
	local clientLocale = GetLocale();
	local index = LOCALE_INDEX[clientLocale] or 1;

	local L = {};
	for key, values in pairs(TRANSLATIONS) do
		L[key] = values[index] or values[1] or key;
	end

	Engine.Locale = setmetatable(L, fallbackMT);

	TRANSLATIONS = nil;
	LOCALE_INDEX = nil;

	Engine.DebugLog("Localization: %s (index %d)", clientLocale, index);
end

-- L10N:Init();

-- API
----------------------------------------------------------------
-- function L10N:HasKey(key)
	-- return rawget(Engine.Locale, key) ~= nil;
-- end

-- function L10N:Extend(translations)
	-- local L = Engine.Locale;
	-- if not L then return end
	
	-- for key, value in pairs(translations) do
		-- if rawget(L, key) == nil then
			-- L[key] = value
		-- end
	-- end
-- end