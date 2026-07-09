class OLTogetherRemoteController extends AIController;

var OLTogetherRemoteHero RemoteHero;
var vector LastAppliedLocation;
var vector LastAppliedVelocity;
var rotator LastAppliedRotation;
var bool bHasRemoteState;
var float TeleportDistance;
var float MoveStopDistance;
var float RunSpeedThreshold;
var float TurnInterpolationTime;

function Possess(Pawn inPawn, bool bVehicleTransition)
{
    super.Possess(inPawn, bVehicleTransition);
    RemoteHero = OLTogetherRemoteHero(inPawn);
    if (RemoteHero != None)
    {
        RemoteHero.SetMovementPhysics();
        RemoteHero.Controller = self;
    }
}

function UnPossess()
{
    RemoteHero = None;
    super.UnPossess();
}

function SetRemoteState(vector NewLocation, rotator NewRotation, vector NewVelocity)
{
    LastAppliedLocation = NewLocation;
    LastAppliedRotation = NewRotation;
    LastAppliedVelocity = NewVelocity;
    bHasRemoteState = true;
}

event Tick(float DeltaTime)
{
    local rotator R;
    local vector MoveDelta, TargetLoc, Forward, Right;
    local float MoveDist, Speed;

    super.Tick(DeltaTime);
    if (RemoteHero == None || Pawn != RemoteHero || !bHasRemoteState)
        return;

    TargetLoc = LastAppliedLocation;
    MoveDelta = TargetLoc - RemoteHero.Location;
    MoveDelta.Z = 0;
    MoveDist = VSize(MoveDelta);

    if (VSizeSq(LastAppliedVelocity) > 0.1)
    {
        Speed = VSize2D(LastAppliedVelocity);
        if (Speed >= MoveStopDistance)
            RemoteHero.DesiredMoveDirection = Normal(MoveDelta);
        else
            RemoteHero.DesiredMoveDirection = vect(0.0, 0.0, 0.0);
    }

    if (MoveDist > TeleportDistance)
    {
        RemoteHero.SetLocation(TargetLoc);
    }
    else
    {
        RemoteHero.SetLocation(VInterpTo(RemoteHero.Location, TargetLoc, DeltaTime, 12.0));
    }

    R = LastAppliedRotation;
    R.Pitch = 0;
    RemoteHero.SetRotation(R);
    RemoteHero.Velocity = LastAppliedVelocity;
    RemoteHero.Acceleration = LastAppliedVelocity;
}

DefaultProperties
{
    bAlwaysTick=true
    TeleportDistance=200.0
    MoveStopDistance=20.0
    RunSpeedThreshold=420.0
    TurnInterpolationTime=0.12
}
