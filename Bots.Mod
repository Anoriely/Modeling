MODULE Bots;
IMPORT Out, Random;

CONST
  (** World map size **)
  W* = 45;
  H* = 24;

  (** General world constants **)
  maxBots* = 64;
  genCount* = 64;
  commandCount* = 64;

  initHp* = 35;
  maxHp* = 100;
  addHp* = 10;
  mutantsPer8 = 2;

  initFood* = 60;
  initPoison* = 60;

  (** Possible values of map cells **)
  busy*   = -1; (** There is a bot on this cell *)
  wall*   = 0;
  empty*  = 1;
  food*   = 2;
  poison* = 3;

TYPE
  Bot* = RECORD (** A single bot *)
    gen*: ARRAY genCount OF INTEGER;
    pc*: INTEGER; (** Program counter, index in gen *)
    x*, y*: INTEGER; (** Position in map *)
    dir*: BYTE; (** Turn direction, 0..7 *)
    hp*: BYTE; (** Health points, >= 0 *)
    age*: INTEGER (** For how many steps did the bot stay alive *)
  END;

  World* = RECORD (** The whole world *)
    map*: ARRAY H, W OF INTEGER; (** See constants *)
    bots*: ARRAY maxBots OF Bot;
    botCount*: INTEGER (** Actual size of bots array *)
  END;

VAR
  world*: World;
  steps*: INTEGER; (** How many steps have passed since the beginning of the world *)
  foodEaten: INTEGER; (** How many items of food were eaten since the last step *)

(** Alters bot.pc depending on cell. Cell is the value of
    a map cell where bot is looking or where it went or
    grabbed.*)
PROCEDURE JumpPC(VAR bot: Bot; cell: INTEGER);
VAR n: INTEGER;
BEGIN
  IF    cell = poison THEN n := 1
  ELSIF cell = wall   THEN n := 2
  ELSIF cell = busy   THEN n := 3
  ELSIF cell = food   THEN n := 4
  ELSIF cell = empty  THEN n := 5
  ELSE ASSERT(FALSE)
  END;
  bot.pc := (bot.pc + n) MOD genCount
END JumpPC;

(** Grab cell (x; y) by the given bot. *)
PROCEDURE Grab(VAR bot: Bot; x, y: INTEGER);
VAR cell: INTEGER;
BEGIN
  cell := world.map[y, x];
  IF cell = food THEN
    world.map[y, x] := empty;
    INC(bot.hp, addHp);
    IF bot.hp > maxHp THEN bot.hp := maxHp END;
    INC(foodEaten)
  ELSIF cell = poison THEN
    world.map[y, x] := food
  END;
  JumpPC(bot, cell)
END Grab;

(** Teleport the given bot into (x; y). *)
PROCEDURE TryMove(VAR bot: Bot; x, y: INTEGER);
VAR cell: INTEGER;
BEGIN
  cell := world.map[y, x];
  IF (cell = empty) OR (cell = food) OR (cell = poison) THEN
    world.map[bot.y, bot.x] := empty;
    world.map[y, x] := busy;
    bot.x := x; bot.y := y;
    IF cell = food THEN
      INC(bot.hp, addHp);
      IF bot.hp > maxHp THEN bot.hp := maxHp END;
      INC(foodEaten)
    ELSIF cell = poison THEN
      bot.hp := 0
    END
  END;
  JumpPC(bot, cell)
END TryMove;

PROCEDURE DirToXY(dir: INTEGER; VAR x, y: INTEGER);
BEGIN
  dir := dir MOD 8;
  IF dir < 4 THEN
    IF    dir = 0 THEN x := -1; y := -1
    ELSIF dir = 1 THEN x :=  0; y := -1
    ELSIF dir = 2 THEN x :=  1; y := -1
    ELSE   (* = 3 *)   x :=  1; y :=  0
    END
  ELSE
    IF    dir = 4 THEN x :=  1; y :=  1
    ELSIF dir = 5 THEN x :=  0; y :=  1
    ELSIF dir = 6 THEN x :=  1; y :=  1
    ELSE   (* = 7 *)   x := -1; y :=  0
    END
  END
END DirToXY;

(** Make the given bot do a single step, n is the index
    of the bot in the world.bots array. *)
PROCEDURE ActBot(VAR bot: Bot; n: INTEGER);
VAR x, y: INTEGER;
  code, K: INTEGER; (* Current command code = gen[bot.pc] *)
  iter: INTEGER; (* Iteration counter *)
  quit: BOOLEAN;
BEGIN
  DEC(bot.hp);
  iter := 0; quit := FALSE;
  REPEAT
    code := bot.gen[bot.pc];
    IF code < 32 THEN
      DirToXY(bot.dir + code, x, y);
      INC(x, bot.x); INC(y, bot.y);
      K := code DIV 8;
      IF K = 0 THEN (* code = 0..7 -- move *)
        TryMove(bot, x, y);
        quit := TRUE
      ELSIF K = 1 THEN (* code = 8..15 -- grab *)
        Grab(bot, x, y);
        quit := TRUE
      ELSIF K = 2 THEN (* code = 16..23 -- look *)
        JumpPC(bot, world.map[y, x])
      ELSE (* K = 3, code = 24..31 -- turn *)
        bot.dir := (bot.dir + code) MOD 8;
        bot.pc := (bot.pc + 1) MOD genCount
      END
    ELSE (* code = 32..63 *)
      IF code < 48 THEN DEC(code, 48) ELSE DEC(code, 47) END;
      (* code = -16..-1, 1..16 *)
      bot.pc := (bot.pc + code) MOD genCount
    END;
    INC(iter)
  UNTIL quit OR (iter = 64)
