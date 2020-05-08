(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE StdDlg;


PROCEDURE DriveValid( Drive: CHAR): BOOLEAN;
VAR
  r : Registers;
BEGIN
  r.AX := 30H;
  Dos( r ); (* Dos version *)
  IF r.AL >= 3 THEN
    r.AX := 04408H;
    r.BL := SHORTCARD( Drive ) - (SHORTCARD('A')-1);
    Dos( r );
    IF NOT (CarryFlag IN r.Flags) THEN
      RETURN TRUE;
    END;
  END;
  r.AH := 36H;
  r.DL := SHORTCARD( Drive ) - (SHORTCARD('A')-1);
  Dos( r );
  RETURN r.AX # 0FFFFH;
END DriveValid;

PROCEDURE PathValid(VAR Path: ARRAY OF CHAR): BOOLEAN;
VAR
  ExpPath: PathStr;
  F: File;
  SR: SearchRec;
BEGIN
  ExpPath := FExpand(Path);
  IF Length(ExpPath) <= 3 THEN
    RETURN DriveValid(ExpPath[1])
  ELSE
    IF ExpPath[Length(ExpPath)] = '\' THEN
      DEC(ExpPath[0]);
    END;
    FindFirst(ExpPath, Directory, SR);
    RETURN (DosError = 0) & (SR.Attr & Directory <> 0);
  END;
END PathValid;

PROCEDURE ValidFileName(VAR FileName: ARRAY OF CHAR): BOOLEAN;
CONST
  IllegalChars = ';,=+<>|"[] \';
VAR
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;

  (* Contains returns true if Dir contains any characters in IllegalChars *)
  PROCEDURE Contains(VAR n : ARRAY OF CHAR ):BOOLEAN;
  BEGIN
    FOR s := 0 TO Length( IllegalChars )-1 DO
      l := Length( n );
      IF ScanR( ADR( n ), l, IllegalChars[ s ]) # l THEN
        RETURN TRUE;
      END;
    END;
    RETURN FALSE;
  END Contains;

BEGIN
  FSplit(FileName, Dir, Name, Ext);
  RETURN ((Dir = '') OR PathValid(Dir)) &
         NOT Contains(Name, IllegalChars) &
         NOT Contains(Dir, IllegalChars);
END ValidFileName;

PROCEDURE GetCurDir(VAR CurDir : ARRAY OF CHAR );
BEGIN
  GetDir(0, CurDir);
  IF Length( CurDir ) > 3 THEN
    Append( CurDir, '\' );
  END;
END GetCurDir;

TYPE
  PSearchRec = POINTER TO TSearchRec;

PROCEDURE IsWild(VAR S: ARRAY OF CHAR ): BOOLEAN;
BEGIN
  RETURN (Pos('?',S) # MAX(CARDINAL)) OR (Pos('*',S) # MAX(CARDINAL));
END IsWild;

PROCEDURE IsDir(VAR S: ARRAY OF CHAR): BOOLEAN;
VAR
  SR: SearchRec;
BEGIN
  FindFirst(S, Directory, SR);
  IF DosError = 0 THEN
    RETURN SR.Attr AND (Directory <> 0);
  ELSE
    RETURN FALSE;
  END;
END IsDir;

CLASS IMPLEMENTATION TFileInputLine;

  PROCEDURE Init(VAR Bounds: TRect; AMaxLen: INTEGER);
  BEGIN
    TInputLine.Init(Bounds, AMaxLen);
    INCL( EventMask, evBroadcast );
  END Init;

  PROCEDURE HandleEvent(VAR Event: TEvent);
  VAR
    Dir: DirStr;
    Name: NameStr;
    Ext: ExtStr;
  BEGIN
    TInputLine.HandleEvent(Event);
    IF (Event.What    = EventTypes{ evBroadcast }) &
       (Event.Command = cmFileFocused) &
       (sfSelected IN State )
    THEN
       IF PSearchRec(Event.InfoPtr)^.Attr & (Directory <> 0) THEN
         Data^ := PSearchRec(Event.InfoPtr)^.Name + '\'+
            PFileDialog(Owner)^.WildCard
       ELSE
         Data^ := PSearchRec(Event.InfoPtr)^.Name;
       END;
       DrawView;
    END;
  END HandleEvent;

BEGIN
END TFileInputLine;

CLASS IMPLEMENTATION TFileCollection;

  PROCEDURE Compare(Key1, Key2: ADDRESS): INTEGER;
  BEGIN
    IF PSearchRec(Key1)^.Name = PSearchRec(Key2)^.Name THEN
      RETURN 0;
    ELSIF PSearchRec(Key1)^.Name = '..' THEN
      RETURN 1;
    ELSIF PSearchRec(Key2)^.Name = '..' THEN
      RETURN -1;
    ELSIF (PSearchRec(Key1)^.Attr AND Directory <> 0) AND
       (PSearchRec(Key2)^.Attr AND Directory = 0)
    THEN
      Compare := 1;
    ELSIF (PSearchRec(Key2)^.Attr AND Directory <> 0) AND
          (PSearchRec(Key1)^.Attr AND Directory = 0)
    THEN
      Compare := -1;
    ELSIF PSearchRec(Key1)^.Name > PSearchRec(Key2)^.Name THEN
      Compare := 1;
    ELSE
      Compare := -1;
    END;
  END Compare;

  PROCEDURE FreeItem(Item: ADDRESS);
  BEGIN
    DISPOSE(PSearchRec(Item));
  END FreeItem;

  PROCEDURE GetItem(VAR S: TStream): ADDRESS;
  VAR
    Item: PSearchRec;
  BEGIN
    NEW(Item);
    S.Rd(Item^);
    RETURN Item;
  END GetItem;

  PROCEDURE PutItem(VAR S: TStream; Item: ADDRESS);
  BEGIN
    S.Write(Item^, TSIZE( TSearchRec ));
  END PutItem;

BEGIN
END TFileCollection;

CLASS IMPLEMENTATION TSortedListBox;

  PROCEDURE Init(VAR Bounds: TRect;
                     ANumCols: CARDINAL;
                     AScrollBar: PScrollBar);
  BEGIN
    TListBox.Init(Bounds, ANumCols, AScrollBar);
    SearchPos := 0;
    ShowCursor;
    SetCursor(1,0);
  END Init;

  PROCEDURE HandleEvent(VAR Event: TEvent);
  VAR
    CurString, NewString: String;
    K: ADDRESS;
    Value, OldPos, OldValue: INTEGER;
    T: BOOLEAN;

    PROCEDURE Equal( VAR S1, S2: ARRAY OF CHAR; Count: CARDINAL): BOOLEAN;
    VAR
      i : CARDINAL;
    BEGIN
      IF ( Length(S1) < Count ) OR ( Length(S2) < Count ) THEN
        RETURN FALSE;
      END;
      FOR i := 0 TO Count-1 DO
        IF CAP(S1[i]) # CAP(S2[i]) THEN
          RETURN FALSE;
        END;
      END;
      RETURN TRUE;
    END Equal;

  BEGIN
    OldValue := Focused;
    TListBox.HandleEvent(Event);
    IF OldValue # Focused THEN
      SearchPos := 0;
    END;
    IF Event.What = EventTypes{ evKeyDown } THEN
      IF Event.CharCode # 0C THEN
        Value := Focused;
        IF Value < Range THEN
          CurString := GetText(Value);
        ELSE
          CurString := '';
        END;
        OldPos := SearchPos;
        IF Event.KeyCode = kbBack THEN
          IF SearchPos = 0 THEN
            RETURN;
          END;
          DEC(SearchPos);
          IF SearchPos = 0 THEN
            ShiftState := Event.KState;
          END;
          CurString[0] := CHR(SearchPos);
        ELSIF (Event.CharCode = '.') THEN
          SearchPos := Pos( '.', CurString);
        ELSE
          INC(SearchPos);
          IF SearchPos = 1 THEN
            ShiftState := Event.KState;
          END;
          CurString[0] := CHR(SearchPos);
          CurString[SearchPos] := Event.CharCode;
        END;
        K := GetKey(CurString);
        T := PSortedCollection(List)^.Search(K, Value);
        IF Value < Range THEN
          IF Value < Range THEN
            NewString := GetText(Value);
          ELSE
            NewString := '';
          END;
          IF Equal(NewString, CurString, SearchPos) THEN
            IF Value <> OldValue THEN
              FocusItem(Value);
              (* Assumes ListControl will set the cursor to the first character *)
              (* of the sfFocused item *)
              SetCursor(Cursor.X+SearchPos, Cursor.Y);
            ELSE
              SetCursor(Cursor.X+(SearchPos-OldPos), Cursor.Y);
            END;
          ELSE
            SearchPos := OldPos;
          END;
        ELSE
          SearchPos := OldPos;
        END;
        IF (SearchPos <> OldPos) OR
           (Event.CharCode IN CHARSET{'A'..'Z','a'..'z'})
        THEN
          ClearEvent(Event);
        END;
      END;
    END;
  END HandleEvent;

  PROCEDURE GetKey(VAR S: ARRAY OF CHAR): ADDRESS;
  BEGIN
    RETURN ADR( S );
  END GetKey;

  PROCEDURE NewList(AList: PCollection);
  BEGIN
    TListBox.NewList(AList);
    SearchPos := 0;
  END NewList;

BEGIN
END TSortedListBox;

CLASS IMPLEMENTATION TFileList;

  PROCEDURE Init(VAR Bounds: TRect;
                     AWildCard: ARRAY OF CHAR;
                     AScrollBar: PScrollBar);
  BEGIN
    TSortedListBox.Init(Bounds, 2, AScrollBar);
  END Init;

  PROCEDURE Done;
  BEGIN
    IF List # NIL THEN
      List^.Done;
      DISPOSE(List);
    END;
    TListBox.Done;
  END Done;

  PROCEDURE DataSize(): CARDINAL;
  BEGIN
    DataSize := 0;
  END DataSize;

  PROCEDURE FocusItem(Item: INTEGER);
  BEGIN
    TSortedListBox.FocusItem(Item);
    Message(Owner, evBroadcast, cmFileFocused, List^.At(Item));
  END FocusItem;

  PROCEDURE GetData(VAR Rec : ARRAY OF CHAR);
  END GetData;

  PROCEDURE GetKey(VAR S: ARRAY OF CHAR): ADDRESS;
(*
  CONST
    SR: TSearchRec = ();
*)
  BEGIN
    IF (ShiftState & $03 <> 0) OR ((S <> '') AND (S[1]='.')) THEN
      SR.Attr := Directory;
    ELSE
      SR.Attr := 0;
    END;
    SR.Name := S;
    CapsStr(SR.Name);
    RETURN ADR( SR );
  END GetKey;

  PROCEDURE GetText(Item: INTEGER; MaxLen: INTEGER): String;
  VAR
    S: String;
    SR: PSearchRec;
  BEGIN
    SR := PSearchRec(List^.At(Item));
    S := SR^.Name;
    IF SR^.Attr AND (Directory <> 0) THEN
      Append( S, '\' );
    END;
    RETURN S;
  END GetText;

  PROCEDURE HandleEvent(VAR Event: TEvent);
  BEGIN
    IF (Event.What = EnentTypes{ evMouseDown }) & (Event.Double) THEN
      Event.What := evCommand;
      Event.Command := cmOK;
      PutEvent(Event);
      ClearEvent(Event);
    ELSE
      TSortedListBox.HandleEvent(Event);
    END;
  END HandleEvent;

  PROCEDURE ReadDirectory(AWildCard: ARRAY OF CHAR);
  CONST
    FindAttr = ReadOnly + Archive;
    AllFiles = '*.*';
    PrevDir  = '..';
  VAR
    S: SearchRec;
    P: PSearchRec;
    FileList: PFileCollection;
    NumFiles: CARDINAL;
    CurPath: PathStr;
    Dir: DirStr;
    Name: NameStr;
    Ext: ExtStr;
    Event: TEvent;
    Tmp: PathStr;
    Flag: Integer;
  BEGIN
    NumFiles := 0;
    AWildCard := FExpand(AWildCard);
    FSplit(AWildCard, Dir, Name, Ext);
    FileList := New(PFileCollection, Init(5, 5));
    FindFirst(AWildCard, FindAttr, S);
    P := ADR( P );
    WHILE (P # NIL) & (DosError = 0) DO
      IF (S.Attr & Directory = 0) THEN
        P := MemAlloc(SizeOf(P^));
        IF P <> nil THEN
          Move(S.Attr, P^, SizeOf(P^));
          FileList^.Insert(P);
        END;
      END;
      FindNext(S);
    END;
    Tmp := Dir + AllFiles;
    FindFirst(Tmp, Directory, S);
    WHILE (P <> nil) & (DosError = 0) DO
      IF (S.Attr & Directory <> 0) & (S.Name[1] <> '.') THEN
        P := MemAlloc(SizeOf(P^));
        IF P # NIL THEN
          Move(S.Attr, P^, SizeOf(P^));
          FileList^.Insert(PObject(P));
        END;
      END;
      FindNext(S);
    END;
    IF Length(Dir) > 4 THEN
      P := MemAlloc(SizeOf(P^));
      IF P <> nil THEN
        FindFirst(Tmp, Directory, S);
        FindNext(S);
        IF (DosError = 0) AND (S.Name = PrevDir) THEN
          Move(S.Attr, P^, SizeOf(P^))
        ELSE
          P^.Name := PrevDir;
          P^.Size := 0;
          P^.Time := $210000;
          P^.Attr := Directory;
        END;
        FileList^.Insert(PObject(P));
      END;
    END;
    IF P = NIL THEN
      MessageBox('Too many files.', nil, mfOkButton + mfWarning);
    END;
    NewList(FileList);
    IF List^.Count > 0 THEN
      Event.What := EventTypes{ evBroadcast };
      Event.Command := cmFileFocused;
      Event.InfoPtr := List^.At(0);
      Owner^.HandleEvent(Event);
    END;
  END HandleEvent;

  PROCEDURE SetData(VAR Rec : ARRAY OF CHAR);
  BEGIN
    WITH PFileDialog(Owner)^ DO
      SELF.ReadDirectory(Directory^ + WildCard);
    END;
  END SetData;

BEGIN
END TFileList;
(*
CLASS IMPLEMENTATION TFileInfoPane;

  PROCEDURE Init(VAR Bounds: TRect);
  BEGIN
    TView.Init(Bounds);
    INCL( EventMask, evBroadcast );
  END Init;

  PROCEDURE Draw;
  VAR
    b: TDrawBuffer;
    d: String[9];
    m: String[3];
    pm: BOOLEAN;
    Color: CARDINAL;
    Time: DateTime;
    Path: String;
    FmtId: String;
    Params: ARRAY[0..7] OF LONGINT;
    str: String[80];
  CONST
    sDirectoryLine = ' %-12s %-9s %3s %2d, %4d  %2d:%02d%cm';
    sFileLine      = ' %-12s %-9d %3s %2d, %4d  %2d:%02d%cm';
  BEGIN
    (* Display path *)
    Path := FExpand(PFileDialog(Owner)^.Directory^+PFileDialog(Owner)^.WildCard);
    Color := GetColor(1);
    MoveChar(B, ' ', Color, Size.X);
    MoveStr(b, 1, Path, Color);
    WriteLine(0, 0, Size.X, 1, B);

    (* Display file *)
    Params[0] := LongInt(ADR(S.Name));
    MoveChar(B, ' ', Color, Size.X);
    Params[0] := LongInt(ADR(S.Name));
    IF S.Attr & Directory <> 0 THEN
      FmtId := sDirectoryLine;
      D := Directory;
      Params[1] := LongInt(ADR(D));
    end else
    begin
      FmtId := sFileLine;
      Params[1] := S.Size;
    end;
    UnpackTime(S.Time, Time);
    M := Month[Time.Month];
    Params[2] := LongInt(@M);
    Params[3] := Time.Day;
    Params[4] := Time.Year;
    PM := Time.Hour >= 12;
    Time.Hour := Time.Hour mod 12;
    if Time.Hour = 0 then Time.Hour := 12;
    Params[5] := Time.Hour;
    Params[6] := Time.Min;
    if PM then Params[7] := Byte('p')
    else Params[7] := Byte('a');
    FormatStr(Str, FmtId, Params);
    MoveStr(B, Str, Color);
    WriteLine(0, 1, Size.X, 1, B);
  
    { Fill in rest of rectangle }
    MoveChar(B, ' ', Color, Size.X);
    WriteLine(0, 2, Size.X, Size.Y-2, B);
  end;
  
  function TFileInfoPane.GetPalette: PPalette;
  const
    P: String[Length(CInfoPane)] = CInfoPane;
  begin
    GetPalette := @P;
  end;
  
  procedure TFileInfoPane.HandleEvent(var Event: TEvent);
  begin
    TView.HandleEvent(Event);
    if (Event.What = evBroadcast) and (Event.Command = cmFileFocused) then
    begin
      S := PSearchRec(Event.InfoPtr)^;
      DrawView;
    end;
  end;

BEGIN
END TFileInfoPane;

IMPLEMENTATION CLASS TFileDialog;

  constructor TFileDialog.Init(AWildCard: TWildStr; ATitle: String;
    InputName: String; AOptions: Word; HistoryId: Byte);
  var
    Control: PView;
    R: TRect;
    S: String;
    Opt: Word;
    ACurDir: PathStr;
  begin
    R.Assign(15,1,64,20);
    TDialog.Init(R, ATitle);
    Options := Options or ofCentered;
    WildCard := AWildCard;
  
    R.Assign(3,3,31,4);
    FileName := New(PFileInputLine, Init(R, 79));
    FileName^.Data^ := WildCard;
    Insert(FileName);
    R.Assign(2,2,3+CStrLen(InputName),3);
    Control := New(PLabel, Init(R, InputName, FileName));
    Insert(Control);
    R.Assign(31,3,34,4);
    Control := New(PHistory, Init(R, FileName, HistoryId));
    Insert(Control);
  
    R.Assign(3,14,34,15);
    Control := New(PScrollBar, Init(R));
    Insert(Control);
    R.Assign(3,6,34,14);
    FileList := New(PFileList, Init(R, WildCard, PScrollBar(Control)));
    Insert(FileList);
    R.Assign(2,5,8,6);
    Control := New(PLabel, Init(R, '~F~iles', FileList));
    Insert(Control);
  
    R.Assign(35,3,46,5);
    Opt := bfDefault;
    if AOptions and fdOpenButton <> 0 then
    begin
      Insert(New(PButton, Init(R, '~O~pen', cmFileOpen, Opt)));
      Opt := bfNormal;
      Inc(R.A.Y,3); Inc(R.B.Y,3);
    end;
    if AOptions and fdOkButton <> 0 then
    begin
      Insert(New(PButton, Init(R, 'O~K~', cmFileOpen, Opt)));
      Opt := bfNormal;
      Inc(R.A.Y,3); Inc(R.B.Y,3);
    end;
    if AOptions and fdReplaceButton <> 0 then
    begin
      Insert(New(PButton, Init(R, '~R~eplace',cmFileReplace, Opt)));
      Opt := bfNormal;
      Inc(R.A.Y,3); Inc(R.B.Y,3);
    end;
    if AOptions and fdClearButton <> 0 then
    begin
      Insert(New(PButton, Init(R, '~C~lear',cmFileClear, Opt)));
      Opt := bfNormal;
      Inc(R.A.Y,3); Inc(R.B.Y,3);
    end;
    Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
    Inc(R.A.Y,3); Inc(R.B.Y,3);
    if AOptions and fdHelpButton <> 0 then
    begin
      Insert(New(PButton, Init(R, 'Help',cmHelp, bfNormal)));
      Inc(R.A.Y,3); Inc(R.B.Y,3);
    end;
  
    R.Assign(1,16,48,18);
    Control := New(PFileInfoPane, Init(R));
    Insert(Control);
  
    SelectNext(False);
  
    if AOptions and fdNoLoadDir = 0 then ReadDirectory;
  end;
  
  constructor TFileDialog.Load(var S: TStream);
  var
    ACurDir: DirStr;
    ViewId: Word;
  begin
    TDialog.Load(S);
    S.Read(WildCard, SizeOf(TWildStr));
    GetSubViewPtr(S, FileName);
    GetSubViewPtr(S, FileList);
  
    ReadDirectory;
  end;
  
  destructor TFileDialog.Done;
  begin
    DisposeStr(Directory);
    TDialog.Done;
  end;
  
  procedure TFileDialog.GetData(var Rec);
  begin
    GetFilename(PathStr(Rec));
  end;
  
  procedure TFileDialog.GetFileName(var S: PathStr);
  var
    Path: PathStr;
    Name: NameStr;
    Ext: ExtStr;
    TPath: PathStr;
    TName: NameStr;
    TExt: NameStr;
  
  function LTrim(S: String): String;
  var
    I: Integer;
  begin
    I := 1;
    while (I < Length(S)) and (S[I] = ' ') do Inc(I);
    LTrim := Copy(S, I, 255);
  end;
  
  function RTrim(S: String): String;
  var
    I: Integer;
  begin
    while S[Length(S)] = ' ' do Dec(S[0]);
    RTrim := S;
  end;
  
  function RelativePath(var S: PathStr): Boolean;
  var
    I,J: Integer;
    P: PathStr;
  begin
    S := LTrim(RTrim(S));
    if (S <> '') and ((S[1] = '\') or (S[2] = ':')) then RelativePath := False
    else RelativePath := True;
  end;
  {
  function NoWildChars(S: String): String; assembler;
  asm
  	PUSH	DS
  	LDS	SI,S
          XOR     AX,AX
  	LODSB
  	XCHG	AX,CX
          LES     DI,@Result
          INC     DI
          JCXZ    @@3
  @@1:	LODSB
  	CMP	AL,'?'
  	JE	@@2
  	CMP	AL,'*'
  	JE	@@2
  	STOSB
  @@2:	LOOP	@@1
  @@3:	XCHG	AX,DI
  	MOV	DI,WORD PTR @Result
  	SUB	AX,DI
          DEC     AX
          STOSB
  	POP	DS
  end;
  }
  begin
    S := FileName^.Data^;
    if RelativePath(S) then S := FExpand(Directory^ + S)
    else S := FExpand(S);
    FSplit(S, Path, Name, Ext);
    if ((Name = '') or (Ext = '')) and not IsDir(S) then
    begin
      FSplit(WildCard, TPath, TName, TExt);
      if ((Name = '') and (Ext = '')) then S := Path + TName + TExt
      else if Name = '' then S := Path + TName + Ext
      else if Ext = '' then
      begin
        if IsWild(Name) then S := Path + Name + TExt
        else S := Path + Name + NoWildChars(TExt);
      end;
    end;
  end;
  
  procedure TFileDialog.HandleEvent(var Event: TEvent);
  begin
    TDialog.HandleEvent(Event);
    if Event.What = evCommand then
      case Event.Command of
        cmFileOpen, cmFileReplace, cmFileClear:
          begin
            EndModal(Event.Command);
            ClearEvent(Event);
          end;
      end;
  end;
  
  procedure TFileDialog.SetData(var Rec);
  begin
    TDialog.SetData(Rec);
    if (PathStr(Rec) <> '') and (IsWild(TWildStr(Rec))) then
    begin
      Valid(cmFileInit);
      FileName^.Select;
    end;
  end;
  
  procedure TFileDialog.ReadDirectory;
  begin
    FileList^.ReadDirectory(WildCard);
    Directory := NewStr(GetCurDir);
  end;
  
  procedure TFileDialog.Store(var S: TStream);
  begin
    TDialog.Store(S);
    S.Write(WildCard, SizeOf(TWildStr));
    PutSubViewPtr(S, FileName);
    PutSubViewPtr(S, FileList);
  end;
  
  function TFileDialog.Valid(Command: Word): Boolean;
  var
    T: Boolean;
    FName: PathStr;
    Dir: DirStr;
    Name: NameStr;
    Ext: ExtStr;
  
  function CheckDirectory(var S: PathStr): Boolean;
  begin
    if not PathValid(S) then
    begin
      MessageBox('Invalid drive or directory.', nil, mfError + mfOkButton);
      FileName^.Select;
      CheckDirectory := False;
    end else CheckDirectory := True;
  end;
  
  begin
    if Command = 0 then
    begin
      Valid := True;
      Exit;
    end else Valid := False;
    if TDialog.Valid(Command) then
    begin
      GetFileName(FName);
      if (Command <> cmCancel) and (Command <> cmFileClear) then
      begin
        if IsWild(FName) then
        begin
          FSplit(FName, Dir, Name, Ext);
          if CheckDirectory(Dir) then
          begin
            DisposeStr(Directory);
            Directory := NewStr(Dir);
            WildCard := Name+Ext;
            if Command <> cmFileInit then FileList^.Select;
            FileList^.ReadDirectory(Directory^+WildCard);
          end
        end
        else if IsDir(FName) then
        begin
          if CheckDirectory(FName) then
          begin
            DisposeStr(Directory);
  	  Directory := NewSTr(FName+'\');
  	  if Command <> cmFileInit then FileList^.Select;
  	  FileList^.ReadDirectory(Directory^+WildCard);
          end
        end else if ValidFileName(FName) then Valid := True
        else
        begin
          MessageBox('Invalid file name.', nil, mfError + mfOkButton);
          Valid := False;
        end
      end
      else Valid := True;
    end;
  end;
  
BEGIN
END TFileDialog;
(*
{ TDirCollection }

function TDirCollection.GetItem(var S: TStream): Pointer;
var
  DirItem: PDirEntry;
begin
  New(DirItem);
  DirItem^.DisplayText := S.ReadStr;
  DirItem^.Directory := S.ReadStr;
  GetItem := DirItem;
end;

procedure TDirCollection.FreeItem(Item: Pointer);
var
  DirItem: PDirEntry absolute Item;
begin
  DisposeStr(DirItem^.DisplayText);
  DisposeStr(DirItem^.Directory);
  Dispose(DirItem);
end;

procedure TDirCollection.PutItem(var S: TStream; Item: Pointer);
var
  DirItem: PDirEntry absolute Item;
begin
  S.WriteStr(DirItem^.DisplayText);
  S.WriteStr(DirItem^.Directory);
end;

{ TDirListBox }

const
  DrivesS: String[6] = 'Drives';
  Drives: PString = @DrivesS;

constructor TDirListBox.Init(var Bounds: TRect; AScrollBar:
  PScrollBar);
begin
  TListBox.Init(Bounds, 1, AScrollBar);
  Dir := '';
end;

destructor TDirListBox.Done;
begin
  if List <> nil then Dispose(List, Done);
  TListBox.Done;
end;

function TDirListBox.GetText(Item: Integer; MaxLen: Integer): String;
begin
  GetText := PDirEntry(List^.At(Item))^.DisplayText^;
end;

procedure TDirListBox.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evMouseDown) and (Event.Double) then
  begin
    Event.What := evCommand;
    Event.Command := cmChangeDir;
    PutEvent(Event);
    ClearEvent(Event);
  end
  else TListBox.HandleEvent(Event);
end;

function TDirListBox.IsSelected(Item: Integer): Boolean;
begin
  IsSelected := Item = Cur;
end;

procedure TDirListBox.NewDirectory(var ADir: DirStr);
const
  PathDir            = 'ÀÄÂ';
  FirstDir           =   'ÀÂÄ';
  MiddleDir          =   ' ÃÄ';
  LastDir            =   ' ÀÄ';
  IndentSize         = '  ';
var
  AList: PCollection;
  NewDir, Dirct: DirStr;
  C, OldC: Char;
  S, Indent: String[80];
  P: PString;
  isFirst: Boolean;
  SR: SearchRec;
  I: Integer;
  DirEntry: PDirEntry;

function NewDirEntry(DisplayText, Directory: String): PDirEntry; {near;}
var
  DirEntry: PDirEntry;
begin
  New(DirEntry);
  DirEntry^.DisplayText := NewStr(DisplayText);
  DirEntry^.Directory := NewStr(Directory);
  NewDirEntry := DirEntry;
end;

{function GetCurDrive: Char; assembler;
asm
	MOV	AH,19H
        INT	21H
        ADD	AL,'A'
end;
}
begin
  Dir := ADir;
  AList := New(PDirCollection, Init(5,5));
  AList^.Insert(NewDirEntry(Drives^,Drives^));
  if Dir = Drives^ then
  begin
    isFirst := True;
    OldC := ' ';
    for C := 'A' to 'Z' do
    begin
      if (C < 'C') or DriveValid(C) then
      begin
        if OldC <> ' ' then
	begin
          if isFirst then
	  begin
	    S := FirstDir + OldC;
            isFirst := False;
          end
          else S := MiddleDir + OldC;
	  AList^.Insert(NewDirEntry(S, OldC + ':\'));
        end;
        if C = GetCurDrive then Cur := AList^.Count;
        OldC := C;
      end;
    end;
    if OldC <> ' ' then AList^.Insert(NewDirEntry(LastDir + OldC, OldC + ':\'));
  end
  else
  begin
    Indent := IndentSize;
    NewDir := Dir;
    Dirct := Copy(NewDir,1,3);
    AList^.Insert(NewDirEntry(PathDir + Dirct, Dirct));
    NewDir := Copy(NewDir,4,255);
    while NewDir <> '' do
    begin
      I := Pos('\',NewDir);
      if I <> 0 then
      begin
        S := Copy(NewDir,1,I-1);
        Dirct := Dirct + S;
        AList^.Insert(NewDirEntry(Indent + PathDir + S, Dirct));
        NewDir := Copy(NewDir,I+1,255);
      end
      else
      begin
        Dirct := Dirct + NewDir;
        AList^.Insert(NewDirEntry(Indent + PathDir + NewDir, Dirct));
        NewDir := '';
      end;
      Indent := Indent + IndentSize;
      Dirct := Dirct + '\';
    end;
    Cur := AList^.Count-1;
    isFirst := True;
    NewDir := Dirct + '*.*';
    FindFirst(NewDir, Directory, SR);
    while DosError = 0 do
    begin
      if (SR.Attr and Directory <> 0) and (SR.Name[1] <> '.') then
      begin
        if isFirst then
	begin
	  S := FirstDir;
	  isFirst := False;
	end else S := MiddleDir;
        AList^.Insert(NewDirEntry(Indent + S + SR.Name, Dirct + SR.Name));
      end;
      FindNext(SR);
    end;
    P := PDirEntry(AList^.At(AList^.Count-1))^.DisplayText;
    I := Pos('À',P^);
    if I = 0 then
    begin
      I := Pos('Ã',P^);
      if I <> 0 then P^[I] := 'À';
    end else
    begin
      P^[I+1] := 'Ä';
      P^[I+2] := 'Ä';
    end;
  end;
  NewList(AList);
  FocusItem(Cur);
end;

procedure TDirListBox.SetState(AState: Word; Enable: Boolean);
begin
  TListBox.SetState(AState, Enable);
  if AState and sfFocused <> 0 then
    PChDirDialog(Owner)^.ChDirButton^.MakeDefault(Enable);
end;

{ TChDirDialog }

constructor TChDirDialog.Init(AOptions: Word; HistoryId: Word);
var
  R: TRect;
  Control: PView;
  CurDir: DirStr;
begin
  R.Assign(16, 2, 64, 20);
  TDialog.Init(R, 'Change Directory');

  Options := Options or ofCentered;

  R.Assign(3, 3, 30, 4);
  DirInput := New(PInputLine, Init(R, 68));
  Insert(DirInput);
  R.Assign(2, 2, 17, 3);
  Control := New(PLabel, Init(R, 'Directory ~n~ame', DirInput));
  Insert(Control);
  R.Assign(30, 3, 33, 4);
  Control := New(PHistory, Init(R, DirInput, HistoryId));
  Insert(Control);

  R.Assign(32, 6, 33, 16);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 6, 32, 16);
  DirList := New(PDirListBox, Init(R, PScrollBar(Control)));
  Insert(DirList);
  R.Assign(2, 5, 17, 6);
  Control := New(PLabel, Init(R, 'Directory ~t~ree', DirList));
  Insert(Control);

  R.Assign(35, 6, 45, 8);
  OkButton := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
  Insert(OkButton);
  Inc(R.A.Y,3); Inc(R.B.Y,3);
  ChDirButton := New(PButton, Init(R, '~C~hdir', cmChangeDir, bfNormal));
  Insert(ChDirButton);
  Inc(R.A.Y,3); Inc(R.B.Y,3);
  Insert(New(PButton, Init(R, '~R~evert', cmRevert, bfNormal)));
  if AOptions and cdHelpButton <> 0 then
  begin
    Inc(R.A.Y,3); Inc(R.B.Y,3);
    Insert(New(PButton, Init(R, 'Help', cmHelp, bfNormal)));
  end;

  if AOptions and cdNoLoadDir = 0 then SetUpDialog;

  SelectNext(False);
end;

constructor TChDirDialog.Load(var S: TStream);
var
  CurDir: DirStr;
begin
  TDialog.Load(S);
  GetSubViewPtr(S, DirList);
  GetSubViewPtr(S, DirInput);
  GetSubViewPtr(S, OkButton);
  GetSubViewPtr(S, ChDirbutton);
  SetUpDialog;
end;

function TChDirDialog.DataSize: Word;
begin
  DataSize := 0;
end;

procedure TChDirDialog.GetData(var Rec);
begin
end;

procedure TChDirDialog.HandleEvent(var Event: TEvent); 
var
  CurDir: DirStr;
  P: PDirEntry;
begin
  TDialog.HandleEvent(Event);
  case Event.What of
    evCommand:
      begin
        case Event.Command of
          cmRevert: GetDir(0,CurDir);
          cmChangeDir:
            begin
              P := DirList^.List^.At(DirList^.Focused);
              if (P^.Directory^ = Drives^) or DriveValid(P^.Directory^[1]) then
                CurDir := P^.Directory^
              else Exit;
            end;
        else
          Exit;
        end;
        if (Length(CurDir) > 3) and (CurDir[Length(CurDir)] = '\') then
          CurDir := Copy(CurDir,1,Length(CurDir)-1);
        DirList^.NewDirectory(CurDir);
        DirInput^.Data^ := CurDir;
        DirInput^.DrawView;
        DirList^.Select;
        ClearEvent(Event);
      end;
  end;
end;

procedure TChDirDialog.SetData(var Rec);
begin
end;

procedure TChDirDialog.SetUpDialog;
var
  CurDir: DirStr;
begin
  if DirList <> nil then
  begin
    CurDir := GetCurDir;
    DirList^.NewDirectory(CurDir);
    if (Length(CurDir) > 3) and (CurDir[Length(CurDir)] = '\') then
      CurDir := Copy(CurDir,1,Length(CurDir)-1);
    if DirInput <> nil then
    begin
      DirInput^.Data^ := CurDir;
      DirInput^.DrawView;
    end;
  end;
end;

procedure TChDirDialog.Store(var S: TStream);
begin
  TDialog.Store(S);
  PutSubViewPtr(S, DirList);
  PutSubViewPtr(S, DirInput);
  PutSubViewPtr(S, OkButton);
  PutSubViewPtr(S, ChDirButton);
end;

function TChDirDialog.Valid(Command: Word): Boolean;
var
  P: PathStr;
begin
  Valid := True;
  if Command = cmOk then
  begin
    P := FExpand(DirInput^.Data^);
    if (Length(P) > 3) and (P[Length(P)] = '\') then Dec(P[0]);
    {$I-}
    ChDir(P);
    if IOResult <> 0 then
    begin
      MessageBox('Invalid directory.', nil, mfError + mfOkButton);
      Valid := False;
    end;
    {$I+}
  end;
end;

procedure RegisterStdDlg;
begin
  RegisterType(RFileInputLine);
  RegisterType(RFileCollection);
  RegisterType(RFileList);
  RegisterType(RFileInfoPane);
  RegisterType(RFileDialog);
  RegisterType(RDirCollection);
  RegisterType(RDirListBox);
  RegisterType(RChDirDialog);
end;
*)*)
END StdDlg.
