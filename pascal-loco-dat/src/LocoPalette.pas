{
  LocoPalette.pas

  The fixed 256-colour palette Locomotion and OpenLoco render everything
  through. Every sprite pixel byte is an index (0..255) into this table.
  Transcribed directly from the user-supplied loco_color_palette.php (256
  RGB triples, index 0 = black, matching the in-game/G1 palette order).

  Used by LocoSprite.pas to convert between raw palette-index pixel data
  (as stored in a .DAT object's image table) and 24-bit RGB / PNG.

  Part of the LocoDat Pascal library.
}
unit LocoPalette;

{$mode delphi}{$H+}

interface

type
  TLocoRGB = packed record
    R, G, B: Byte;
  end;

const
  kLocoPaletteSize = 256;

  { Index -> RGB. LocoPalette[i] is the display colour for palette index i. }
  LocoPalette: array[0..255] of TLocoRGB = (
    (R:0;G:0;B:0), (R:0;G:229;B:0), (R:0;G:204;B:0), (R:0;G:179;B:0), // 0..3
    (R:0;G:153;B:0), (R:0;G:128;B:0), (R:0;G:102;B:0), (R:15;G:11;B:19), // 4..7
    (R:36;G:27;B:45), (R:57;G:42;B:70), (R:23;G:35;B:35), (R:35;G:51;B:51), // 8..11
    (R:47;G:67;B:67), (R:63;G:83;B:83), (R:75;G:99;B:99), (R:91;G:115;B:115), // 12..15
    (R:111;G:131;B:131), (R:131;G:151;B:151), (R:159;G:175;B:175), (R:183;G:195;B:195), // 16..19
    (R:211;G:219;B:219), (R:239;G:243;B:243), (R:51;G:47;B:0), (R:63;G:59;B:0), // 20..23
    (R:79;G:75;B:11), (R:91;G:91;B:19), (R:107;G:107;B:31), (R:119;G:123;B:47), // 24..27
    (R:135;G:139;B:59), (R:151;G:155;B:79), (R:167;G:175;B:95), (R:187;G:191;B:115), // 28..31
    (R:203;G:207;B:139), (R:223;G:227;B:163), (R:67;G:43;B:7), (R:87;G:59;B:11), // 32..35
    (R:111;G:75;B:23), (R:127;G:87;B:31), (R:143;G:99;B:39), (R:159;G:115;B:51), // 36..39
    (R:179;G:131;B:67), (R:191;G:151;B:87), (R:203;G:175;B:111), (R:219;G:199;B:135), // 40..43
    (R:231;G:219;B:163), (R:247;G:239;B:195), (R:71;G:27;B:0), (R:95;G:43;B:0), // 44..47
    (R:119;G:63;B:0), (R:143;G:83;B:7), (R:167;G:111;B:7), (R:191;G:139;B:15), // 48..51
    (R:215;G:167;B:19), (R:243;G:203;B:27), (R:255;G:231;B:47), (R:255;G:243;B:95), // 52..55
    (R:255;G:251;B:143), (R:255;G:255;B:195), (R:35;G:0;B:0), (R:79;G:0;B:0), // 56..59
    (R:95;G:7;B:7), (R:111;G:15;B:15), (R:127;G:27;B:27), (R:143;G:39;B:39), // 60..63
    (R:163;G:59;B:59), (R:179;G:79;B:79), (R:199;G:103;B:103), (R:215;G:127;B:127), // 64..67
    (R:235;G:159;B:159), (R:255;G:191;B:191), (R:27;G:51;B:19), (R:35;G:63;B:23), // 68..71
    (R:47;G:79;B:31), (R:59;G:95;B:39), (R:71;G:111;B:43), (R:87;G:127;B:51), // 72..75
    (R:99;G:143;B:59), (R:115;G:155;B:67), (R:131;G:171;B:75), (R:147;G:187;B:83), // 76..79
    (R:163;G:203;B:95), (R:183;G:219;B:103), (R:31;G:55;B:27), (R:47;G:71;B:35), // 80..83
    (R:59;G:83;B:43), (R:75;G:99;B:55), (R:91;G:111;B:67), (R:111;G:135;B:79), // 84..87
    (R:135;G:159;B:95), (R:159;G:183;B:111), (R:183;G:207;B:127), (R:195;G:219;B:147), // 88..91
    (R:207;G:231;B:167), (R:223;G:247;B:191), (R:15;G:63;B:0), (R:19;G:83;B:0), // 92..95
    (R:23;G:103;B:0), (R:31;G:123;B:0), (R:39;G:143;B:7), (R:55;G:159;B:23), // 96..99
    (R:71;G:175;B:39), (R:91;G:191;B:63), (R:111;G:207;B:87), (R:139;G:223;B:115), // 100..103
    (R:163;G:239;B:143), (R:195;G:255;B:179), (R:79;G:43;B:19), (R:99;G:55;B:27), // 104..107
    (R:119;G:71;B:43), (R:139;G:87;B:59), (R:167;G:99;B:67), (R:187;G:115;B:83), // 108..111
    (R:207;G:131;B:99), (R:215;G:151;B:115), (R:227;G:171;B:131), (R:239;G:191;B:151), // 112..115
    (R:247;G:207;B:171), (R:255;G:227;B:195), (R:15;G:19;B:55), (R:39;G:43;B:87), // 116..119
    (R:51;G:55;B:103), (R:63;G:67;B:119), (R:83;G:83;B:139), (R:99;G:99;B:155), // 120..123
    (R:119;G:119;B:175), (R:139;G:139;B:191), (R:159;G:159;B:207), (R:183;G:183;B:223), // 124..127
    (R:211;G:211;B:239), (R:239;G:239;B:255), (R:0;G:27;B:111), (R:0;G:39;B:151), // 128..131
    (R:7;G:51;B:167), (R:15;G:67;B:187), (R:27;G:83;B:203), (R:43;G:103;B:223), // 132..135
    (R:67;G:135;B:227), (R:91;G:163;B:231), (R:119;G:187;B:239), (R:143;G:211;B:243), // 136..139
    (R:175;G:231;B:251), (R:215;G:247;B:255), (R:11;G:43;B:15), (R:15;G:55;B:23), // 140..143
    (R:23;G:71;B:31), (R:35;G:83;B:43), (R:47;G:99;B:59), (R:59;G:115;B:75), // 144..147
    (R:79;G:135;B:95), (R:99;G:155;B:119), (R:123;G:175;B:139), (R:147;G:199;B:167), // 148..151
    (R:175;G:219;B:195), (R:207;G:243;B:223), (R:63;G:0;B:95), (R:75;G:7;B:114), // 152..155
    (R:83;G:15;B:126), (R:95;G:31;B:142), (R:107;G:43;B:154), (R:123;G:63;B:170), // 156..159
    (R:135;G:83;B:186), (R:155;G:103;B:198), (R:171;G:127;B:214), (R:191;G:155;B:230), // 160..163
    (R:215;G:195;B:240), (R:243;G:235;B:254), (R:63;G:0;B:0), (R:87;G:0;B:0), // 164..167
    (R:115;G:0;B:0), (R:143;G:0;B:0), (R:171;G:0;B:0), (R:199;G:0;B:0), // 168..171
    (R:227;G:7;B:0), (R:255;G:7;B:0), (R:255;G:79;B:67), (R:255;G:123;B:115), // 172..175
    (R:255;G:171;B:163), (R:255;G:219;B:215), (R:79;G:39;B:0), (R:111;G:51;B:0), // 176..179
    (R:147;G:63;B:0), (R:183;G:71;B:0), (R:219;G:79;B:0), (R:255;G:83;B:0), // 180..183
    (R:255;G:111;B:23), (R:255;G:139;B:51), (R:255;G:163;B:79), (R:255;G:183;B:107), // 184..187
    (R:255;G:203;B:135), (R:255;G:219;B:163), (R:0;G:51;B:47), (R:0;G:63;B:55), // 188..191
    (R:26;G:63;B:67), (R:42;G:81;B:86), (R:58;G:99;B:105), (R:74;G:118;B:124), // 192..195
    (R:90;G:136;B:143), (R:107;G:155;B:163), (R:132;G:180;B:186), (R:157;G:205;B:209), // 196..199
    (R:182;G:230;B:232), (R:207;G:255;B:255), (R:63;G:0;B:27), (R:103;G:0;B:51), // 200..203
    (R:123;G:11;B:63), (R:143;G:23;B:79), (R:163;G:31;B:95), (R:183;G:39;B:111), // 204..207
    (R:219;G:59;B:143), (R:239;G:91;B:171), (R:243;G:119;B:187), (R:247;G:151;B:203), // 208..211
    (R:251;G:183;B:223), (R:255;G:215;B:239), (R:39;G:19;B:0), (R:55;G:31;B:7), // 212..215
    (R:71;G:47;B:15), (R:91;G:63;B:31), (R:107;G:83;B:51), (R:123;G:103;B:75), // 216..219
    (R:143;G:127;B:107), (R:163;G:147;B:127), (R:187;G:171;B:147), (R:207;G:195;B:171), // 220..223
    (R:231;G:219;B:195), (R:255;G:243;B:223), (R:55;G:75;B:75), (R:255;G:183;B:0), // 224..227
    (R:255;G:219;B:0), (R:255;G:255;B:0), (R:64;G:47;B:0), (R:91;G:66;B:0), // 228..231
    (R:118;G:86;B:0), (R:145;G:107;B:0), (R:173;G:126;B:0), (R:200;G:146;B:0), // 232..235
    (R:227;G:167;B:0), (R:255;G:187;B:0), (R:255;G:201;B:51), (R:255;G:214;B:102), // 236..239
    (R:67;G:91;B:91), (R:83;G:107;B:107), (R:99;G:123;B:123), (R:255;G:228;B:153), // 240..243
    (R:255;G:242;B:204), (R:0;G:255;B:0), (R:77;G:57;B:96), (R:98;G:73;B:121), // 244..247
    (R:118;G:88;B:147), (R:139;G:108;B:167), (R:159;G:134;B:182), (R:179;G:159;B:198), // 248..251
    (R:199;G:185;B:213), (R:220;G:210;B:228), (R:240;G:236;B:244), (R:0;G:0;B:255) // 252..255
  );

{ Nearest-colour lookup: returns the palette index whose RGB is closest
  (least squared error) to the given colour. Used when importing a PNG
  that is not already indexed with exactly LocoPalette's colours (e.g. a
  plain RGB/RGBA PNG, or an indexed PNG using a different palette order). }
