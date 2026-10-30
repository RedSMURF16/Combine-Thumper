/*
*
*	Combine Thumper by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /thumper                "Opens the Thumper menu."
*       say_team /thumper           "Opens the Thumper menu."
*       combinethumper_reload       "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                         32
#define ADMIN_ACCESS                    ADMIN_RCON
#define PDATA_NEXT_ATTACK               83
#define XO_CBASEPLAYER                  5
#define XO_CBASEPLAYERWEAPON            4
#define THUMPER_CHECK                   10.0
#define THUMPER_OFFSET_BASE             120.0
#define THUMPER_OFFSET_MIN              65.0
#define THUMPER_OFFSET_MAX              900.0
#define THUMPER_OFFSET_STEP             10.0
#define THUMPER_GHOST_ALPHA             120
#define THUMPER_ROTATION_STEP           22.5
#define THUMPER_KEY                     756612
#define THUMPER_TASK_THUMP              191817
#define THUMPER_ARRAY_ITEM              pev_iuser1
#define THUMP_DURATION                  2.833
#define TOP_DURATION                    2.333
#define SOUND_NAV                       "buttons/blip1.wav"
#define SOUND_REMOVE                    "buttons/button10.wav"
#define SOUND_ALERT                     "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "CombineThumper_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_THUMPER
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_ARRAY_MESSAGE,
    DTYPE_ARRAY_MODEL,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL_ID,
    DTYPE_ARRAY_MODEL_ID
}

enum
{
    FLAG_SHAKE              = (1 << 0),
    FLAG_DAMAGE             = (1 << 1),
    FLAG_PUSH               = (1 << 2),

    FLAG_SHOW               = (1 << 3),
    FLAG_GHOST              = (1 << 4),
    FLAG_GROUND             = (1 << 5),
    FLAG_ACTIVE             = (1 << 6)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum
{
    SIZE_NORMAL,
    SIZE_SMALL
}

enum _:MAIN_SETTINGS
{
    SETTING_MODEL_NORMAL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_SMALL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_AMB[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_ON[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_OFF[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_HIT[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_DUST[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_TOP[MAX_RESOURCE_PATH_LENGTH],
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    SETTING_DEFAULT_USE_TEAM,
    Float:SETTING_DEFAULT_FRAMERATE,
    Float:SETTING_DEFAULT_DAMAGE[2],
    SETTING_DEFAULT_DAMAGETYPE,
    Float:SETTING_DEFAULT_PUSH_FORWARD[2],
    Float:SETTING_DEFAULT_PUSH_UP[2],
    Float:SETTING_DEFAULT_RANGE_SHAKE[2],
    Float:SETTING_DEFAULT_RANGE_IMPACT[2],
    SETTING_DEFAULT_SHAKE_AMPLITUDE[2],
    SETTING_DEFAULT_SHAKE_FREQUENCY[2],
    SETTING_DEFAULT_SHAKE_DURATION[2],
    Float:SETTING_FACTOR_DAMAGE,
    Float:SETTING_FACTOR_PUSH,
    bool:SETTING_THE_CLOSER_THE_BIGGER,
    Float:SETTING_USE_COOLDOWN,

    Float:SETTING_MINS_NORMAL[3],
    Float:SETTING_MAXS_NORMAL[3],
    Float:SETTING_MINS_SMALL[3],
    Float:SETTING_MAXS_SMALL[3],
    bool:SETTING_THUMPER_LOAD,
    Float:SETTING_OFFSET_BASE
}

enum _:THUMPER
{
    THUMPER_ID,
    THUMPER_ITEM,
    THUMPER_FLAGS,
    THUMPER_TEAM,
    THUMPER_USE_TEAM,
    Float:THUMPER_FRAMERATE,
    Float:THUMPER_DAMAGE[2],
    THUMPER_DAMAGETYPE,
    Float:THUMPER_PUSH_FORWARD[2],
    Float:THUMPER_PUSH_UP[2],
    THUMPER_SIZE,
    Float:THUMPER_RANGE_SHAKE,
    Float:THUMPER_RANGE_IMPACT,
    THUMPER_SHAKE_AMPLITUDE,
    THUMPER_SHAKE_FREQUENCY,
    THUMPER_SHAKE_DURATION,
    THUMPER_NAME[MAX_VALUE_LENGTH],
    THUMPER_MODEL[MAX_RESOURCE_PATH_LENGTH],

    Float:THUMPER_ORIGIN[3],
    Float:THUMPER_ANGLES[3],
    Float:THUMPER_MINS[3],
    Float:THUMPER_MAXS[3],

    Float:THUMPER_NEXT_USE
}

enum _:PLAYER_DATA
{
    PDATA_THUMPER_GHOST,
    PDATA_THUMPER_MENU,
    bool:PDATA_THUMPER_ACTION,
    PDATA_THUMPER_ID,
    PDATA_ROTATE_SIZE,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_SIZE,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate"
}

new g_szCN[] = "combinethumper"

new Array:g_aThumper,
    Array:g_aThumperConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdUse, HamHook:g_iFwdObjectCaps, HamHook:g_iFwdPreThink,
    g_iThumper, g_iThumperConfig, g_iScreenShake,
    g_iMaxPlayers

new const g_iColorActive[] = { 0, 255, 0 }
new const g_iColorInactive[] = { 255, 0, 0 }
new g_szRotateSize[][] = {"THUMPER_ROTATE_NORMAL", "THUMPER_ROTATE_SMALL"}

public plugin_init()
{
    register_plugin("Combine Thumper", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_CombineThumper", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /thumper",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Thumper menu.")
    register_clcmd("say_team /thumper",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Thumper menu.")
    register_concmd("combinethumper_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("CombineThumper.txt")

    g_iFwdUse = RegisterHam(Ham_Use, "info_target", "fwdUse")
    g_iFwdObjectCaps = RegisterHam(Ham_ObjectCaps, "info_target", "fwdObjectCaps")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iScreenShake = get_user_msgid("ScreenShake")
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableThumper()

    thumperInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aThumper = ArrayCreate(THUMPER)
    g_aThumperConfig = ArrayCreate(THUMPER)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aThumper)
    ArrayDestroy(g_aThumperConfig)
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    thumperSound(id, SOUND_MENU_NAV)
    thumperMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    thumperReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        ArrayClear(g_aThumperConfig)
        g_iThumperConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/CombineThumper.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eThumper[THUMPER], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iThumperConfig )
                            ArrayPushArray(g_aThumperConfig, eThumper)

                        copy(eThumper[THUMPER_NAME], charsmax(eThumper[THUMPER_NAME]), szData)
                        eThumper[THUMPER_FLAGS]                     = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eThumper[THUMPER_TEAM]                      = g_eSettings[SETTING_DEFAULT_TEAM]
                        eThumper[THUMPER_USE_TEAM]                  = g_eSettings[SETTING_DEFAULT_USE_TEAM]
                        eThumper[THUMPER_FRAMERATE]                 = g_eSettings[SETTING_DEFAULT_FRAMERATE]
                        eThumper[THUMPER_DAMAGE][0]                 = g_eSettings[SETTING_DEFAULT_DAMAGE][0]
                        eThumper[THUMPER_DAMAGE][1]                 = g_eSettings[SETTING_DEFAULT_DAMAGE][1]
                        eThumper[THUMPER_DAMAGETYPE]                = g_eSettings[SETTING_DEFAULT_DAMAGETYPE]
                        eThumper[THUMPER_PUSH_FORWARD][0]           = g_eSettings[SETTING_DEFAULT_PUSH_FORWARD][0]
                        eThumper[THUMPER_PUSH_FORWARD][1]           = g_eSettings[SETTING_DEFAULT_PUSH_FORWARD][1]
                        eThumper[THUMPER_PUSH_UP][0]                = g_eSettings[SETTING_DEFAULT_PUSH_UP][0]
                        eThumper[THUMPER_PUSH_UP][1]                = g_eSettings[SETTING_DEFAULT_PUSH_UP][1]

                        iSection = SECTION_THUMPER
                        g_iThumperConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_MODEL_NORMAL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_NORMAL], charsmax(g_eSettings[SETTING_MODEL_NORMAL]))
                        else if ( equali(szKey, "SETTING_MODEL_SMALL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_SMALL], charsmax(g_eSettings[SETTING_MODEL_SMALL]))
                        else if ( equali(szKey, "SETTING_SOUND_AMB") )
                            parseSetting(DTYPE_STRING_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_SOUND_AMB], charsmax(g_eSettings[SETTING_SOUND_AMB]))
                        else if ( equali(szKey, "SETTING_SOUND_ON") )
                            parseSetting(DTYPE_STRING_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_SOUND_ON], charsmax(g_eSettings[SETTING_SOUND_ON]))
                        else if ( equali(szKey, "SETTING_SOUND_OFF") )
                            parseSetting(DTYPE_STRING_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_SOUND_OFF], charsmax(g_eSettings[SETTING_SOUND_OFF]))
                        else if ( equali(szKey, "SETTING_SOUND_HIT") )
                            parseSetting(DTYPE_STRING_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_SOUND_HIT], charsmax(g_eSettings[SETTING_SOUND_HIT]))
                        else if ( equali(szKey, "SETTING_SOUND_DUST") )
                            parseSetting(DTYPE_STRING_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_SOUND_DUST], charsmax(g_eSettings[SETTING_SOUND_DUST]))
                        else if ( equali(szKey, "SETTING_SOUND_TOP") )
                            parseSetting(DTYPE_STRING_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_SOUND_TOP], charsmax(g_eSettings[SETTING_SOUND_TOP]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_USE_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_USE_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_USE_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGETYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGETYPE], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGETYPE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_PUSH_FORWARD") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_PUSH_FORWARD], charsmax(g_eSettings[SETTING_DEFAULT_PUSH_FORWARD]))
                        else if ( equali(szKey, "SETTING_DEFAULT_PUSH_UP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_PUSH_UP], charsmax(g_eSettings[SETTING_DEFAULT_PUSH_UP]))
                        else if ( equali(szKey, "SETTING_DEFAULT_RANGE_SHAKE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_RANGE_SHAKE], charsmax(g_eSettings[SETTING_DEFAULT_RANGE_SHAKE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_RANGE_IMPACT") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_RANGE_IMPACT], charsmax(g_eSettings[SETTING_DEFAULT_RANGE_IMPACT]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_AMPLITUDE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_FREQUENCY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DURATION]))
                        else if ( equali(szKey, "SETTING_FACTOR_DAMAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_FACTOR_DAMAGE], charsmax(g_eSettings[SETTING_FACTOR_DAMAGE]))
                        else if ( equali(szKey, "SETTING_FACTOR_PUSH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_FACTOR_PUSH], charsmax(g_eSettings[SETTING_FACTOR_PUSH]))
                        else if ( equali(szKey, "SETTING_THE_CLOSER_THE_BIGGER") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_THE_CLOSER_THE_BIGGER], charsmax(g_eSettings[SETTING_THE_CLOSER_THE_BIGGER]))
                        else if ( equali(szKey, "SETTING_USE_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_USE_COOLDOWN], charsmax(g_eSettings[SETTING_USE_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_MINS_NORMAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_NORMAL], charsmax(g_eSettings[SETTING_MINS_NORMAL]))
                        else if ( equali(szKey, "SETTING_MAXS_NORMAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_NORMAL], charsmax(g_eSettings[SETTING_MAXS_NORMAL]))
                        else if ( equali(szKey, "SETTING_MINS_SMALL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_SMALL], charsmax(g_eSettings[SETTING_MINS_SMALL]))
                        else if ( equali(szKey, "SETTING_MAXS_SMALL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_SMALL], charsmax(g_eSettings[SETTING_MAXS_SMALL]))
                        else if ( equali(szKey, "SETTING_THUMPER_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_THUMPER_LOAD], charsmax(g_eSettings[SETTING_THUMPER_LOAD]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                    }
                    case SECTION_THUMPER:
                    {
                        if ( equali(szKey, "THUMPER_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eThumper[THUMPER_FLAGS], charsmax(eThumper[THUMPER_FLAGS]))
                        else if ( equali(szKey, "THUMPER_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eThumper[THUMPER_TEAM], charsmax(eThumper[THUMPER_TEAM]))
                        else if ( equali(szKey, "THUMPER_USE_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eThumper[THUMPER_USE_TEAM], charsmax(eThumper[THUMPER_USE_TEAM]))
                        else if ( equali(szKey, "THUMPER_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThumper[THUMPER_FRAMERATE], charsmax(eThumper[THUMPER_FRAMERATE]))
                        else if ( equali(szKey, "THUMPER_DAMAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThumper[THUMPER_DAMAGE], charsmax(eThumper[THUMPER_DAMAGE]))
                        else if ( equali(szKey, "THUMPER_DAMAGETYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eThumper[THUMPER_DAMAGETYPE], charsmax(eThumper[THUMPER_DAMAGETYPE]))
                        else if ( equali(szKey, "THUMPER_PUSH_FORWARD") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThumper[THUMPER_PUSH_FORWARD], charsmax(eThumper[THUMPER_PUSH_FORWARD]))
                        else if ( equali(szKey, "THUMPER_PUSH_UP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThumper[THUMPER_PUSH_UP], charsmax(eThumper[THUMPER_PUSH_UP]))
                    }
                }
            }
        }
    }

    if ( g_iThumperConfig )
        ArrayPushArray(g_aThumperConfig, eThumper)
    else
        set_fail_state("No thumpers were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_disconnected(id)
{
    new eThumper[THUMPER], iItem
    if ( g_ePlayerData[id][PDATA_THUMPER_GHOST]
    && (iItem = thumperGet(eThumper, g_ePlayerData[id][PDATA_THUMPER_GHOST])) != -1 )
    {
        thumperKill(eThumper[THUMPER_ID])
        thumperRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_THUMPER_GHOST] = 0
    g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
}

stock thumperInit()
{
    if ( g_eSettings[SETTING_THUMPER_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock thumperMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "THUMPER_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "THUMPER_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "THUMPER_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "THUMPER_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "THUMPER_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "THUMPER_ROOT_STATUS"); }
        case MENU_ROTATE:           { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "THUMPER_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "THUMPER_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROOT_NOCLIP", id, get_user_noclip(id) ? "THUMPER_ON" : "THUMPER_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROOT_GODMODE", id, get_user_godmode(id) ? "THUMPER_ON" : "THUMPER_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iThumper >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_LIMIT", MAX_ENT)

                thumperSound(id, SOUND_MENU_REMOVE)
                thumperMenu(id, MENU_ROOT)
            }
            else
            {
                thumperSound(id, SOUND_MENU_NAV)
                thumperMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iThumper )
            {
                client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_NO_THUMPER")

                thumperSound(id, SOUND_MENU_REMOVE)
                thumperMenu(id, MENU_ROOT)
            }
            else
            {
                thumperSound(id, SOUND_MENU_NAV)
                thumperMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iThumper )
            {
                client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_NO_THUMPER")

                thumperSound(id, SOUND_MENU_REMOVE)
                thumperMenu(id, MENU_ROOT)
            }
            else
            {
                thumperSound(id, SOUND_MENU_REMOVE)
                thumperMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            thumperNoClip(id)
        }
        case ROOT_GODMODE:
        {
            thumperGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eThumper[THUMPER], szItem[64]
    for ( new i = 0; i < g_iThumperConfig; i ++ )
    {
        ArrayGetArray(g_aThumperConfig, i, eThumper)

        copy(szItem, charsmax(szItem), eThumper[THUMPER_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        thumperSound(id, SOUND_MENU_NAV)
        thumperMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    thumperCreate(id, item)
    thumperSound(id, SOUND_MENU_NAV)
    thumperMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eThumper[THUMPER]
    menuNav(id, iMenu)
    ArrayGetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_REMOVE_CURRENT", eThumper[THUMPER_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    thumperSelect(eThumper, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)
}

public menuHandlerRemove(id, menu, item)
{
    new eThumper[THUMPER]
    ArrayGetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        thumperSelect(eThumper, eThumper[THUMPER_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_THUMPER_MENU] >= g_iThumper - 1 )
                g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_THUMPER_MENU] ++

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_THUMPER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_THUMPER_MENU] = g_iThumper - 1
            else
                g_ePlayerData[id][PDATA_THUMPER_MENU] --

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eThumper[THUMPER_FLAGS] &= ~FLAG_ACTIVE
            thumperSetState(eThumper, false)
            thumperKill(eThumper[THUMPER_ID])
            thumperRemove(g_ePlayerData[id][PDATA_THUMPER_MENU])

            client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_REMOVE_CURRENT", eThumper[THUMPER_NAME])
            g_ePlayerData[id][PDATA_THUMPER_MENU] = 0

            thumperSound(id, g_iThumper > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            thumperMenu(id, g_iThumper > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iThumper )
            {
                ArrayGetArray(g_aThumper, 0, eThumper)
                eThumper[THUMPER_FLAGS] &= ~FLAG_ACTIVE

                thumperSetState(eThumper, false)
                thumperKill(eThumper[THUMPER_ID])
                thumperRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_THUMPER_MENU] = 0

            thumperSound(id, SOUND_MENU_ALERT)
            thumperMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                thumperSound(id, SOUND_MENU_NAV)
                thumperMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eThumper[THUMPER]
    menuNav(id, iMenu)
    ArrayGetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_SHOW_CURRENT",
    eThumper[THUMPER_FLAGS] & FLAG_SHOW ? "\y" : "\r", eThumper[THUMPER_NAME], id, eThumper[THUMPER_FLAGS] & FLAG_SHOW ? "THUMPER_SHOWN" : "THUMPER_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    thumperSelect(eThumper, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)
}

public menuHandlerShow(id, menu, item)
{
    new eThumper[THUMPER]
    ArrayGetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        thumperSelect(eThumper, eThumper[THUMPER_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_THUMPER_MENU] >= g_iThumper - 1 )
                g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_THUMPER_MENU] ++

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_THUMPER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_THUMPER_MENU] = g_iThumper - 1
            else
                g_ePlayerData[id][PDATA_THUMPER_MENU] --

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eThumper[THUMPER_FLAGS] ^= FLAG_SHOW
            if ( eThumper[THUMPER_FLAGS] & FLAG_SHOW )
                eThumper[THUMPER_FLAGS] |= FLAG_ACTIVE
            else
                eThumper[THUMPER_FLAGS] &= ~FLAG_ACTIVE
            thumperSetState(eThumper)

            client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_SHOW_CURRENT",
            eThumper[THUMPER_NAME], id, eThumper[THUMPER_FLAGS] & FLAG_SHOW ? "THUMPER_CHAT_SHOWN" : "THUMPER_CHAT_HIDDEN")
            ArraySetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iThumper; i ++ )
            {
                ArrayGetArray(g_aThumper, i, eThumper)
                eThumper[THUMPER_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
                thumperSetState(eThumper)

                ArraySetArray(g_aThumper, i, eThumper)
            }

            client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_SHOW_ALL_SHOWN")
            thumperSound(id, SOUND_MENU_ALERT)
            thumperMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iThumper; i ++ )
            {
                ArrayGetArray(g_aThumper, i, eThumper)
                eThumper[THUMPER_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
                thumperSetState(eThumper)

                ArraySetArray(g_aThumper, i, eThumper)
            }

            client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_SHOW_ALL_HIDDEN")
            thumperSound(id, SOUND_MENU_ALERT)
            thumperMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                thumperSound(id, SOUND_MENU_NAV)
                thumperMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eThumper[THUMPER]
    menuNav(id, iMenu)
    ArrayGetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_STATUS_CURRENT",
    eThumper[THUMPER_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eThumper[THUMPER_NAME], id, eThumper[THUMPER_FLAGS] & FLAG_ACTIVE ? "THUMPER_ENABLED" : "THUMPER_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    thumperSelect(eThumper, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)
}

public menuHandlerStatus(id, menu, item)
{
    new eThumper[THUMPER]
    ArrayGetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        thumperSelect(eThumper, eThumper[THUMPER_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_THUMPER_MENU] >= g_iThumper - 1 )
                g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_THUMPER_MENU] ++

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_THUMPER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_THUMPER_MENU] = g_iThumper - 1
            else
                g_ePlayerData[id][PDATA_THUMPER_MENU] --

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eThumper[THUMPER_FLAGS] ^= FLAG_ACTIVE
            thumperSetState(eThumper)

            client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_STATUS_CURRENT",
            eThumper[THUMPER_NAME], id, eThumper[THUMPER_FLAGS] & FLAG_ACTIVE ? "THUMPER_CHAT_ENABLED" : "THUMPER_CHAT_DISABLED")
            ArraySetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iThumper; i ++ )
            {
                ArrayGetArray(g_aThumper, i, eThumper)
                eThumper[THUMPER_FLAGS] |= FLAG_ACTIVE
                thumperSetState(eThumper)

                ArraySetArray(g_aThumper, i, eThumper)
            }

            client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_STATUS_ALL_ENABLED")
            thumperSound(id, SOUND_MENU_ALERT)
            thumperMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iThumper; i ++ )
            {
                ArrayGetArray(g_aThumper, i, eThumper)
                eThumper[THUMPER_FLAGS] &= ~FLAG_ACTIVE
                thumperSetState(eThumper)

                ArraySetArray(g_aThumper, i, eThumper)
            }

            client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_STATUS_ALL_DISABLED")
            thumperSound(id, SOUND_MENU_ALERT)
            thumperMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                thumperSound(id, SOUND_MENU_NAV)
                thumperMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eThumper[THUMPER]
    if ( thumperGet(eThumper, g_ePlayerData[id][PDATA_THUMPER_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROTATE_GROUND",
    id, eThumper[THUMPER_FLAGS] & FLAG_GROUND ? "THUMPER_ON" : "THUMPER_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROTATE_SIZE", id, g_szRotateSize[g_ePlayerData[id][PDATA_ROTATE_SIZE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THUMPER_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eThumper[THUMPER], iItem
    if ( (iItem = thumperGet(eThumper, g_ePlayerData[id][PDATA_THUMPER_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eThumper[THUMPER_ID], pev_angles, eThumper[THUMPER_ANGLES])
            eThumper[THUMPER_ANGLES][1] -= THUMPER_ROTATION_STEP
            if ( eThumper[THUMPER_ANGLES][1] < -180.0 ) eThumper[THUMPER_ANGLES][1] += 360.0

            set_pev(eThumper[THUMPER_ID], pev_angles, eThumper[THUMPER_ANGLES])
            ArraySetArray(g_aThumper, iItem, eThumper)

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eThumper[THUMPER_ID], pev_angles, eThumper[THUMPER_ANGLES])
            eThumper[THUMPER_ANGLES][1] += THUMPER_ROTATION_STEP
            if ( eThumper[THUMPER_ANGLES][1] > 180.0 ) eThumper[THUMPER_ANGLES][1] -= 360.0

            set_pev(eThumper[THUMPER_ID], pev_angles, eThumper[THUMPER_ANGLES])
            ArraySetArray(g_aThumper, iItem, eThumper)

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eThumper[THUMPER_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aThumper, iItem, eThumper)

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_ROTATE)
        }
        case ROTATE_SIZE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SIZE] > SIZE_SMALL )
                g_ePlayerData[id][PDATA_ROTATE_SIZE] = SIZE_NORMAL

            eThumper[THUMPER_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
            switch( eThumper[THUMPER_SIZE] )
            {
                case SIZE_NORMAL: engfunc(EngFunc_SetModel, eThumper[THUMPER_ID], g_eSettings[SETTING_MODEL_NORMAL])
                case SIZE_SMALL:  engfunc(EngFunc_SetModel, eThumper[THUMPER_ID], g_eSettings[SETTING_MODEL_SMALL])
            }

            ArraySetArray(g_aThumper, iItem, eThumper)
            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            thumperTrace(eThumper, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_THUMPER_GHOST] = 0

            eThumper[THUMPER_FLAGS] &= ~FLAG_GHOST
            eThumper[THUMPER_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eThumper[THUMPER_ANGLES][0] = -eThumper[THUMPER_ANGLES][0]
            thumperSetSize(eThumper)
            thumperSetState(eThumper)
            client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_CREATE_NEW", eThumper[THUMPER_NAME])

            ArraySetArray(g_aThumper, iItem, eThumper)
            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            thumperKill(eThumper[THUMPER_ID])
            thumperRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_THUMPER_GHOST] = 0

            thumperSound(id, SOUND_MENU_NAV)
            thumperMenu(id, MENU_CREATE)
        }
        default:
        {
            thumperKill(eThumper[THUMPER_ID])
            thumperRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_THUMPER_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

stock thumperCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new eThumper[THUMPER]
    ArrayGetArray(g_aThumperConfig, iItem, eThumper)
    eThumper[THUMPER_ID] = iEnt
    eThumper[THUMPER_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_THUMPER_GHOST] = eThumper[THUMPER_ID]
        g_ePlayerData[id][PDATA_OFFSET] = THUMPER_OFFSET_BASE

        eThumper[THUMPER_FLAGS] |= FLAG_GHOST
        eThumper[THUMPER_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
    }

    thumperSelect(eThumper, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, THUMPER_KEY)
    set_pev(iEnt, THUMPER_ARRAY_ITEM, g_iThumper)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

    if ( id )
    {
        switch( eThumper[THUMPER_SIZE] )
        {
            case SIZE_NORMAL:   engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_NORMAL])
            case SIZE_SMALL:    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_SMALL])
        }
    }

    ArrayPushArray(g_aThumper, eThumper)
    if ( ++ g_iThumper == 1 )
        EnableThumper()
}

public thumperRemove(iItem)
{
    new eThumper[THUMPER]
    ArrayDeleteItem(g_aThumper, iItem)

    if ( -- g_iThumper == 0 )
        DisableThumper()

    for ( new i = iItem; i < g_iThumper; i ++ )
    {
        ArrayGetArray(g_aThumper, i, eThumper)
        set_pev(eThumper[THUMPER_ID], THUMPER_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eThumper[THUMPER],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_CombineThumper.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    for ( new i = 0; i < g_iThumper; i ++ )
    {
        ArrayGetArray(g_aThumper, i, eThumper)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eThumper[THUMPER_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eThumper[THUMPER_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "size = %d^n", eThumper[THUMPER_SIZE])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eThumper[THUMPER_ORIGIN][0], eThumper[THUMPER_ORIGIN][1], eThumper[THUMPER_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eThumper[THUMPER_ANGLES][0], eThumper[THUMPER_ANGLES][1], eThumper[THUMPER_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "THUMPER_CHAT_TAG", id, "THUMPER_CHAT_SAVE", szFile)
    fclose(iFile)

    thumperSound(id, SOUND_MENU_NAV)
    thumperMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iSize, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_CombineThumper.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataThumper(iItem, iFlags, iSize, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "size") )
            {
                iSize = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataThumper(iItem, iFlags, iSize, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock LoadDataThumper(iItem, iFlags, iSize, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eThumper[THUMPER]
    thumperCreate(0, iItem)
    ArrayGetArray(g_aThumper, iCount, eThumper)

    eThumper[THUMPER_FLAGS] = iFlags
    eThumper[THUMPER_SIZE] = iSize
    switch( eThumper[THUMPER_SIZE] )
    {
        case SIZE_NORMAL: engfunc(EngFunc_SetModel, eThumper[THUMPER_ID], g_eSettings[SETTING_MODEL_NORMAL])
        case SIZE_SMALL:  engfunc(EngFunc_SetModel, eThumper[THUMPER_ID], g_eSettings[SETTING_MODEL_SMALL])
    }

    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eThumper[THUMPER_ORIGIN])
    xs_vec_copy(fAngles, eThumper[THUMPER_ANGLES])

    thumperSetBox(eThumper)
    thumperSetSize(eThumper)
    thumperSetState(eThumper)
    ArraySetArray(g_aThumper, iCount, eThumper)
}

public thumperNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    thumperSound(id, SOUND_MENU_NAV)
    thumperMenu(id, MENU_ROOT)
}

public thumperGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    thumperSound(id, SOUND_MENU_NAV)
    thumperMenu(id, MENU_ROOT)
}

public fwdUse(iEnt, iCaller, iActivator, iType, Float:fValue)
{
    if ( !isThumper(iEnt)
    || !is_user_alive(iActivator) )
        return HAM_IGNORED

    new eThumper[THUMPER], iItem, Float:fCurrentTime
    fCurrentTime = get_gametime()
    if ( (iItem = thumperGet(eThumper, iEnt)) == -1
    || !(CsTeams:eThumper[THUMPER_USE_TEAM] & cs_get_user_team(iActivator))
    || fCurrentTime < eThumper[THUMPER_NEXT_USE] )
        return HAM_IGNORED

    eThumper[THUMPER_FLAGS] ^= FLAG_ACTIVE
    eThumper[THUMPER_NEXT_USE] = fCurrentTime + g_eSettings[SETTING_USE_COOLDOWN]
    thumperSetState(eThumper)
    ArraySetArray(g_aThumper, iItem, eThumper)
    return HAM_IGNORED
}

public fwdObjectCaps(iEnt)
{
    if ( !isThumper(iEnt) )
        return GetHamReturnStatus() == HAM_SUPERCEDE ? HAM_SUPERCEDE : HAM_IGNORED

    SetHamReturnInteger(FCAP_IMPULSE_USE)
    return HAM_SUPERCEDE
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eThumper[THUMPER], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( thumperGet(eThumper, g_ePlayerData[id][PDATA_THUMPER_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_THUMPER_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += THUMPER_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], THUMPER_OFFSET_MIN, THUMPER_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= THUMPER_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], THUMPER_OFFSET_MIN, THUMPER_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            thumperTrace(eThumper, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_THUMPER_ACTION] )
    {
        thumperCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_THUMPER_MENU] = 0
    if ( g_ePlayerData[id][PDATA_THUMPER_GHOST] )
    {
        new eThumper[THUMPER], iItem
        if ( (iItem = thumperGet(eThumper, g_ePlayerData[id][PDATA_THUMPER_GHOST])) != -1 )
        {
            thumperKill(eThumper[THUMPER_ID])
            thumperRemove(iItem)
        }

        g_ePlayerData[id][PDATA_THUMPER_GHOST] = 0
    }
}

stock thumperTrace(eThumper[THUMPER], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eThumper[THUMPER_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eThumper[THUMPER_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eThumper[THUMPER_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eThumper[THUMPER_ORIGIN])

    thumperSetBox(eThumper)
    thumperSetOffset(eThumper)
    set_pev(eThumper[THUMPER_ID], pev_origin, eThumper[THUMPER_ORIGIN])
}

stock thumperCheck(id)
{
    new eThumper[THUMPER], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = THUMPER_CHECK
    for ( new i = 0; i < g_iThumper; i ++ )
    {
        ArrayGetArray(g_aThumper, i, eThumper)
        xs_vec_sub(eThumper[THUMPER_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eThumper[THUMPER_ID], pev_absmin, fMins)
        pev(eThumper[THUMPER_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_THUMPER_MENU] != iBest )
    {
        ArrayGetArray(g_aThumper, g_ePlayerData[id][PDATA_THUMPER_MENU], eThumper)
        thumperSelect(eThumper, eThumper[THUMPER_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_THUMPER_MENU] = iBest
        thumperMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

public thumperThump(iTask)
{
    new eThumper[THUMPER], iEnt
    iEnt = iTask - THUMPER_TASK_THUMP
    if ( !pev_valid(iEnt)
    || thumperGet(eThumper, iEnt) == -1 )
        return

    new Float:fOrigin[3], Float:fVec[3], Float:fDist, Float:fFactor

    engfunc(EngFunc_EmitSound, iEnt, CHAN_WEAPON, g_eSettings[SETTING_SOUND_HIT], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    engfunc(EngFunc_EmitSound, iEnt, CHAN_BODY, g_eSettings[SETTING_SOUND_DUST], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    set_task(TOP_DURATION / eThumper[THUMPER_FRAMERATE], "thumperTop", eThumper[THUMPER_ID] + THUMPER_TASK_THUMP)
    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        pev(id, pev_origin, fOrigin)
        fDist = xs_vec_distance(fOrigin, eThumper[THUMPER_ORIGIN])
        if ( (eThumper[THUMPER_FLAGS] & FLAG_SHAKE) && fDist <= eThumper[THUMPER_RANGE_SHAKE] )
            thumperShake(eThumper, id)

        if ( !(eThumper[THUMPER_FLAGS] & (FLAG_DAMAGE | FLAG_PUSH))
        || fDist > eThumper[THUMPER_RANGE_IMPACT]
        || !(CsTeams:eThumper[THUMPER_TEAM] & cs_get_user_team(id)) )
            continue

        fFactor = 1.0 - (fDist / eThumper[THUMPER_RANGE_IMPACT])
        if ( eThumper[THUMPER_FLAGS] & FLAG_DAMAGE )
            ExecuteHamB(Ham_TakeDamage, id, iEnt, iEnt, random_float(eThumper[THUMPER_DAMAGE][0], eThumper[THUMPER_DAMAGE][1]) * fFactor * g_eSettings[SETTING_FACTOR_DAMAGE], eThumper[THUMPER_DAMAGETYPE])

        if ( eThumper[THUMPER_FLAGS] & FLAG_PUSH )
        {
            xs_vec_sub(fOrigin, eThumper[THUMPER_ORIGIN], fVec)
            fVec[2] = 0.0
            xs_vec_normalize(fVec, fVec)

            xs_vec_mul_scalar(fVec, random_float(eThumper[THUMPER_PUSH_FORWARD][0], eThumper[THUMPER_PUSH_FORWARD][1]) * fFactor * g_eSettings[SETTING_FACTOR_PUSH], fVec)
            fVec[2] = random_float(eThumper[THUMPER_PUSH_UP][0], eThumper[THUMPER_PUSH_UP][1]) * fFactor * g_eSettings[SETTING_FACTOR_PUSH]
            set_pev(id, pev_velocity, fVec)
        }
    }
}

public thumperTop(iTask)
{
    new iEnt = iTask - THUMPER_TASK_THUMP
    if ( pev_valid(iEnt) )
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, g_eSettings[SETTING_SOUND_TOP], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock thumperShake(eThumper[THUMPER], id)
{
    message_begin(MSG_ONE_UNRELIABLE, g_iScreenShake, .player = id)
    write_short(eThumper[THUMPER_SHAKE_AMPLITUDE] * 4096)
    write_short(eThumper[THUMPER_SHAKE_DURATION] * 4096)
    write_short(eThumper[THUMPER_SHAKE_FREQUENCY] * 4096)
    message_end()
}

stock thumperSetBox(eThumper[THUMPER])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eThumper[THUMPER_ANGLES][0] = -eThumper[THUMPER_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eThumper[THUMPER_ANGLES], fForward, fRight, fUp)
    switch( eThumper[THUMPER_SIZE] )
    {
        case SIZE_NORMAL:   { xs_vec_copy(g_eSettings[SETTING_MINS_NORMAL], fMins); xs_vec_copy(g_eSettings[SETTING_MAXS_NORMAL], fMaxs); }
        case SIZE_SMALL:    { xs_vec_copy(g_eSettings[SETTING_MINS_SMALL], fMins);  xs_vec_copy(g_eSettings[SETTING_MAXS_SMALL], fMaxs); }
    }

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eThumper[THUMPER_MINS])
    xs_vec_copy(fMaxs, eThumper[THUMPER_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock thumperSetOffset(eThumper[THUMPER])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eThumper[THUMPER_MINS][0]
    fGaps[1] = eThumper[THUMPER_MAXS][0]
    fGaps[2] = -eThumper[THUMPER_MINS][1]
    fGaps[3] = eThumper[THUMPER_MAXS][1]
    fGaps[4] = -eThumper[THUMPER_MINS][2]
    fGaps[5] = eThumper[THUMPER_MAXS][2]

    if ( eThumper[THUMPER_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eThumper[THUMPER_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eThumper[THUMPER_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eThumper[THUMPER_ID], 0)
        get_tr2(0, TR_vecEndPos, eThumper[THUMPER_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eThumper[THUMPER_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eThumper[THUMPER_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eThumper[THUMPER_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eThumper[THUMPER_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eThumper[THUMPER_ORIGIN], fVec1, eThumper[THUMPER_ORIGIN])
        }
    }
}

stock thumperSetSeq(iEnt, Float:fFrameRate)
{
    set_pev(iEnt, pev_sequence, 0)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, fFrameRate)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock thumperSetSize(eThumper[THUMPER])
{
    thumperSelect(eThumper, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eThumper[THUMPER_ID], eThumper[THUMPER_ORIGIN])
    set_pev(eThumper[THUMPER_ID], pev_angles, eThumper[THUMPER_ANGLES])
    set_pev(eThumper[THUMPER_ID], pev_solid, eThumper[THUMPER_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eThumper[THUMPER_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eThumper[THUMPER_ID], eThumper[THUMPER_MINS], eThumper[THUMPER_MAXS])
    if ( eThumper[THUMPER_SIZE] == SIZE_SMALL )
    {
        eThumper[THUMPER_RANGE_SHAKE] = g_eSettings[SETTING_DEFAULT_RANGE_SHAKE][0]
        eThumper[THUMPER_RANGE_IMPACT] = g_eSettings[SETTING_DEFAULT_RANGE_IMPACT][0]
        eThumper[THUMPER_SHAKE_AMPLITUDE] = g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE][0]
        eThumper[THUMPER_SHAKE_DURATION] = g_eSettings[SETTING_DEFAULT_SHAKE_DURATION][0]
        eThumper[THUMPER_SHAKE_FREQUENCY] = g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY][0]
    }
    else
    {
        eThumper[THUMPER_RANGE_SHAKE] = g_eSettings[SETTING_DEFAULT_RANGE_SHAKE][1]
        eThumper[THUMPER_RANGE_IMPACT] = g_eSettings[SETTING_DEFAULT_RANGE_IMPACT][1]
        eThumper[THUMPER_SHAKE_AMPLITUDE] = g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE][1]
        eThumper[THUMPER_SHAKE_DURATION] = g_eSettings[SETTING_DEFAULT_SHAKE_DURATION][1]
        eThumper[THUMPER_SHAKE_FREQUENCY] = g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY][1]
    }
}

stock thumperSetState(eThumper[THUMPER], bool:bPlaySound = true)
{
    if ( eThumper[THUMPER_FLAGS] & FLAG_SHOW )
    {
        set_pev(eThumper[THUMPER_ID], pev_solid, SOLID_BBOX)
        thumperSelect(eThumper, TARGET_CLEAR)

        if ( eThumper[THUMPER_FLAGS] & FLAG_ACTIVE
        && !task_exists(eThumper[THUMPER_ID] + THUMPER_TASK_THUMP) )
        {
            engfunc(EngFunc_EmitSound, eThumper[THUMPER_ID], CHAN_ITEM, g_eSettings[SETTING_SOUND_ON], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
            engfunc(EngFunc_EmitAmbientSound, eThumper[THUMPER_ID], CHAN_ITEM, g_eSettings[SETTING_SOUND_AMB], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

            thumperSetSeq(eThumper[THUMPER_ID], eThumper[THUMPER_FRAMERATE])
            set_task(THUMP_DURATION / eThumper[THUMPER_FRAMERATE], "thumperThump", eThumper[THUMPER_ID] + THUMPER_TASK_THUMP, .flags = "b")
            set_task(TOP_DURATION / eThumper[THUMPER_FRAMERATE], "thumperTop", eThumper[THUMPER_ID] + THUMPER_TASK_THUMP)
        }
        else
        {
            engfunc(EngFunc_EmitAmbientSound, eThumper[THUMPER_ID], eThumper[THUMPER_ORIGIN], g_eSettings[SETTING_SOUND_AMB], VOL_NORM, SND_STOP, PITCH_NORM)
            engfunc(EngFunc_EmitSound, eThumper[THUMPER_ID], CHAN_ITEM, g_eSettings[SETTING_SOUND_ON], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
            engfunc(EngFunc_EmitSound, eThumper[THUMPER_ID], CHAN_ITEM, g_eSettings[SETTING_SOUND_TOP], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
            engfunc(EngFunc_EmitSound, eThumper[THUMPER_ID], CHAN_ITEM, g_eSettings[SETTING_SOUND_HIT], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
            engfunc(EngFunc_EmitSound, eThumper[THUMPER_ID], CHAN_ITEM, g_eSettings[SETTING_SOUND_DUST], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
            if ( bPlaySound )
                engfunc(EngFunc_EmitSound, eThumper[THUMPER_ID], CHAN_ITEM, g_eSettings[SETTING_SOUND_OFF], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

            thumperSetSeq(eThumper[THUMPER_ID], 0.0)
            remove_task(eThumper[THUMPER_ID] + THUMPER_TASK_THUMP)
        }
    }
    else
    {
        set_pev(eThumper[THUMPER_ID], pev_solid, SOLID_NOT)
        thumperSelect(eThumper, TARGET_HIDE)

        thumperSetSeq(eThumper[THUMPER_ID], 0.0)
        remove_task(eThumper[THUMPER_ID] + THUMPER_TASK_THUMP)
    }
}

stock thumperSelect(eThumper[THUMPER], iAction)
{
    new iRenderColor[3]
    if ( iAction == TARGET_SELECT )
    {
        if ( eThumper[THUMPER_FLAGS] & FLAG_ACTIVE )    { iRenderColor[0] = g_iColorActive[0];    iRenderColor[1] = g_iColorActive[1];    iRenderColor[2] = g_iColorActive[2]; }
        else                                            { iRenderColor[0] = g_iColorInactive[0];  iRenderColor[1] = g_iColorInactive[1];  iRenderColor[2] = g_iColorInactive[2]; }

        set_ent_rendering(eThumper[THUMPER_ID], kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_ent_rendering(eThumper[THUMPER_ID], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, THUMPER_GHOST_ALPHA)
    }
    else if ( iAction == TARGET_HIDE )
    {
        set_ent_rendering(eThumper[THUMPER_ID], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_ent_rendering(eThumper[THUMPER_ID], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
    }
}

stock thumperSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_VOICE, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock thumperReset()
{
    new eThumper[THUMPER]
    for ( new i = 0; i < g_iThumper; i ++ )
    {
        ArrayGetArray(g_aThumper, i, eThumper)
        eThumper[THUMPER_NEXT_USE] = 0.0
        ArraySetArray(g_aThumper, i, eThumper)
    }
}

stock thumperGet(eThumper[THUMPER], iEnt)
{
    if ( !isThumper(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, THUMPER_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iThumper )
        return -1

    ArrayGetArray(g_aThumper, iItem, eThumper)
    return iItem
}

stock bool:isThumper(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == THUMPER_KEY
}

stock thumperKill(iEnt)
{
    if ( pev_valid(iEnt) )
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_ARRAY_MESSAGE:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_MODEL:
        {
            if ( !g_bFileWasRead )
                precache_model(szValue)

            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
        case DTYPE_ARRAY_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                ArrayPushCell(aOutput[0], precache_model(szValue))
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_THUMPER_ACTION] )
    {
        new eThumper[THUMPER]
        for ( new i = 0; i < g_iThumper; i ++ )
        {
            ArrayGetArray(g_aThumper, i, eThumper)
            if ( eThumper[THUMPER_FLAGS] & FLAG_SHOW )
                continue

            thumperSelect(eThumper, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_THUMPER_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_THUMPER_ACTION] )
    {
        new eThumper[THUMPER]
        for ( new i = 0; i < g_iThumper; i ++ )
        {
            ArrayGetArray(g_aThumper, i, eThumper)
            if ( eThumper[THUMPER_FLAGS] & FLAG_SHOW )
                continue

            thumperSelect(eThumper, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_THUMPER_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
}

stock EnableThumper()
{
    EnableHamForward(g_iFwdUse)
    EnableHamForward(g_iFwdObjectCaps)
}

stock DisableThumper()
{
    DisableHamForward(g_iFwdUse)
    DisableHamForward(g_iFwdObjectCaps)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}