END ActBot;

(** Delete nth bot from world.bots by replacing it with the
    last bot (if it itself is not the last bot),
    decrease world.botCount by 1. *)
PROCEDURE DeleteBot(VAR bot: Bot; n: INTEGER);
VAR tmp: Bot;
BEGIN
  bot.age := steps;
  world.map[bot.y, bot.x] := empty;
  DEC(world.botCount);
  IF n # world.botCount THEN
    (* Swap dead bot with the last one alive *)
    tmp := bot;
    world.bots[n] := world.bots[world.botCount];
    world.bots[world.botCount] := tmp
  END;
END DeleteBot;

PROCEDURE PlaceItem(value: BYTE);
VAR x, y: INTEGER;
BEGIN
  REPEAT
    x := Random.Int(W);
    y := Random.Int(H)
  UNTIL world.map[y, x] = empty;
  world.map[y, x] := value
END PlaceItem;

PROCEDURE PlaceItems(foodCount, poisonCount: INTEGER);
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO foodCount - 1 DO PlaceItem(food) END;
  FOR i := 0 TO poisonCount - 1 DO PlaceItem(poison) END
END PlaceItems;

(** Make each bot do a single step *)
PROCEDURE ActWorld*;
VAR i: INTEGER;
BEGIN
  i := 0;
  foodEaten := 0;
  WHILE i # world.botCount DO
    ActBot(world.bots[i], i);
    IF world.bots[i].hp = 0 THEN
      DeleteBot(world.bots[i], i)
    ELSE
      INC(i)
    END
  END;
  WHILE foodEaten # 0 DO
    IF Random.Int(2) = 0 THEN
      PlaceItem(food)
    ELSE
      PlaceItem(poison)
    END;
    DEC(foodEaten)
  END;
  INC(steps)
END ActWorld;

PROCEDURE MapRect(x1, y1, x2, y2: INTEGER; value: BYTE);
VAR x, y: INTEGER;
BEGIN
  FOR y := y1 TO y2 DO
    FOR x := x1 TO x2 DO
      world.map[y, x] := value
    END
  END
END MapRect;

PROCEDURE MakeMap;
BEGIN
  MapRect(1, 1, W - 2, H - 2, empty);

  (* 4 walls *)
  MapRect(0, 0, W - 1, 0, wall);
  MapRect(0, H - 1, W - 1, H - 1, wall);
  MapRect(0, 0, 0, H - 1, wall);
  MapRect(W - 1, 0, W - 1, H - 1, wall);

  (* auxilary walls *)
  MapRect(W * 2 DIV 9, 1, W * 2 DIV 9, H * 5 DIV 12, wall);
  MapRect(W DIV 2, H DIV 3, W DIV 2, H * 2 DIV 3, wall);
  (*MapRect(5, H - 4, W - 1, H - 4, wall)*)
END MakeMap;

(** Randomize gen for the given bot. *)
PROCEDURE MakeRandomBot(VAR bot: Bot);
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO genCount - 1 DO
    bot.gen[i] := Random.Int(commandCount)
  END
END MakeRandomBot;

(** Create maxBots bots with random gens. *)
PROCEDURE MakeRandomBots;
VAR i: INTEGER;
BEGIN
  world.botCount := maxBots;
  FOR i := 0 TO maxBots - 1 DO
    MakeRandomBot(world.bots[i])
  END
END MakeRandomBots;

PROCEDURE MutateBot(VAR bot: Bot; mutations: INTEGER);
BEGIN
  WHILE mutations # 0 DO
    bot.gen[Random.Int(genCount)] := Random.Int(commandCount);
    DEC(mutations)
  END
END MutateBot;

PROCEDURE MakeNewBots;
VAR i, j: INTEGER;
BEGIN
  FOR i := 0 TO 7 DO
    FOR j := 8 + i TO maxBots - 1 BY 8 DO
      world.bots[j] := world.bots[i]
    END;
    FOR j := 0 TO mutantsPer8 - 1 DO
      MutateBot(world.bots[i + j * 8], j + 1)
    END
  END;
  world.botCount := maxBots
END MakeNewBots;

PROCEDURE PlaceBot(VAR bot: Bot);
BEGIN
  REPEAT
    bot.x := Random.Int(W);
    bot.y := Random.Int(H);
  UNTIL world.map[bot.y, bot.x] = empty;
  world.map[bot.y, bot.x] := busy;
  bot.dir := Random.Int(8);
  bot.hp := initHp;
  bot.age := 0;
  bot.pc := 0
END PlaceBot;

PROCEDURE PlaceBots;
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO maxBots - 1 DO
    PlaceBot(world.bots[i])
  END
END PlaceBots;

PROCEDURE InitWorld*;
BEGIN
  steps := 0;
  MakeMap;
  MakeRandomBots;
  PlaceBots;
  PlaceItems(initFood, initPoison)
END InitWorld;

(** Regenerate the world *)
PROCEDURE Regen*;
BEGIN
  steps := 0;
  MakeMap;
  MakeNewBots;
  PlaceBots;
  PlaceItems(initFood, initPoison)
END Regen;

PROCEDURE Init*;
BEGIN
  InitWorld
END Init;

END Bots.