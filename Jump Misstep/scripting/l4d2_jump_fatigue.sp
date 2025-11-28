#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#pragma semicolon 1
#pragma newdecls required

// ===============================================
// Cvars (Variables có thể tùy chỉnh)
// ===============================================
public ConVar g_cvarJumpLimit;
public ConVar g_cvarFallChance;
public ConVar g_cvarFallVelocity; 
public ConVar g_cvarResetTime;
public ConVar g_cvarStunDuration; 

// ===============================================
// Global Data (Dữ liệu toàn cục)
// ===============================================
int g_iJumpCount[MAXPLAYERS + 1];

Handle sdkCallPushPlayer = INVALID_HANDLE; 
Handle GameConf = INVALID_HANDLE; 
bool isl4d2 = false;

// Tên file Gamedata mới
#define PLUGIN_GAMEDATA_FILE "l4d2_jump_fatigue" 

// ===============================================
// Plugin Setup
// ===============================================
public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int maxlen)
{
    CreateNative("GetJumpFatigueCount", Native_GetJumpFatigueCount);
    return APLRes_Success;
}

public Plugin myinfo = 
{
    name = "L4D2 Jump Slip Fling",
    author = "KeroN và AI",
    description = "Players who jump too much in a short time have a chance to stumble and fall.",
    version = "1.0", // Cập nhật version lên 1.0
    url = "https://guns.lol/gavailin"
};

public void OnPluginStart()
{
    // Kiểm tra và tải SDKCall
    char sGame[256];
    GetGameFolderName(sGame, sizeof(sGame));
    
    if (StrEqual(sGame, "left4dead2", false))
    {
        isl4d2 = true;
        
        // --- SỬA ĐỔI ĐỂ TẢI TÊN FILE MỚI CỦA BẠN ---
        GameConf = LoadGameConfigFile(PLUGIN_GAMEDATA_FILE);
            
        if(GameConf == INVALID_HANDLE)
        {
            // Lỗi sẽ hiển thị tên file mới
            SetFailState("Lỗi: Không tìm thấy file Gamedata (%s.gdt) trong addons/sourcemod/gamedata.", PLUGIN_GAMEDATA_FILE);
        }
        
        // --- Chuẩn bị SDKCall cho CTerrorPlayer_Fling ---
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(GameConf, SDKConf_Signature, "CTerrorPlayer_Fling");
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef); 
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); 
        PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); 
        PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain); 
        sdkCallPushPlayer = EndPrepSDKCall();
        
        if(sdkCallPushPlayer == INVALID_HANDLE)
        {
            SetFailState("Lỗi: Không tìm thấy signature 'CTerrorPlayer_Fling'. GameData có thể lỗi thời hoặc không khớp.");
        }	
        
        CloseHandle(GameConf);
    }
    
    // Tạo Cvars
    g_cvarJumpLimit = CreateConVar("l4d2_jf_jumplimit", "4", "Number of consecutive jumps before a fall chance is applied.", FCVAR_SPONLY|FCVAR_NOTIFY, true, 1.0);
    g_cvarFallChance = CreateConVar("l4d2_jf_fallchance", "30.0", "Percentage chance (0-100) to fall after reaching the jump limit.", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 100.0);
    g_cvarFallVelocity = CreateConVar("l4d2_jf_fallvelocity", "1000.0", "The base force applied to the player fling.", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0); 
    g_cvarResetTime = CreateConVar("l4d2_jf_resettime", "1.5", "Time in seconds before the jump count resets if no jumps are made.", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.1);
    g_cvarStunDuration = CreateConVar("l4d2_jf_stunduration", "2.0", "Duration (seconds) the fling/stun lasts.", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.1);

    // Đăng ký sự kiện PlayerJump
    HookEvent("player_jump", Event_PlayerJump, EventHookMode_Post);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            g_iJumpCount[i] = 0;
        }
    }
    
    AutoExecConfig(true, "l4d2_jump_slip_fling_bykeron");
}

public void OnClientPutInServer(int client)
{
    g_iJumpCount[client] = 0;
}

// ===============================================
// Events (Xử lý sự kiện)
// ===============================================
public void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
    if (!isl4d2) return; 

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
    {
        return;
    }

    g_iJumpCount[client]++;

    float fResetTime = g_cvarResetTime.FloatValue;
    CreateTimer(fResetTime, Timer_ResetJumpCount, GetClientUserId(client)); 
    
    int iJumpLimit = g_cvarJumpLimit.IntValue;
    float fFallChance = g_cvarFallChance.FloatValue;

    if (g_iJumpCount[client] >= iJumpLimit)
    {
        int iRand = GetRandomInt(1, 100);
        
        if (iRand <= RoundToFloor(fFallChance))
        {
            DoPlayerStumble(client);
            
            char sName[MAX_NAME_LENGTH];
            GetClientName(client, sName, sizeof(sName));
            PrintToChatAll("\x04%s\x03 nhảy bị trượt chân \x04Ngã\x03 hahaha!", sName); 
            
            g_iJumpCount[client] = 0;
        }
    }
}

// ===============================================
// Timers (Hẹn giờ)
// ===============================================
public Action Timer_ResetJumpCount(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    
    if (client > 0 && IsClientInGame(client) && g_iJumpCount[client] > 0)
    {
        g_iJumpCount[client] = 0;
    }
    
    return Plugin_Stop;
}

// ===============================================
// Custom Functions (Hàm tùy chỉnh)
// ===============================================
void DoPlayerStumble(int target)
{
    float fBaseForce = g_cvarFallVelocity.FloatValue;
    float fFlingDuration = g_cvarStunDuration.FloatValue;

    float fVelocity[3], fResultingFling[3];
    
    // Lấy vận tốc hiện tại của người chơi
    GetEntPropVector(target, Prop_Data, "m_vecVelocity", fVelocity);

    // Tính toán vector lực đẩy ngược
    fResultingFling[0] = (fVelocity[0] > 0.0) ? -fBaseForce : fBaseForce;
    fResultingFling[1] = (fVelocity[1] > 0.0) ? -fBaseForce : fBaseForce;
    
    // Đẩy Z lên (Fling)
    fResultingFling[2] = fVelocity[2] + fBaseForce * 0.5;

    // --- SỬ DỤNG SDKCALL ĐỂ HẤT TUNG ---
    SDKCall(sdkCallPushPlayer, target, fResultingFling, 76, target, fFlingDuration);
    
    PrintHintText(target, "Bạn bị ngã vì Trượt Chân");
}

// ===============================================
// Native Functions (Hàm Native để gọi từ các plugin khác)
// ===============================================
public int Native_GetJumpFatigueCount(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    
    if (client > 0 && client <= MaxClients && g_iJumpCount[client] >= 0)
    {
        return g_iJumpCount[client];
    }
    
    return 0;
}
