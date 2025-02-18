Class DmgHUD extends Interaction;

var transient PlayerController LocalOwner;
var transient vector PLCameraLoc,PLCameraDir;
var transient rotator PLCameraRot;

const Duration = 1.f;

struct FNumberedMsg
{
	var int Amount;
	var vector Pos;
	var vector Vel;
	var float Time;
};
var transient array<FNumberedMsg> Numbers;
var transient float RenderTime;

function PostRender(Canvas Canvas)
{
	local float Dt;

	if (RenderTime > 0) {
		Dt = LocalOwner.WorldInfo.TimeSeconds - RenderTime;
	}
	RenderTime = LocalOwner.WorldInfo.TimeSeconds;

	if( Numbers.Length>0 )
		DrawNumberMsg(Canvas, Dt);
}

final function AddNumberMsg( int Amount, vector Pos )
{
	local vector velocity;
	local int i;

	i = Numbers.Length;
	while( i>18 ) // don't overflow this that much...
	{
		Numbers.Remove(0,1);
		i = Numbers.Length;
	}

	velocity = vect(0, 0, 0);
	velocity.X = FRand() * 400.f - 200.f;
	velocity.Y = FRand() * 400.f - 200.f;
	velocity.Z = FRand() * 200.f + 150.f;

	Numbers.Length = i+1;
	Numbers[i].Vel = velocity;
	Numbers[i].Amount = Amount;
	Numbers[i].Pos = Pos;
	Numbers[i].Time = LocalOwner.WorldInfo.TimeSeconds;
}

final function DrawNumberMsg( Canvas Canvas, float Dt )
{
	local int i;
	local float T,FontScale,XS,YS,CameraDot,AnimPercent,Dist,RenderSize;
	local vector V;
	local string S;

	LocalOwner.GetPlayerViewPoint(PLCameraLoc,PLCameraRot);
	PLCameraDir = vector(PLCameraRot);
	CameraDot = (PLCameraDir Dot PLCameraLoc);

	FontScale = Canvas.ClipY / 800.f;
	Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

	for( i=Numbers.length - 1; i>=0; i-- )
	{
		T = LocalOwner.WorldInfo.TimeSeconds - Numbers[i].Time;

		if( T>Duration )
		{
			Numbers.remove(i, 1);
			continue;
		}

		AnimPercent = T/Duration;
		V = Numbers[i].Pos;

		Dist = (PLCameraDir Dot V) - CameraDot;

		if( Dist > 0.f )
		{
			V = Canvas.Project(V);
			if( V.X>0 && V.Y>0 && V.X<Canvas.ClipX && V.Y<Canvas.ClipY )
			{
				RenderSize = FontScale - (FMin(Dist, 1500.f) / 1500.f) * FontScale * 0.5;

				if( Numbers[i].Amount<0 )
					S = "+"$string(-Numbers[i].Amount);
				else S = string(Numbers[i].Amount);

				Canvas.SetDrawColor(0, 0, 0, 204);
				if(AnimPercent > 0.7 )
					Canvas.DrawColor.A = (1-AnimPercent)/0.3*204.f;
				Canvas.TextSize(S,XS,YS,RenderSize,RenderSize);
				Canvas.SetPos(V.X-XS*0.5 + 1,V.Y-YS*0.5 + 1);
				Canvas.DrawText(S,,RenderSize,RenderSize);

				if( Numbers[i].Amount==0 )
					Canvas.SetDrawColor(220,0,0,204);
				else if( Numbers[i].Amount<0 )
					Canvas.SetDrawColor(15,255,15,204);
				else Canvas.SetDrawColor(240,240,240,204);

				if( AnimPercent > 0.7 )
					Canvas.DrawColor.A = (1-AnimPercent)/0.3*204.f;
				Canvas.SetPos(V.X-XS*0.5,V.Y-YS*0.5);
				Canvas.DrawText(S,,RenderSize,RenderSize);
			}
		}

		Numbers[i].Pos += Numbers[i].Vel * Dt;
		Numbers[i].Vel.Z -= 700.f * Dt;
	}
}

defaultproperties
{
   Name="Default__DmgHUD"
   ObjectArchetype=Interaction'Engine.Default__Interaction'
}
