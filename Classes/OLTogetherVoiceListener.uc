// OLTogetherVoiceListener.uc
// Local control channel for the desktop voice client (voice_client.py).
// The game listens on 127.0.0.1 and pushes the local player's world position
// and push-to-talk state so the voice client can gate its microphone and
// attenuate incoming audio by distance. Audio itself never travels over this
// link; it flows over UDP to the voice relay.

class OLTogetherVoiceListener extends TcpLink;

var int ListenPort;
var OLTogetherController ControllerOwner;
var OLTogetherVoiceListener ActiveChild;
var bool bClientConnected;

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
    LinkMode    = MODE_Text;
    ReceiveMode = RMODE_Event;
}

function Init(OLTogetherController Controller)
{
    ControllerOwner = Controller;
    ListenPort      = 6700;

    LinkMode    = MODE_Text;
    ReceiveMode = RMODE_Event;

    if (BindPort(ListenPort) > 0)
    {
        Listen();
        `log("OLTogetherVoiceListener: Listening on port " $ ListenPort);
    }
    else
    {
        `log("OLTogetherVoiceListener: FAILED to bind port " $ ListenPort $ " - is another app using it?");
    }
}

event GainedChild(Actor C)
{
    local OLTogetherVoiceListener Child;
    Child = OLTogetherVoiceListener(C);
    if (Child != None)
    {
        Child.ControllerOwner = ControllerOwner;
        ActiveChild = Child;
        bClientConnected = true;
        `log("OLTogetherVoiceListener: Voice client connected.");
    }
}

event LostChild(Actor C)
{
    if (OLTogetherVoiceListener(C) == ActiveChild)
    {
        ActiveChild = None;
        bClientConnected = false;
        `log("OLTogetherVoiceListener: Voice client disconnected.");
    }
}

// Push a control line to the connected voice client. Called from the parent
// listener; forwards through the accepted child connection.
function SendControl(string Line)
{
    if (ActiveChild != None)
        ActiveChild.SendText(Line $ "\n");
}

event ReceivedText(string Text)
{
    // The voice client is push-only from the game's perspective; ignore any
    // inbound chatter but keep the handler so the link stays in event mode.
}

defaultproperties
{
    AcceptClass=class'OLTogetherVoiceListener'
    ListenPort=6700
}
