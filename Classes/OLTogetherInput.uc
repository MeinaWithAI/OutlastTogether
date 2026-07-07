class OLTogetherInput extends OLPlayerInput within OLTogetherController;

var bool bIgnoreNextChar;
var IntPoint MousePosition;
var bool bMouseCaptured;
var bool bShiftDown;
var bool bCtrlDown;
var int ChatSelectionAnchor;

function int ChatSelMin()
{
    if (Outer.ChatSelStart < Outer.ChatSelEnd)
        return Outer.ChatSelStart;
    return Outer.ChatSelEnd;
}

function int ChatSelMax()
{
    if (Outer.ChatSelStart > Outer.ChatSelEnd)
        return Outer.ChatSelStart;
    return Outer.ChatSelEnd;
}

function ChatExtendSelection()
{
    Outer.ChatSelStart = ChatSelectionAnchor;
    Outer.ChatSelEnd = Outer.ChatCaretPos;
}

function ChatDeleteSelection()
{
    local int A, B;
    A = ChatSelMin();
    B = ChatSelMax();
    Outer.ChatText = Left(Outer.ChatText, A) $ Mid(Outer.ChatText, B);
    Outer.ChatCaretPos = A;
    Outer.ChatSelStart = A;
    Outer.ChatSelEnd = A;
    ChatSelectionAnchor = A;
    NoteChatCaretMove();
}

function ChatInsertText(string S)
{
    local string Clean;
    Clean = Repl(Repl(S, Chr(13), "", true), Chr(10), "", true);
    if (Clean == "")
        return;
    if (Outer.ChatSelStart != Outer.ChatSelEnd)
        ChatDeleteSelection();
    if (Len(Outer.ChatText) + Len(Clean) > 128)
        Clean = Left(Clean, 128 - Len(Outer.ChatText));
    if (Clean == "")
        return;
    Outer.ChatText = Left(Outer.ChatText, Outer.ChatCaretPos) $ Clean $ Mid(Outer.ChatText, Outer.ChatCaretPos);
    Outer.ChatCaretPos += Len(Clean);
    Outer.ChatSelStart = Outer.ChatCaretPos;
    Outer.ChatSelEnd = Outer.ChatCaretPos;
    ChatSelectionAnchor = Outer.ChatCaretPos;
    NoteChatCaretMove();
}

function NoteChatCaretMove()
{
    local OLTogetherHUD H;
    H = OLTogetherHUD(Outer.myHUD);
    if (H == None)
        H = OLTogetherHUD(Outer.HUD);
    if (H != None)
        H.NoteChatCaretMove();
}

function int ChatFindWordLeft(int Pos)
{
    while (Pos > 0 && Mid(Outer.ChatText, Pos - 1, 1) == " ")
        Pos--;
    while (Pos > 0 && Mid(Outer.ChatText, Pos - 1, 1) != " ")
        Pos--;
    return Pos;
}

function int ChatFindWordRight(int Pos)
{
    while (Pos < Len(Outer.ChatText) && Mid(Outer.ChatText, Pos, 1) == " ")
        Pos++;
    while (Pos < Len(Outer.ChatText) && Mid(Outer.ChatText, Pos, 1) != " ")
        Pos++;
    return Pos;
}

event PlayerInput(float DeltaTime)
{
    local OLTogetherHUD H;
    H = OLTogetherHUD(myHUD);
    if (H != None && (H.bSettingsOpen || Outer.bChatMode))
    {
        if (!bMouseCaptured)
        {
            bMouseCaptured = true;
            MousePosition.X = H.SizeX / 2;
            MousePosition.Y = H.SizeY / 2;
        }
        MousePosition.X = Clamp(MousePosition.X + aMouseX, 0, H.SizeX);
        MousePosition.Y = Clamp(MousePosition.Y - aMouseY, 0, H.SizeY);
        aMouseX = 0;
        aMouseY = 0;

        if (Outer.bChatMode && H.bChatSelectingDrag)
        {
            Outer.ChatCaretPos = H.ChatHitTestCaret(Outer, MousePosition.X);
            Outer.ChatSelStart = ChatSelectionAnchor;
            Outer.ChatSelEnd = Outer.ChatCaretPos;
            H.NoteChatCaretMove();
        }
    }
    else
    {
        bMouseCaptured = false;
    }
    Super.PlayerInput(DeltaTime);
}