function FindNearestPaletteIndex(R, G, B: Byte): Byte;

{ Exact lookup: returns the palette index whose RGB exactly matches, or
  -1 if no exact match exists (caller should fall back to
  FindNearestPaletteIndex in that case). }
function FindExactPaletteIndex(R, G, B: Byte): Integer;

implementation

function FindNearestPaletteIndex(R, G, B: Byte): Byte;
var
  i: Integer;
  dr, dg, db: Integer;
  dist, bestDist: Integer;
  bestIndex: Integer;
begin
  bestIndex := 0;
  bestDist := MaxInt;
  for i := 0 to High(LocoPalette) do
  begin
    dr := Integer(R) - Integer(LocoPalette[i].R);
    dg := Integer(G) - Integer(LocoPalette[i].G);
    db := Integer(B) - Integer(LocoPalette[i].B);
    dist := dr * dr + dg * dg + db * db;
    if dist < bestDist then
    begin
      bestDist := dist;
      bestIndex := i;
      if dist = 0 then
        Break;
    end;
  end;
  Result := Byte(bestIndex);
end;

function FindExactPaletteIndex(R, G, B: Byte): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(LocoPalette) do
  begin
    if (LocoPalette[i].R = R) and (LocoPalette[i].G = G) and (LocoPalette[i].B = B) then
    begin
      Result := i;
      Break;
    end;
  end;
end;

end.
