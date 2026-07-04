class OLTogetherRemoteController extends AIController;

var OLTogetherRemoteHero RemoteHero;

function Possess(Pawn inPawn, bool bVehicleTransition)
{
    super.Possess(inPawn, bVehicleTransition);
    RemoteHero = OLTogetherRemoteHero(inPawn);
}

DefaultProperties
{
}