function bool Key(int ControllerId, name Key, EInputEvent Event, float AmountDepressed=1.0, bool bGamepad=false)
{
    local OLTogetherHUD H;

    if (Outer == None)
        return false;

    H = OLTogetherHUD(Outer.myHUD);
    if (H == None)
        H = OLTogetherHUD(Outer.HUD);

    // Track modifier key state for chat editing (selection extend / shortcuts).
    if (Key == 'LeftShift' || Key == 'RightShift')
        bShiftDown = (Event == IE_Pressed || Event == IE_Repeat);
    if (Key == 'LeftControl' || Key == 'RightControl')
        bCtrlDown = (Event == IE_Pressed || Event == IE_Repeat);

    // While the settings menu is open it captures navigation so movement keys
    // don't leak into gameplay. Mouse click triggers selection.
    if (H != None && H.bSettingsOpen)
    {
        if (H.bRebindListening)
        {
            if (Event == IE_Pressed)
            {
                if (Key == 'Escape')
                {
                    H.bRebindListening = false;
                    H.RebindSlotIndex = -1;
                    return true;
                }
                if (Key != 'LeftMouseButton' && Key != 'RightMouseButton' && Key != 'MiddleMouseButton')
                {
                    H.CaptureRebindKey(Outer, Key);
                    return true;
                }
            }
            return true;
        }

        if (Event == IE_Pressed && Key == 'LeftMouseButton')
        {
            Outer.SettingsMenuClick();
            return true;
        }
        if (Event == IE_Pressed || Event == IE_Repeat)
        {
            switch (Key)
            {
                case 'Up': case 'W':          Outer.SettingsMenuInput('Up');    return true;
                case 'Down': case 'S':        Outer.SettingsMenuInput('Down');  return true;
                case 'Left': case 'A':        Outer.SettingsMenuInput('Left');  return true;
                case 'Right': case 'D':       Outer.SettingsMenuInput('Right'); return true;
                case 'Enter': case 'SpaceBar': Outer.SettingsMenuInput('Enter'); return true;
                case 'Escape': case 'Tilde':  Outer.SettingsMenuInput('Escape'); return true;
            }
        }
        return true;
    }

    // Tilde toggles the settings menu (only when not in chat)
    if (Event == IE_Pressed && Key == Outer.BindOpenSettings && !Outer.bChatMode)
    {
        Outer.ToggleSettingsMenu();
        return true;
    }

    // Ready toggle (when in speedrun mode)
    if (Event == IE_Pressed && Key == Outer.BindSpeedrunReady && Outer.bSpeedrunMode && !Outer.bChatMode)
    {
        Outer.ToggleSpeedrunReady();
        return true;
    }

    if (Event == IE_Pressed && Key == Outer.BindForceStart && Outer.bSpeedrunMode && !Outer.bChatMode)
    {
        Outer.ForceStartSpeedrun();
        return true;
    }

    // Push To Talk enabled: hold the bind to open the mic, release to mute.
    // Push To Talk disabled: each press toggles the mic open/muted.
    if (Event == IE_Pressed && Key == Outer.BindPushToTalk)
    {
        if (Outer.Settings != None && Outer.Settings.bPushToTalk)
            Outer.bMicTransmitting = true;
        else
            Outer.bMicTransmitting = !Outer.bMicTransmitting;
        return true;
    }
    if (Event == IE_Released && Key == Outer.BindPushToTalk)
    {
        if (Outer.Settings != None && Outer.Settings.bPushToTalk)
            Outer.bMicTransmitting = false;
        return true;
    }

    if (Outer.bChatMode)
    {
        if (Event == IE_Pressed && Key == 'LeftMouseButton')
        {
            if (H != None && H.EmojiPickerClick(Outer))
                return true;
            if (H != None && MousePosition.X >= H.ChatInputX && MousePosition.X < H.ChatInputX + H.ChatInputW
                && MousePosition.Y >= H.ChatInputY && MousePosition.Y < H.ChatInputY + H.ChatInputH)
            {
                Outer.ChatCaretPos = H.ChatHitTestCaret(Outer, MousePosition.X);
                Outer.ChatSelStart = Outer.ChatCaretPos;
                Outer.ChatSelEnd = Outer.ChatCaretPos;
                ChatSelectionAnchor = Outer.ChatCaretPos;
                H.bChatSelectingDrag = true;
                H.NoteChatCaretMove();
                return true;
            }
        }
        if (Event == IE_Released && Key == 'LeftMouseButton')
        {
            if (H != None)
                H.bChatSelectingDrag = false;
        }

        if (Event == IE_Pressed || Event == IE_Repeat)
        {
            if (Key == 'MouseScrollUp')
            {
                if (H != None && H.bEmojiPickerOpen)
                    H.ScrollEmojiPicker(-1);
                else if (H != None)
                    H.ScrollChat(3);
                return true;
            }
            if (Key == 'MouseScrollDown')
            {
                if (H != None && H.bEmojiPickerOpen)
                    H.ScrollEmojiPicker(1);
                else if (H != None)
                    H.ScrollChat(-3);
                return true;
            }
            if (Key == 'PageUp')
            {
                if (H != None && H.bEmojiPickerOpen)
                    H.ScrollEmojiPicker(-6);
                else if (H != None)
                    H.ScrollChat(6);
                return true;
            }
            if (Key == 'PageDown')
            {
                if (H != None && H.bEmojiPickerOpen)
                    H.ScrollEmojiPicker(6);
                else if (H != None)
                    H.ScrollChat(-6);
                return true;
            }
        }
    }

    if (Outer.bChatMode)
    {
        if (Event == IE_Pressed || Event == IE_Repeat)
        {
            if (Key == 'Enter' && Event == IE_Pressed)
            {
                if (Outer.ChatText != "")
                    Outer.Chat(Outer.ChatText);
                Outer.ChatText = "";
                Outer.ChatCaretPos = 0;
                Outer.ChatSelStart = 0;
                Outer.ChatSelEnd = 0;
                Outer.bChatMode = false;
                if (H != None)
                    H.CloseEmojiPicker();
                return true;
            }
            if (Key == 'BackSpace')
            {
                if (Outer.ChatSelStart != Outer.ChatSelEnd)
                {
                    ChatDeleteSelection();
                }
                else if (Outer.ChatCaretPos > 0)
                {
                    Outer.ChatText = Left(Outer.ChatText, Outer.ChatCaretPos - 1) $ Mid(Outer.ChatText, Outer.ChatCaretPos);
                    Outer.ChatCaretPos--;
                    Outer.ChatSelStart = Outer.ChatCaretPos;
                    Outer.ChatSelEnd = Outer.ChatCaretPos;
                }
                return true;
            }
            if (Key == 'Delete')
            {
                if (Outer.ChatSelStart != Outer.ChatSelEnd)
                {
                    ChatDeleteSelection();
                }
                else if (Outer.ChatCaretPos < Len(Outer.ChatText))
                {
                    Outer.ChatText = Left(Outer.ChatText, Outer.ChatCaretPos) $ Mid(Outer.ChatText, Outer.ChatCaretPos + 1);
                }
                return true;
            }
            if (Key == 'Escape' && Event == IE_Pressed)
            {
                Outer.ChatText = "";
                Outer.ChatCaretPos = 0;
                Outer.ChatSelStart = 0;
                Outer.ChatSelEnd = 0;
                Outer.bChatMode = false;
                if (H != None)
                    H.CloseEmojiPicker();
                return true;
            }
            if (Key == 'Left' || Key == 'Right' || Key == 'Home' || Key == 'End' ||
                Key == 'BackSpace' || Key == 'Delete')
                NoteChatCaretMove();
            if (Key == 'Left')
            {
                if (bShiftDown && Outer.ChatSelStart == Outer.ChatSelEnd)
                    ChatSelectionAnchor = Outer.ChatCaretPos;
                if (bCtrlDown)
                {
                    Outer.ChatCaretPos = ChatFindWordLeft(Outer.ChatCaretPos);
                }
                else if (Outer.ChatCaretPos > 0)
                {
                    if (!bShiftDown && Outer.ChatSelStart != Outer.ChatSelEnd)
                        Outer.ChatCaretPos = ChatSelMin();
                    else
                        Outer.ChatCaretPos--;
                }
                if (!bShiftDown) { Outer.ChatSelStart = Outer.ChatCaretPos; Outer.ChatSelEnd = Outer.ChatCaretPos; ChatSelectionAnchor = Outer.ChatCaretPos; }
                else ChatExtendSelection();
                return true;
            }
            if (Key == 'Right')
            {
                if (bShiftDown && Outer.ChatSelStart == Outer.ChatSelEnd)
                    ChatSelectionAnchor = Outer.ChatCaretPos;
                if (bCtrlDown)
                {
                    Outer.ChatCaretPos = ChatFindWordRight(Outer.ChatCaretPos);
                }
                else if (Outer.ChatCaretPos < Len(Outer.ChatText))
                {
                    if (!bShiftDown && Outer.ChatSelStart != Outer.ChatSelEnd)
                        Outer.ChatCaretPos = ChatSelMax();
                    else
                        Outer.ChatCaretPos++;
                }
                if (!bShiftDown) { Outer.ChatSelStart = Outer.ChatCaretPos; Outer.ChatSelEnd = Outer.ChatCaretPos; ChatSelectionAnchor = Outer.ChatCaretPos; }
                else ChatExtendSelection();
                return true;
            }
            if (Key == 'Home')
            {
                if (bShiftDown && Outer.ChatSelStart == Outer.ChatSelEnd)
                    ChatSelectionAnchor = Outer.ChatCaretPos;
                Outer.ChatCaretPos = 0;
                if (!bShiftDown) { Outer.ChatSelStart = 0; Outer.ChatSelEnd = 0; ChatSelectionAnchor = 0; }
                else ChatExtendSelection();
                return true;
            }
            if (Key == 'End')
            {
                if (bShiftDown && Outer.ChatSelStart == Outer.ChatSelEnd)
                    ChatSelectionAnchor = Outer.ChatCaretPos;
                Outer.ChatCaretPos = Len(Outer.ChatText);
                if (!bShiftDown) { Outer.ChatSelStart = Outer.ChatCaretPos; Outer.ChatSelEnd = Outer.ChatCaretPos; ChatSelectionAnchor = Outer.ChatCaretPos; }
                else ChatExtendSelection();
                return true;
            }
            if (Key == 'Space' && Event == IE_Pressed)
            {
                ChatInsertText(" ");
                return true;
            }
            if (bCtrlDown && Event == IE_Pressed)
            {
                if (Key == 'A')
                {
                    Outer.ChatSelStart = 0;
                    Outer.ChatSelEnd = Len(Outer.ChatText);
                    Outer.ChatCaretPos = Outer.ChatSelEnd;
                    return true;
                }
                if (Key == 'C')
                {
                    if (Outer.ChatSelStart != Outer.ChatSelEnd)
                        Outer.CopyToClipboard(Mid(Outer.ChatText, ChatSelMin(), ChatSelMax() - ChatSelMin()));
                    return true;
                }
                if (Key == 'X')
                {
                    if (Outer.ChatSelStart != Outer.ChatSelEnd)
                    {
                        Outer.CopyToClipboard(Mid(Outer.ChatText, ChatSelMin(), ChatSelMax() - ChatSelMin()));
                        ChatDeleteSelection();
                    }
                    return true;
                }
                if (Key == 'V')
                {
                    ChatInsertText(Outer.PasteFromClipboard());
                    return true;
                }
            }
        }

        return true;
    }

    if (Event == IE_Pressed && Key == 'T')
    {
        Outer.bChatMode = true;
        Outer.ChatText = "";
        Outer.ChatCaretPos = 0;
        Outer.ChatSelStart = 0;
        Outer.ChatSelEnd = 0;
        ChatSelectionAnchor = 0;
        if (H != None)
        {
            H.ResetChatVisibility();
            MousePosition.X = H.SizeX / 2;
            MousePosition.Y = H.SizeY / 2;
        }
        bMouseCaptured = true;
        bIgnoreNextChar = true;
        return true;
    }

    return false;
}

function bool Char(int ControllerId, string Unicode)
{
    if (Outer == None || !Outer.bChatMode)
        return false;

    if (bIgnoreNextChar)
    {
        bIgnoreNextChar = false;
        return true;
    }

    if (Len(Unicode) == 1 && Asc(Unicode) < 32)
        return true;

    ChatInsertText(Unicode);
    return true;
}

DefaultProperties
{
    OnReceivedNativeInputKey = Key
    OnReceivedNativeInputChar = Char
}