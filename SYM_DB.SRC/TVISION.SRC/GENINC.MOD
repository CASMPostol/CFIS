(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
(*------------------------------------------------------------------------*)
(* filename - geninc.cpp                                                  *)
(*                                                                        *)
(*      generates assembler EQUates for offsets of                        *)
(*      class data members                                                *)
(*                                                                        *)
(*  Used only before build!  Compile to produce GENINC.EXE,               *)
(*  then execute GENINC >TView.INC to produce the .INC                    *)
(*  file needed by the assembler files                                    *)
(*                                                                        *)
(*------------------------------------------------------------------------*)

(*------------------------------------------------------------------------*)
(*                                                                        *)
(*    Turbo Vision -  Version 1.0                                         *)
(*                                                                        *)
(*                                                                        *)
(*    Copyright (c) 1991 by Borland International                         *)
(*    All Rights Reserved.                                                *)
(*                                                                        *)
(*------------------------------------------------------------------------*)
MODULE GenINC;

FROM Objects IMPORT
  TPoint;
FROM Views IMPORT
  TView, TGroup, TFrame, TViewState, TViewStateType, TViewOption,
  TViewOptionType, MaxViewWidth;
FROM Drivers IMPORT
  TEvent, TDrawBuffer;
FROM IO IMPORT
  WrStr, WrCard, WrLn;
FROM SYSTEM IMPORT
  Ofs;


PROCEDURE Generate( name : ARRAY OF CHAR; offset : CARDINAL );
BEGIN
  WrStr(name);
  WrStr(' = ');
  WrCard(offset, 4);
  WrLn;
END Generate;

PROCEDURE GenRefs;
VAR
  Point : TPoint;
  View : TView;
  Group : TGroup;
  Event : TEvent;
  Frame : TFrame;
  DrawBuffer : TDrawBuffer;
BEGIN
    Generate(' TPointX',           Ofs(Point.X)-Ofs(Point) );
    Generate(' TPointY',           Ofs(Point.Y)-Ofs(Point) );

    Generate(' TViewSizeX',        Ofs(View.Size.X )-Ofs(View));
    Generate(' TViewSizeY',        Ofs(View.Size.Y )-Ofs(View));
    Generate(' TViewState',        Ofs(View.State )-Ofs(View));
    Generate(' TViewOwner',        Ofs(View.Owner )-Ofs(View));
    Generate(' TViewOriginY',      Ofs(View.Origin.Y )-Ofs(View));
    Generate(' TViewOriginX',      Ofs(View.Origin.X )-Ofs(View));
    Generate(' TViewCursorY',      Ofs(View.Cursor.Y )-Ofs(View));
    Generate(' TViewCursorX',      Ofs(View.Cursor.X )-Ofs(View));
    Generate(' TViewNext',         Ofs(View.Next )-Ofs(View));
    Generate(' TViewOptions',      Ofs(View.Options )-Ofs(View));

    Generate(' TGroupClipAY',      Ofs(Group.Clip.A.Y )-Ofs(Group));
    Generate(' TGroupClipAX',      Ofs(Group.Clip.A.X )-Ofs(Group));
    Generate(' TGroupClipBY',      Ofs(Group.Clip.B.Y )-Ofs(Group));
    Generate(' TGroupClipBX',      Ofs(Group.Clip.B.X )-Ofs(Group));
    Generate(' TGroupLast',        Ofs(Group.Last )-Ofs(Group));
    Generate(' TGroupBuffer',      Ofs(Group.Buffer )-Ofs(Group));
    Generate(' TGroupLockFlag',    Ofs(Group.LockFlag )-Ofs(Group));

    Generate(' MsEventWhereX',     Ofs(Event.Where.X )-Ofs(Event));
    Generate(' MsEventWhereY',     Ofs(Event.Where.Y )-Ofs(Event));

    Generate(' TFrameSizeX',       Ofs(Frame.Size.X )- Ofs(Frame));
    Generate(' TFrameOwner',       Ofs(Frame.Owner) - Ofs(Frame));

    Generate(' TDrawBufferData',   Ofs(DrawBuffer.Data)-Ofs(DrawBuffer));
(*
    Generate(' TEditorCurPtr',     TEditor, curPtr ));
    Generate(' TEditorGapLen',     TEditor, gapLen ));
    Generate(' TEditorBuffer',     TEditor, buffer ));
    Generate(' TEditorSelStart',   TEditor, selStart ));
    Generate(' TEditorSelEnd',     TEditor, selEnd ));
    Generate(' TEditorBufSize',    TEditor, bufSize ));
    Generate(' TEditorBufLen',     TEditor, bufLen ));
    Generate(' TTerminalBuffer',   TTerminal, buffer ));
    Generate(' TTerminalBufSize',  TTerminal, bufSize ));
    Generate(' TTerminalQueBack',  TTerminal, queBack ));
*)
    Generate( " sfVisible",   CARDINAL( TViewState { sfVisible }));
    Generate( " sfCursorVis", CARDINAL( TViewState { sfCursorVis }));
    Generate( " sfCursorIns", CARDINAL( TViewState { sfCursorIns }));
    Generate( " sfFocused",   CARDINAL( TViewState { sfFocused }));
    Generate( " sfShadow",    CARDINAL( TViewState { sfShadow }));
    Generate( " sfExposed",   CARDINAL( TViewState { sfExposed }));
    Generate( " ofFramed",    CARDINAL( TViewOption { ofFramed }));

    Generate( " MaxViewWidth", MaxViewWidth);
END GenRefs;

BEGIN
  GenRefs;
END GenINC.
