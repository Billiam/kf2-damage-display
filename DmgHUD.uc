Class DmgHUD extends Interaction;

var transient PlayerController LocalOwner;
var transient vector PLCameraLoc,PLCameraDir;
var transient rotator PLCameraRot;

struct FNumberedMsg
{
	var int Amount;
	var vector Pos;
	var vector Vel;
	var float Time;
	var byte Type;
};
var transient array<FNumberedMsg> Numbers;

function PostRender(Canvas Canvas)
{
	if( Numbers.Length>0 )
		DrawNumberMsg(Canvas);
}

final function AddNumberMsg( int Amount, vector Pos, byte Type )
{
	local int i;
	local vector velocity;

	i = Numbers.Length;
	if( i>18 ) // don't overflow this that much...
	{
		Numbers.Remove(0,1);
		i = Numbers.Length;
	}
	velocity = vect(0, 0, 0);
	velocity.X = FRand() * 200.f - 100.f;
	velocity.Y = FRand() * 200.f - 100.f;
	velocity.Z = FRand() * 200.f + 80.f;

	Numbers.Length = i+1;
	Numbers[i].Vel = velocity;
	Numbers[i].Amount = Amount;
	Numbers[i].Pos = Pos;
	Numbers[i].Time = LocalOwner.WorldInfo.TimeSeconds;
	Numbers[i].Type = Type;
}
final function DrawNumberMsg( Canvas Canvas )
{
	local int i;
	local float T,ThisDot,FontScale,XS,YS,CameraDot;
	local vector V;
	local string S;

	LocalOwner.GetPlayerViewPoint(PLCameraLoc,PLCameraRot);
	PLCameraDir = vector(PLCameraRot);
	CameraDot = (PLCameraDir Dot PLCameraLoc);

	FontScale = Canvas.ClipY / 2.f;
	Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

	for( i=0; i<Numbers.Length; ++i )
	{
		T = LocalOwner.WorldInfo.TimeSeconds-Numbers[i].Time;
		if( T>1.f )
		{
			Numbers.Remove(i--,1);
			continue;
		}
		V = Numbers[i].Pos+Numbers[i].Vel*T;
		Numbers[i].Vel.Z -= 3.f*T;
		ThisDot = (PLCameraDir Dot V) - CameraDot;
		if( ThisDot>0.f && ThisDot<1500.f )
		{
			V = Canvas.Project(V);
			if( V.X>0 && V.Y>0 && V.X<Canvas.ClipX && V.Y<Canvas.ClipY )
			{
				ThisDot = (FontScale/ThisDot);
				switch( Numbers[i].Type )
				{
				case 0: // Pawn damage.
					if( Numbers[i].Amount<0 )
						S = "+"$string(-Numbers[i].Amount);
					else S = string(Numbers[i].Amount);
					if( Numbers[i].Amount==0 )
						Canvas.SetDrawColor(220,0,0,255);
					else if( Numbers[i].Amount<0 )
						Canvas.SetDrawColor(15,255,15,255);
					else Canvas.SetDrawColor(220,220,220,255);
					break;
				}
				if( T>0.7 )
					Canvas.DrawColor.A = (1.f-T)*255.f;
				Canvas.TextSize(S,XS,YS,ThisDot,ThisDot);
				Canvas.SetPos(V.X-XS*0.5,V.Y-YS*0.5);
				Canvas.DrawText(S,,ThisDot,ThisDot);
			}
		}
	}
}

defaultproperties
{
   Name="Default__DmgHUD"
   ObjectArchetype=Interaction'Engine.Default__Interaction'
}
