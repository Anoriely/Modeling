MODULE ModelingLog;
IMPORT Texts, Out, Bots;

VAR W: Texts.Writer;

PROCEDURE EndGeneration*(generationNum: INTEGER; world: Bots.World);
VAR i: INTEGER;
BEGIN
  Texts.WriteString(W, 'Gen ');
  Texts.WriteInt(W, generationNum, 0);
  Texts.WriteString(W, ': ');
  Texts.WriteInt(W, Bots.steps, 0); Texts.WriteLn(W);
  FOR i := 0 TO Bots.genCount - 1 DO
    Texts.WriteInt(W, world.bots[0].gen[i], 3)
  END;
  Texts.WriteLn(W)
END EndGeneration;

PROCEDURE Close*;
VAR T: Texts.Text;
BEGIN
  NEW(T);
  Texts.Open(T, '');
  Texts.Append(T, W.buf);
  Texts.Close(T, 'log.txt')
END Close;

PROCEDURE Init*;
BEGIN
  Texts.OpenWriter(W)
END Init;

END ModelingLog.