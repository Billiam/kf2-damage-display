// Written by Marco
Class DmgMut extends KFMutator;

struct FPairedUser
{
	var Controller User;
	var DmgRep Rep;
};
var transient array<FPairedUser> Users;
var transient FPairedUser CacheUser;

var transient Pawn LastHitPawn;
var transient int LastHitHP;
var transient vector LastDamagePosition;
var transient PlayerController LastDamageInstigator;

function PostBeginPlay()
{
	if( WorldInfo.Game.BaseMutator==None )
		WorldInfo.Game.BaseMutator = Self;
	else WorldInfo.Game.BaseMutator.AddMutator(Self);
}
function AddMutator(Mutator M)
{
	if( M!=Self ) // Make sure we don't get added twice.
	{
		if( M.Class==Class )
			M.Destroy();
		else Super.AddMutator(M);
	}
}

function NotifyLogout(Controller Exiting)
{
	local int i;
	
	if( PlayerController(Exiting)!=None )
	{
		i = Users.Find('User',Exiting);
		if( i>=0 )
		{
			Users[i].Rep.Destroy();
			Users.Remove(i,1);
		}
	}
	Super.NotifyLogout(Exiting);
}

function NotifyLogin(Controller NewPlayer)
{
	local int i;

	Super.NotifyLogin(NewPlayer);
	if( PlayerController(NewPlayer)!=None && PlayerController(NewPlayer).Player!=None )
	{
		i = Users.Length;
		Users.Length = i+1;
		Users[i].User = NewPlayer;
		Users[i].Rep = Spawn(class'DmgRep',NewPlayer);
	}
}

final function CleanupUsers()
{
	local int i;
	
	for( i=0; i<Users.Length; ++i )
	{
		if( Users[i].Rep!=None )
			Users[i].Rep.Destroy();
	}
	Users.Length = 0;
}

function GetSeamlessTravelActorList(bool bToEntry, out array<Actor> ActorList)
{
	// Cleanup all now!
	CleanupUsers();
	Super.GetSeamlessTravelActorList(bToEntry, ActorList);
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	if (NextMutator != None)
		NextMutator.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
	
	if( LastDamageInstigator!=None )
	{
		ClearTimer('CheckDamageDone');
		CheckDamageDone();
	}
	
	if( PlayerController(InstigatedBy)!=None && Injured!=None && InstigatedBy.Pawn!=Injured && Injured.Health>0 )
	{
		// Must delay this until next to get accurate damage dealt result.
		LastHitPawn = Injured;
		LastHitHP = Injured.Health;
		LastDamagePosition = HitLocation;
		LastDamageInstigator = PlayerController(InstigatedBy);
		SetTimer(0.001,false,'CheckDamageDone');
	}
}
function CheckDamageDone()
{
	local int i;

	if( LastDamageInstigator!=None )
	{
		if( CacheUser.User!=LastDamageInstigator )
		{
			CacheUser.User = LastDamageInstigator;
			i = Users.Find('User',LastDamageInstigator);
			if( i>=0 )
				CacheUser.Rep = Users[i].Rep;
			else CacheUser.Rep = None;
		}
		if( CacheUser.Rep!=None )
		{
			if( LastHitPawn!=None )
				i = LastHitHP - Max(LastHitPawn.Health,0);
			else i = LastHitHP;
			CacheUser.Rep.ClientPopupMessage(i,LastDamagePosition,0);
		}
		LastDamageInstigator = None;
	}
}

defaultproperties
{
   Begin Object Class=SpriteComponent Name=DmgSprite Archetype=SpriteComponent'KFGame.Default__KFMutator:Sprite'
      SpriteCategoryName="Info"
      ReplacementPrimitive=None
      HiddenGame=True
      AlwaysLoadOnClient=False
      AlwaysLoadOnServer=False
      Name="DmgSprite"
      ObjectArchetype=SpriteComponent'KFGame.Default__KFMutator:Sprite'
   End Object
   Components(0)=DmgSprite
   Name="Default__DmgMut"
   ObjectArchetype=KFMutator'KFGame.Default__KFMutator'
}
