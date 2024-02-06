MODULE Modeling;
IMPORT Bots, Visual, Log := ModelingLog;

CONST
  aliveLimit = 8; (** When bot count is <= this value, regenerate *)

PROCEDURE Run;
VAR generations: INTEGER;
BEGIN
  generations := 0;
  REPEAT
    REPEAT
      Bots.ActWorld;
      Visual.Update(Bots.world) (* Maybe sets Visual.quit *)
    UNTIL Visual.quit OR (Bots.world.botCount <= aliveLimit);
    Log.EndGeneration(generations, Bots.world);
    Bots.Regen;
    INC(generations)
  UNTIL Visual.quit
END Run;

BEGIN
  Log.Init;
  IF Visual.Init() THEN
    Bots.Init;
    Run;
    Visual.Close
  END;
  Log.Close
END Modeling.