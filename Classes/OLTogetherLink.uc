class OLTogetherLink extends TcpLink config(Multiplayer);

var OLTogetherController ControllerOwner;
var bool bIsConnected;
var config string IP;
var config string Port;
var config bool   bFadeNearbyPlayers;
var config float  NearbyFadeDistance;
var config float  NearbyFadeHysteresis;

function SendAuth(string Token)
{
    if (Token != "")
        SendText("AUTH," $ Token $ ",0\n");
}

exec function SetServer(string NewIP, string NewPort)
{
    if (NewIP != "")
        IP = NewIP;
    if (NewPort != "")
        Port = NewPort;

    bIsConnected = false;
    `log("OLTogetherLink: Set server to " $ IP $ ":" $ Port);
    Resolve(IP);
}

exec function Reconnect()
{
    bIsConnected = false;
    `log("OLTogetherLink: Reconnecting to " $ IP $ ":" $ Port);
    Resolve(IP);
}

event PostBeginPlay()
{
    super.PostBeginPlay();
    LinkMode = MODE_Line;
    ReceiveMode = RMODE_Event;
    Resolve(IP);
}

event Resolved(IpAddr Addr)
{
    Addr.Port = int(Port);
    BindPort();
    Open(Addr);
}

event Opened()
{
    bIsConnected = true;
    `log("OLTogetherLink Connected to Server!");
    if (ControllerOwner != None)
    {
        ControllerOwner.ConnectionState = "Connected";
        ControllerOwner.AddChatLine("Connected to server " $ IP $ ":" $ Port);
        if (ControllerOwner.RoomAuthToken != "")
            SendAuth(ControllerOwner.RoomAuthToken);
    }
}

event Closed()
{
    bIsConnected = false;
    `log("OLTogetherLink Disconnected.");
    if (ControllerOwner != None)
    {
        ControllerOwner.ConnectionState = "Disconnected";
        ControllerOwner.AddChatLine("Disconnected from server.");
    }
}

event ReceivedLine(string Line)
{
    if (ControllerOwner != None)
    {
        ControllerOwner.OnReceiveData(Line);
    }
}

DefaultProperties
{
    IP="127.0.0.1"
    Port="7777"
    bFadeNearbyPlayers=false
    NearbyFadeDistance=200.0
    NearbyFadeHysteresis=50.0
}
