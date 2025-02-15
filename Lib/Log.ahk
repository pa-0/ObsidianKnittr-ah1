class log
{
    __Init() {
        tpl=
    (

___________________________________________________
Overview:

Manuscript                : `%manuscriptname`%
Used Verb                 : `%UsedVerb`%
OHTML - Version           : `%obsidianhtml_version`%
Used Personal Fork        : `%bUseOwnOHTMLFork`%
ObsidianKnitr - Version   : `%ObsidianKnittr_Version`%
Quarto - Version          : `%Quarto_Version`%

___________________________________________________
Timings:

ObsidianHTML              > `%ObsidianHTML_Start`%
ObsidianHTML              < `%ObsidianHTML_End`%
                                         `%ObsidianHTML_Duration`%
intermediary Processing   > `%Intermediary_Start`%
intermediary Processing   < `%Intermediary_End`%
                                         `%Intermediary_Duration`%
Compilation               > `%Compilation_Start`%
Compilation               < `%Compilation_End`%
                                         `%Compilation_Duration`%

Total (not ms-precise)                   `%TotalExecution_Duration`%
Total + Startup_AHK (not ms-precise)     `%TOTAL_COUNT`%

___________________________________________________
Script Execution Settings:

ObsidianKnittr:
ObsidianKnittr - Version  : `%ObsidianKnittr_Version`%
Output - Formats          : `%formats`%
Keep Filename             : `%bKeepFilename`%
Stripped '#' from Tags    : `%bRemoveHashTagFromTags`%

ObsidianHTML:
OHTML - Version           : `%obsidianhtml_version`%
Used Verb                 : `%UsedVerb`%
Used Personal Fork        : `%bUseOwnOHTMLFork`%
Verbosity                 : `%bVerboseCheckbox`%
Stripped OHTML - Errors   : `%bRemoveObsidianHTMLErrors`%
Stripped Local MD-Links   : `%bStripLocalMarkdownLinks`%
Vault Limited             : `%bRestrictOHTMLScope`%

RMD:
Execute R-Script          : `%bRendertoOutputs`%

QMD: 
Quarto - Version          : `%Quarto_Version`%
Strip Type from Crossrefs : `%bRemoveQuartoReferenceTypesFromCrossrefs`%

___________________________________________________
Fed OHTML - Config:

`%configfile_contents`%

___________________________________________________
RMarkdown Document Settings:

`%DocumentSettings`%

___________________________________________________
Paths:
manuscriptlocation        : `%manuscriptpath`%
Vault limited to childs of: `%temporaryVaultpath`%
Vault-Limiter removed     : `%temporaryVaultpathRemoved`%
Output Folder             : `%output_path`%
Raw Input Copy            : `%rawInputcopyLocation`%
ObsidianHTML - Path       : `%obsidianHTML_path`% (either the path to the installed exe or the personal modded version)
Config - Template         : `%configtemplate_path`%
ObsidianHTMLCopy Dir      : `%ObsidianHTMLCopyDir`%
ObsidianHTMLWorking Dir   : `%ObsidianHTMLWorkDir`%
ObsidianHTMLOutputPath    : `%ObsidianHTMLOutputPath`%
___________________________________________________
OHTML - StdStreams:
Issued Command            : `%ObsidianHTMLCMD`%
stdOut                    : `%ObsidianHTMLstdOut`%
___________________________________________________
R - StdStreams:
Issued Command            : `%RCMD`%
Working Directory         : `%RWD`%
stdOut                    : `%Rdata_out`%
___________________________________________________
OK - Errorlog:
`%Errormessage`%
)
        ObjRawSet(this, "tpl", tpl)
    }
    __New(Path, Cache, Encoding := "UTF-8") {
        ObjRawSet(this, "__path", Path)
            , ObjRawSet(this, "__encoding", Encoding)
            , ObjRawSet(this, "__Cache", false)
            , ObjRawSet(this,"autowritetofile",true)
            , writeFile_Log(Path, this.tpl, Encoding,, true)
            , tempfile:=FileOpen(Path,"rw",Encoding)
            , ObjRawSet(this,"content",tempfile.read())
            , tempfile.close()
            , ObjRawSet(this,"__h",FileOpen(Path,"w",Encoding))
            , this.Cache(Cache)
            , OnExit(ObjBindMethod(this, "close"))
    }
    cache(Set := "") {
        ;; TODO: implement Cache (false by default, if true we don't close the fo inbetween calls? )
        if !StrLen(Set) {
            return this.__Cache
        }
        return this.__Cache := !!Set
    }
    toggleAutoWrite(benableWritingToFile) {
        this.autowritetofile:=benableWritingToFile + 0
    }
    close() {
        if (this.autowritetofile) { ;; string has not been written to file yet, so we need to push it there before closing the object
            ; this.write(this.content)
        } else {
            this.write(this.content)
        }
        this.__h.close()
    }
    handle() {
        this.__h.handle()
    }
    write(content) {
        this.__h.write(content)
    }
    getTotalDuration(atc1,atc2,key := "TotalExecution_Duration") {
        diff:=atc2-atc1
            , Time:=PrettyTickCount(diff)
            , this[key]:=RegExReplace(Time,"[hms]")
    }
    __Set(Key, Value) {
        OldLength:=strLen(this.content)
            , this.__h.Pos:=0 ; reset the pointer to the beginning of the file → this apparently still frameshifts?
            , Key:="`%" Key "`%" ; prep the eky
            , this.content:=strreplace(this.content,Key, Value)
            , NewLength:=strLen(this.content)
        if (NewLength<OldLength) {
            Diff:=abs(NewLength-OldLength)
            loop, % Diff {
                this.content.=A_Space
            }
            L:=strLen(this.content)
            if (OldLength!=L) {
                MsgBox 0x30, % "Log.__Set()", String written to fileobject was improperly padded.`n`nThis is not a catastrophic error`, just means your execution log is going to be ugly at the bottom.
            }
        }
        if (this.hasKey("autowritetofile")) {
            if (!this.autowritetofile) {
                this.handle()
                return
            }
        }
        this.write(this.content)
        this.handle()
    }
}

; #region: writeFile_Log (3352591673)
; #region: Metadata:
; Snippet: writeFile_Log;  (v.1.0)
;  10 April 2023
; --------------------------------------------------------------
; Author: Gewerd Strauss
; License: MIT
; --------------------------------------------------------------
; Library: Personal Library
; Section: 10 - Filesystem
; Dependencies: /
; AHK_Version: v1
; --------------------------------------------------------------
; Keywords: encoding, UTF-8/UTF-8-RAW
; #endregion:Metadata

; #region:Description:
; Small function for writing files to disk in a safe manner when requiring specific file encodings or flags.
; Allows f.e. UTF-8 filewrites
; #endregion:Description

; #region:Example
; Loop, Files, % Folder "\*." script.config.Config.filetype, F
;         {
;             scriptWorkingDir:=renameFile(A_LoopFileFullPath,Arr[A_Index],true,A_Index,TrueNumberOfFiles)
;             writeFile_Log(scriptWorkingDir "\gfa_renamer_log.txt",Files, "UTF-8-RAW","w",true)
;         }
; #endregion:Example

; #region:Code
writeFile_Log(Path, Content, Encoding := "", Flags := 0x2, bSafeOverwrite := false) {
    if (bSafeOverwrite && FileExist(Path)) ;; if we want to ensure nonexistance.
        FileDelete % Path
    if (Encoding != "") {
        if (fObj := FileOpen(Path, Flags, Encoding)) {
            fObj.Write(Content) ;; insert contents
            fObj.Close() ;; close file
        } else
            throw Exception("File could not be opened. Flags: " Flags "`nPath: " Path, -1, Path)
    } else {
        if (fObj := FileOpen(Path, Flags)) {
            fObj.Write(Content) ;; insert contents
            fObj.Close() ;; close file
        } else
            throw Exception("File could not be opened. Flags: " Flags "`nPath: " Path, -1, Path)
    }
    return
}
; #endregion:Code

; #endregion:writeFile_Log (3352591673)

; #region:CodeTimer_Log (2035383057)

; #region:Metadata:
; Snippet: CodeTimer_Log;  (v.1.0)
; --------------------------------------------------------------
; Author: CodeKnight
; Source: -
; (05.03.2020)
; --------------------------------------------------------------
; Library: AHK-Rare
; Section: 23 - Other
; Dependencies: /
; AHK_Version: v1
; --------------------------------------------------------------
; Keywords: performance, time
; #endregion:Metadata

; #region:Description:
; approximate measure of how much time has exceeded between two positions in code. Returns an array containing the time expired (in ms), as well as the displayed string.
; #endregion:Description

; #region:Example
; CodeTimer_Log("A timer")
; Sleep 1050
; ; Insert other code between the two function calls
; CodeTimer_Log("A timer")
;
; #endregion:Example

; #region:Code
CodeTimer_Log() {

    Global StartTimer

    If (StartTimer != "") {
        FinishTimer := A_TickCount
            , TimedDuration := FinishTimer - StartTimer
            , StartTimer := ""
            , time_withletters:=PrettyTickCount_Log(TimedDuration)
            , time_withoutletters:=RegexReplace(time_withletters,"[hms]")
        Return time_withoutletters
    } Else {
        StartTimer := A_TickCount
    }
}
; #endregion:Code

; #endregion:CodeTimer_Log (2035383057)

; --uID:2595808127
; Metadata:
; Snippet: PrettyTickCount_Log()
; 09 Oktober 2022  ; --------------------------------------------------------------
; License: WTFPL
; --------------------------------------------------------------
; Library: AHK-Rare
; Section: 26 - Date or Time
; Dependencies: /
; AHK_Version: v1
; --------------------------------------------------------------

;; Description:
;; takes a time in milliseconds and displays it in a readable fashion
;;
;;

PrettyTickCount_Log(timeInMilliSeconds) { 	;-- takes a time in milliseconds and displays it in a readable fashion
    ElapsedHours := SubStr(0 Floor(timeInMilliSeconds / 3600000), -1)
        , ElapsedMinutes := SubStr(0 Floor((timeInMilliSeconds - ElapsedHours * 3600000) / 60000), -1)
        , ElapsedSeconds := SubStr(0 Floor((timeInMilliSeconds - ElapsedHours * 3600000 - ElapsedMinutes * 60000) / 1000), -1)
        , ElapsedMilliseconds := SubStr(0 timeInMilliSeconds - ElapsedHours * 3600000 - ElapsedMinutes * 60000 - ElapsedSeconds * 1000, -2)
        , returned := ElapsedHours "h:" ElapsedMinutes "m:" ElapsedSeconds "s." ElapsedMilliseconds
    return returned
}

; --uID:2595808127
