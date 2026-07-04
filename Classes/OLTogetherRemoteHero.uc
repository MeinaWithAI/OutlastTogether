class OLTogetherRemoteHero extends OLTogetherHero;

var vector TargetLocation;
var vector TargetVelocity;
var rotator TargetRotation;
var float InterpSpeed;
var bool bHasRemoteState;

function SetRemoteState(vector NewLocation, rotator NewRotation, vector NewVelocity)
{
    TargetLocation = NewLocation;
    TargetRotation = NewRotation;
    TargetVelocity = NewVelocity;
    bHasRemoteState = true;
}

function ClearRemoteState()
{
    bHasRemoteState = false;
}

event Tick(float DeltaTime)
{
    local vector NewLoc;
    local rotator NewRot;

    if (bHasRemoteState)
    {
        NewLoc = VInterpTo(Location, TargetLocation, DeltaTime, InterpSpeed);
        SetLocation(NewLoc);

        NewRot = RInterpTo(Rotation, TargetRotation, DeltaTime, InterpSpeed);
        NewRot.Pitch = 0;
        SetRotation(NewRot);

        Velocity = TargetVelocity;
        Acceleration = TargetVelocity;
    }

    ApplyPitch();
}

DefaultProperties
{
    InterpSpeed=12.0
    bHasRemoteState=false
}
