MODULE Visual;
IMPORT G := Graph, Bots, Out, Int;

CONST
  esc = CHR(27); (** Escape key *)
  delay = 90; (** Delay between frames in ms *)
  framesToSkip = 5000000; (** How many frames to skip when space pressed *)
  fontFname = 'Data/Fonts/Main'; (** Name of the bitmap file with the font *)
  cellSize = 32;

VAR
  quit*: BOOLEAN; (** TRUE when user wants to quit *)
  skipFrames: INTEGER;

  (** Colors **)
  cWall, cFood, cPoison: G.Color;
  cError, white, grey, black, pink: G.Color;

  (** Coordinates of drawable interface **)
  X, Y: INTEGER; (** Map offset *)
  font: G.Font;

PROCEDURE DrawRect(x, y: INTEGER; color: G.Color);
BEGIN
  x := x * cellSize;
  y := y * cellSize;
  G.FillRect(x + 1, y + 1, x + cellSize - 1, y + cellSize - 1, color)
END DrawRect;

PROCEDURE DrawCell(x, y, cell: INTEGER);
BEGIN
  IF cell # Bots.empty THEN
    IF cell = Bots.wall THEN
      DrawRect(x, y, cWall)
    ELSIF cell = Bots.food THEN
      DrawRect(x, y, cFood)
    ELSIF cell = Bots.poison THEN
      DrawRect(x, y, cPoison)
    ELSE (* Impossible *)
      (*DrawRect(x, y, cError)*)
    END
  END
END DrawCell;

PROCEDURE DrawMap(world: Bots.World);
VAR x, y: INTEGER;
BEGIN
  FOR y := 0 TO LEN(world.map) - 1 DO
    FOR x := 0 TO LEN(world.map[0]) - 1 DO
      DrawCell(x, y, world.map[y, x])
    END
  END
END DrawMap;

PROCEDURE DrawBot(bot: Bots.Bot);
CONST mid = Bots.maxHp DIV 4; (* middle point *)
      max = Bots.maxHp; (* maximum health *)
VAR c: G.Color;
  r, g, x, y: INTEGER;
  s: ARRAY 3 OF CHAR;
BEGIN
  IF bot.hp < mid THEN
    r := 255 - bot.hp * 255 DIV mid;
    IF r > 255 THEN r := 255 END;
    g := r
  ELSE
    g := 0;
    r := (bot.hp - mid) * 255 DIV (max - mid);
    IF r > 255 THEN r := 255 END
  END;
  G.MakeCol(c, r, g, 255);
  x := bot.x * cellSize;
  y := bot.y * cellSize;
  G.FillRect(x + 1, y + 1, x + cellSize - 1, y + cellSize - 1, c);

  IF bot.hp >= 100 THEN s := '00' ELSE Int.Str(bot.hp, s) END;
  INC(x, cellSize DIV 2 + 1);
  IF bot.hp < 10 THEN DEC(x, 4) ELSE DEC(x, 8) END;
  IF (mid DIV 2 < bot.hp) & (bot.hp < mid * 3) THEN c := white ELSE c := black END;
  G.DrawString(s, x, y + ((cellSize - 16) DIV 2 + 2), font, c)
END DrawBot;

PROCEDURE DrawBots(world: Bots.World);
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO world.botCount - 1 DO
    DrawBot(world.bots[i])
  END
END DrawBots;

PROCEDURE DrawNet;
VAR x, y: INTEGER;
BEGIN
  FOR x := 0 TO Bots.W * cellSize BY cellSize DO
    G.VLine(x, 0, Bots.H * cellSize, grey)
  END;
  FOR y := 0 TO Bots.H * cellSize BY cellSize DO
    G.HLine(0, y, Bots.W * cellSize, grey)
  END
END DrawNet;

PROCEDURE Draw*(world: Bots.World);
BEGIN
  IF skipFrames = 0 THEN
    G.ClearScreen;
    DrawNet;
    DrawMap(world);
    DrawBots(world);
    G.Flip;
    G.Delay(delay)
  ELSE
    DEC(skipFrames)
  END
END Draw;

PROCEDURE Update*(world: Bots.World);
VAR ch: CHAR;
BEGIN
  Draw(world);
  IF G.KeyPressed() THEN
    ch := G.ReadKey();
    IF ch = esc THEN
      quit := TRUE
    ELSIF ch = ' ' THEN
      INC(skipFrames, framesToSkip)
    END
  END
END Update;

(** Closes the graphical interface. *)
PROCEDURE Close*;
BEGIN
  G.Close
END Close;

PROCEDURE MakeColors;
BEGIN
  G.MakeCol(black, 0, 0, 0);
  G.MakeCol(white, 255, 255, 255);
  G.MakeCol(grey, 50, 50, 50);
  G.MakeCol(pink, 255, 0, 180);
  G.MakeCol(cWall, 100, 100, 100);
  G.MakeCol(cFood, 10, 80, 10);
  G.MakeCol(cPoison, 96, 10, 5);
  G.MakeCol(cError, 120, 80, 0)
END MakeColors;

PROCEDURE LoadFont(): BOOLEAN;
BEGIN
  font := G.LoadFont(fontFname);
  IF font = NIL THEN
    Out.String('Could not load font '); Out.String(fontFname); Out.Ln
  END
RETURN font # NIL END LoadFont;

(** Initializes graphical visualization
    and returns TRUE on success, sets quit
    global variable to FALSE.
    On error returns FALSE. *)
PROCEDURE Init*(): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
  ok := FALSE;
  quit := FALSE;
  skipFrames := 0;
  G.Settings(Bots.W * cellSize + 1, Bots.H * cellSize + 1, {G.exact});
  G.Init;
  IF ~G.Done THEN
    Out.String('Could not initialize Graph.');
    Out.Ln
  ELSE
    ok := LoadFont();
    MakeColors
  END
RETURN ok END Init;

END Visual.