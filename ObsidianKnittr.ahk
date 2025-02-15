#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Requires AutoHotkey v1.1.35+ ;; version at which script was written.
#SingleInstance Force
#MaxHotkeysPerInterval 99999999
#Warn All, Outputdebug
;#Persistent
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
DetectHiddenWindows On
SetKeyDelay -1,-1
SetBatchLines -1
SetTitleMatchMode 2
FileGetTime ModDate,%A_ScriptFullPath%,M
FileGetTime CrtDate,%A_ScriptFullPath%,C
CrtDate:=SubStr(CrtDate,7, 2) "." SubStr(CrtDate,5,2) "." SubStr(CrtDate,1,4)
ModDate:=SubStr(ModDate,7, 2) "." SubStr(ModDate,5,2) "." SubStr(ModDate,1,4)
global script := new script()
script := {base : script.base
        , name : regexreplace(A_ScriptName, "\.\w+")
        , crtdate : CrtDate
        , moddate : ModDate     
        , resfolder : A_ScriptDir "\res"
        , iconfile	 : ""
        , version : ""
        , config: []
        , configfile : A_ScriptDir "\INI-Files\" regexreplace(A_ScriptName, "\.\w+") ".ini"
        , configfolder : A_ScriptDir "\INI-Files"
        , aboutPath : A_ScriptDir "\res\About.html"
        , reqInternet: false
    ; , vfile_local : A_ScriptDir "\res\version.ini"
        , authorID : "Laptop-C"
        , Computername : A_ComputerName
        , license : A_ScriptDir "\res\LICENSE.txt" ;; do not edit the variables above if you don't know what you are doing.
        , blank : "" }
global DEBUG:=IsDebug()
main()
ExitApp 0
return

main() {
    EL := new log(A_ScriptDir "\Executionlog.txt", true)
        , fTraySetup()
        , script.loadCredits(script.resfolder "\credits.txt")
        , script.loadMetadata(script.resfolder "\meta.txt")
        , erh:=Func("fonError").Bind(DEBUG,EL)
        , onError(erh)
        , exh:=Func("fonExit").Bind(DEBUG,EL)
        , onExit(exh)
    ;; LOAD/INIT SCRIPT-CONFIGS
    ATC_TOTAL1:=A_TickCount
    if !script.load() {
        RS_C:=rscript_check()
            , OHTML_C:=obsidianhtml_check()
            , QUARTO_C:=quarto_check()
        if (!RS_C[1]) {
            ttip("rscript not available")
            if (InStr(rscript_path,"`n")){
                rscript_path:=StrReplace(rscript_path, "`r`n")
                    , rscript_path:=StrSplit(rscript_path)
                    , found:=false
                for _, path in rscript_path { ;; check if an installation of rscript is found; then check if there are multiple
                    if !InStr(path,".exe") { ;; skip wrong file formats.
                        continue
                    }
                    if (FileExist(path)) { ;; if a qualified hit is found, reassign it to the required variable, then break out.
                        found:=true
                            , rscript_path:=path
                        break
                    }
                }
                if (!found) { ;; no 
                    InputBox rscript_path, % script.name,% "Please give the absolute path of your installed 'Rscript.exe'-file you wish to use.`nIf you don't want to use this step, leave this empty and continue.",,,,,,,, % "C:\Program Files\R\R-MAJORVERSION.MINORVERSION.PATCH\bin\Rscript.exe"
                }
            } else {
                if !(FileExist(rscript_path)) {
                    InputBox rscript_path, % script.name,% "Please give the absolute path of your installed 'Rscript.exe'-file you wish to use.`nIf you don't want to use this step, leave this empty and continue.",,,,,,,, % "C:\Program Files\R\R-MAJORVERSION.MINORVERSION.PATCH\bin\Rscript.exe"
                }
            }
        } else {
            rscript_path:=RS_C[2]
        }
        if (!OHTML_C[1]) {
            ttip()
            Message:="The external python 3.11-package ObsidianHTML was not found.`nWithout this package, this program cannot function. Please set up ObsidianHTML first, then rerun this program."
                , Title:="External Dependency not found."
            AppError(Title, Message)
        }
        if (!QUARTO_C[1]) {
            ttip("quarto not available")
        }
        if (!InStr(FileExist(script.configfolder),"D")) {
            FileCreateDir % script.configfolder
        }
        setupDefaultConfig(script.configfile,RS_C,OHTML_C,QUARTO_C)
            , script.load()
            , writeFile(A_ScriptDir "\INI-Files\ObsidianKnittr_Version.ini",script.config.Version.ObsidianKnittr_Version,"UTF-16")
    }
    if (FileExist(OK_V:=A_ScriptDir "\INI-Files\ObsidianKnittr_Version.ini")) {
        FileRead ObsidianKnittr_Version, % OK_V
    } else {
        if (script.config.HasKey("Version")) {
            ObsidianKnittr_Version:=script.config.Version.ObsidianKnittr_Version
                , writeFile(A_ScriptDir "\INI-Files\ObsidianKnittr_Version.ini",script.config.Version.ObsidianKnittr_Version,"UTF-16")
        }
    }
    script.version:=script.config.version.ObsidianKnittr_Version:=Regexreplace(ObsidianKnittr_Version,"\s*")
        , clArgs:=A_Args
    /*
    clArgs:=["-h"]
    clArgs:=["path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md","format=quarto::html","format=quarto::docx","LastExecutionDirectory=0","OHTMLLevel=2"]
    clArgs:=["path=D:\Dokumente neu\Obsidian NoteTaking\BE31-Thesis\100 Thesis\Submission\BE31 Thesis Report.md","format=quarto::html","Verbose=0","UseOwnOHTMLFork=1","LastExecutionDirectory=1","OHTMLLevel=2","quarto::html.number-depth=2","quarto::html.author=Manfred von Karma","quarto::html.toc=1","quarto::html.toc-location=left"]
    clArgs:=["path=C:\Users\Claudius Main\Desktop\TempTemporal\BE31-Thesis-quarto\Report\___manuscript.md","format=quarto::html","Verbose=0","UseOwnOHTMLFork=1","LastExecutionDirectory=1","OHTMLLevel=-1","RenderToOutputs=0","--noMove","--noRender","--noOpen","--noIntermediates"]
    clArgs:=["path=C:/Users/Claudius Main/Desktop/TempTemporal/BE31-Thesis-quarto/documentation/methods/___grain-success.md","format=quarto::html","Verbose=0","UseOwnOHTMLFork=1","LastExecutionDirectory=1","OHTMLLevel=-1","RenderToOutputs=0","--noMove","--noRender","--noOpen","--noIntermediates"]
    clArgs:=["path=D:\Dokumente neu\Obsidian NoteTaking\BE31-Thesis-quarto\documentation\methods\___grain-success.md","format=quarto::html","Verbose=0","UseOwnOHTMLFork=1","LastExecutionDirectory=1","OHTMLLevel=1","RenderToOutputs=0","--noMove","--noRender","--noOpen","--notify"]
    clArgs:=["format=quarto::html","Verbose=1","UseOwnOHTMLFork=1","LastExecutionDirectory=1","OHTMLLevel=-1","RenderToOutputs=0","--noMove","--noRender","--noOpen","--noIntermediates","path=D:\Dokumente neu\Obsidian NoteTaking\BE31-Thesis-quarto/documentation/methods/___grain-success.md"]
    clArgs:=["OHTMLLevel=0","format=quarto::docx","format=quarto::html","Verbose=3","UseOwnOHTMLFork=1","LastExecutionDirectory=1","RenderToOutputs=0","--noRender","--notify","--noIntermediates","--noOpen","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\019-Bugtesting-Subvault\nesting\nesting2\nesting3\019-ObsHTML_EmbeddedTitleStripping_Main.md"]
    clArgs:=["format=quarto::docx","format=quarto::html","OHTMLLevel=2","Verbose=0","UseOwnOHTMLFork=1","LastExecutionDirectory=1","RenderToOutputs=0","--notify","--noIntermediates","--noMove","--noOpen","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\019-Bugtesting-Subvault\nesting\nesting2\nesting3\019-ObsHTML_EmbeddedTitleStripping_Main.md"]

    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","LastExecutionDirectory=1","--notify","--noIntermediates","--noMove","--noOpen","--noOKLOG","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\019-Bugtesting-Subvault\nesting\nesting2\nesting3\019-ObsHTML_EmbeddedTitleStripping_Main.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","LastExecutionDirectory=1","--notify","--noIntermediates","--noMove","--noOpen","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\019-Bugtesting-Subvault\nesting\nesting2\nesting3\019-ObsHTML_EmbeddedTitleStripping_Main.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","LastExecutionDirectory=1","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noMove","--noOpen","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","LastExecutionDirectory=1","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noOpen","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    if (DEBUG && GetKeyState("LShift","P")) {
    clArgs:=["path=D:\Dokumente neu\Obsidian NoteTaking\BE31-Thesis-quarto\Report\___manuscript.md","format=quarto::html","LastExecutionDirectory=1","OHTMLLevel=-1","Verbose=1","--OHTML.Convert","--OHTML.UseCustomFork","--OHTML.TrimErrors","--noMove","--noRender","--noOpen","--notify","--noIntermediates","--SourceNameIndex"]
    }
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","--OHTML.TrimErrors","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noOpen","--Quarto.TrimRefTypes","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","--OHTML.TrimErrors","LastExecutionDirectory=0","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noOpen","--Quarto.TrimRefTypes","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","--OHTML.TrimErrors","LastExecutionDirectory=1","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noOpen","--Quarto.TrimRefTypes","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","--OHTML.TrimErrors","LastExecutionDirectory=2","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noOpen","--Quarto.TrimRefTypes","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","--OHTML.TrimErrors","LastExecutionDirectory=3","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noOpen","--Quarto.TrimRefTypes","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","--OHTML.UseCustomFork","--OHTML.Convert","--OHTML.TrimErrors","LastExecutionDirectory=4","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noOpen","--Quarto.TrimRefTypes","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","--OHTML.UseCustomFork","--OHTML.Convert","--OHTML.TrimErrors","LastExecutionDirectory=5","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noOpen","--Quarto.TrimRefTypes","--keepFilename","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    clArgs:=["format=quarto::html","quarto::html.author=Professor E. Gadd","OHTMLLevel=2","RestrictOHTMLScope=0","--OHTML.UseCustomFork","--OHTML.Convert","--OHTML.TrimErrors","LastExecutionDirectory=5","--notify","--noIntermediates","IntermediatesRemovalLevel=4","--noOpen","--Quarto.TrimRefTypes","--keepFilename","path=D:\Dokumente neu\Obsidian NoteTaking\The Universe\200 University\06 Interns and Unis\BE28 Internship Report\Submission\BE28 Internship Report.md"]
    */
    if (!clArgs.length()) {
        guiOut:=guiShow()
    } else {
        CLIArgs:=parseA_Args(clArgs)
        if (HasVal(CLIArgs, "-h") || CLIArgs.HasKey("-h")) {
            CLI_help()
            ExitApp 2
        } else if (HasVal(CLIArgs,"-v") || CLIArgs.HasKey("-v")) {
            ttip(script.name " - " script.version,5)
            while (1) {
                if GetKeyState("Escape") {
                    break
                }
            }
            ExitApp 2
        } else {
            if !requireA_Args(CLIArgs) {
                msgbox % "error: arguments could not be validated. Missings Args?`n`nExpand upon this error message."
                ExitApp -1
            } else {
                processCLIFlags(CLIArgs)
                processCLIArgs(CLIArgs)
            }
            validateCLIArgs(CLIArgs)
                , script.config.LastRun.manuscriptpath:=CLIArgs.path
                , script.config.DDLHistory:=buildHistory(script.config.DDLHistory,script.config.Config.HistoryLimit,script.config.LastRun.manuscriptpath)
                , script.config.LastRun.last_output_type:=CLIArgs.format
            if (CLIArgs.noOKLog) { ;; disable logging by immediately returning out of the 'class.__Set()'-call
                EL.toggleAutoWrite(0) ;; don't write every new change to file directly ;; works for both error and exit
            } else {
                EL.toggleAutoWrite(1) ;; write every new change to file directly ;; works for both error and exit
            }
            global manuscriptpath:=CLIArgs.path
            guiOut:=guiShow(true,CLIArgs)
        }
    }
    ;; POPULATE EL WITH VALUES
    EL.manuscriptname:=guiOut.manuscriptname
        , EL.formats:=concat_formats(guiOut.Outputformats)
        , EL.manuscriptpath:=guiOut.manuscriptpath
        , EL.bVerboseCheckbox:=guiOut.Settings.bVerboseCheckbox
        , EL.bKeepFilename:=guiOut.Settings.bKeepFilename
        , EL.bRendertoOutputs:=guiOut.Settings.bRendertoOutputs
        , EL.bRemoveHashTagFromTags:=guiOut.Settings.bRemoveHashTagFromTags
        , EL.bConvertInsteadofRun:=guiOut.Settings.bConvertInsteadofRun
        , EL.bRemoveObsidianHTMLErrors:=guiOut.Settings.bRemoveObsidianHTMLErrors
        , EL.bStripLocalMarkdownLinks:=guiOut.Settings.bStripLocalMarkdownLinks
        , EL.bUseOwnOHTMLFork:=guiOut.Settings.bUseOwnOHTMLFork
        , EL.bRestrictOHTMLScope:=guiOut.Settings.bRestrictOHTMLScope
        , EL.bRemoveQuartoReferenceTypesFromCrossrefs:=guiOut.Settings.bRemoveQuartoReferenceTypesFromCrossrefs
        , EL.ObsidianKnittr_Version:=Regexreplace(ObsidianKnittr_Version,"\s*")
    if (guiOut.sel="") && (guiOut.Settings.bVerboseCheckbox="") && (!CLIArgs.Count()) {
        ExitApp -1
    }

    ;; OBSIDIANHTML SETUP CONFIGFILE
    obsidianhtml_configfile:=script.config.config.obsidianhtml_configfile

    tmpObsidianHTML_Config:=createTemporaryObsidianHTML_Config(guiOut.manuscriptpath, obsidianhtml_configfile,guiOut.Settings.bConvertInsteadofRun,guiOut.Settings.bUseOwnOHTMLFork)
        , EL.configtemplate_path:=obsidianhtml_configfile
        , EL.configfile_contents:=tmpObsidianHTML_Config[2]
    notify("Running ObsidianHTML",CLIArgs)
    if (obsidianhtml_configfile="") {
        obsidianhtml_configfile:=script.config.config.obsidianhtml_configfile
    }
    EL.ObsidianHTML_Start:=A_DD "." A_MM "." A_YYYY " - " A_Hour ":" A_Min ":" A_Sec
    ATC1:=A_TickCount
    Codetimer_Log()

    ;; OBSIDIANHTML SETUP VAULT LIMITER
    OHTML_OutputDir:=Deref(script.config.config.OHTML_OutputDir)
        , OHTML_WorkDir:=Deref(script.config.config.OHTML_WorkDir)
        , OHTML_WorkDir_OwnFork := script.config.Config.OHTML_WorkDir_OwnFork ; "D:\Dokumente neu\ObsidianPluginDev\obsidian-html"
    if (guiOut.Settings.bRestrictOHTMLScope) {
        if (CLIArgs!="") && (FileExist(CLIArgs.path)) { ;; CLI-path
            OHTMLScopeRestrictor_Object:=createTemporaryObsidianVaultRoot(guiOut.manuscriptpath,guiOut.Settings.bAutoSubmitOTGUI,CLIArgs.OHTMLLevel,CLIArgs)
        } else { ;; GUI-path
            if (guiOut.manuscriptpath==script.config.LastRun.path_lastmanuscript) {
                OHTMLScopeRestrictor_Object:=createTemporaryObsidianVaultRoot(guiOut.manuscriptpath,guiOut.Settings.bAutoSubmitOTGUI,script.config.LastRun.LastRelativeLevel)
            } else {
                script.config.LastRun.LastRelativeLevel:=-1
                OHTMLScopeRestrictor_Object:=createTemporaryObsidianVaultRoot(guiOut.manuscriptpath,guiOut.Settings.bAutoSubmitOTGUI)
            }
        }
        if (!OHTMLScopeRestrictor_Object.IsVaultRoot) { ;; ensure that the Restrictor-`.obsidian`-path gets removed in case of an error.
            OnExit(Func("removeTempDir").bind(OHTMLScopeRestrictor_Object.Path,false))
            OnError(Func("removeTempDir").bind(OHTMLScopeRestrictor_Object.Path,false))
        }
    }
    ;; OBSIDIANHTML EXECUTE OBSIDIANHTML
    if (tmpObsidianHTML_Config[1] && guiOut.Settings.bConvertInsteadofRun) {
        obsidianhtml_ret:=ObsidianHtml(,tmpObsidianHTML_Config[1],,guiOut.Settings.bUseOwnOHTMLFork,guiOut.Settings.bVerboseCheckbox,OHTML_OutputDir,OHTML_WorkDir,OHTML_WorkDir_OwnFork,OHTMLScopeRestrictor_Object,guiOut.Settings.bAutoSubmitOTGUI)
    } else {
        obsidianhtml_ret:=ObsidianHtml(guiOut.manuscriptpath,tmpObsidianHTML_Config[1],,guiOut.Settings.bUseOwnOHTMLFork,guiOut.Settings.bVerboseCheckbox,OHTML_OutputDir,OHTML_WorkDir,OHTML_WorkDir_OwnFork,OHTMLScopeRestrictor_Object,guiOut.Settings.bAutoSubmitOTGUI)
    }
    ;; OBSIDIANHTML REMOVE VAULT LIMITER
    if (guiOut.Settings.bRestrictOHTMLScope) {
        tempOVaultRoot:=removeTemporaryObsidianVaultRoot(OHTMLScopeRestrictor_Object.Path,OHTMLScopeRestrictor_Object.Graph)
        if (tempOVaultRoot.Removed) {
            EL.temporaryVaultpath:=OHTMLScopeRestrictor_Object.Path 
                , EL.temporaryVaultpathRemoved:="Yes"
            OnExit(Func("removeTempDir"),0)  ;; as the folder has been removed successfully, we can now remove this callback.  #FIXME: This does not seem to work at all. Why?
            OnError(Func("removeTempDir"),0)
        } else {
            if tempOVaultRoot.IsVaultRoot {
                EL.temporaryVaultpath:=OHTMLScopeRestrictor_Object.Path
                    , EL.temporaryVaultpathRemoved:="No - vault root"
            } else {
                EL.temporaryVaultpath:=OHTMLScopeRestrictor_Object.Path
                    , EL.temporaryVaultpathRemoved:="No - not removed, but not vault root"
            }
        }
    }
    ;; OBSIDIANHTML POSTPROCESS RESULTS
    EL.ObsidianHTML_Duration:=Codetimer_Log()
        , EL.ObsidianHTML_End:=A_DD "." A_MM "." A_YYYY " - " A_Hour ":" A_Min ":" A_Sec
        , EL.obsidianhtml_version:=strreplace(obsidianhtml_ret.obsidianhtml_version,"`n")
        , EL.obsidianhtml_path:=obsidianhtml_ret.obsidianhtml_path
        , EL.UsedVerb:=(guiOut.Settings.bConvertInsteadofRun?"Convert":"Run")
        , EL.ObsidianHTMLWorkDir:=obsidianhtml_ret["WorkDir"]
        , EL.ObsidianHTMLOutputpath:=obsidianhtml_ret["Outputpath"]
        , EL.ObsidianHTMLCopyDir:=obsidianhtml_ret["ObsidianHTMLCopyDir"]
        , EL.ObsidianHTMLCMD:=obsidianhtml_ret["CMD"]
        , EL.ObsidianHTMLstdOut:=obsidianhtml_ret["stdOut"]
    vMDPath:=getObsidianHTML_MDPath(obsidianhtml_ret)

    ;; INTERMEDIARY PROCESSING
    ;; Intermediary
    EL.Intermediary_Start:=A_DD "." A_MM "." A_YYYY " - " A_Hour ":" A_Min ":" A_Sec
    Codetimer_Log()
    notify("Converting to .rmd-file",CLIArgs)
    rmd_Path:=convertMDToRMD(vMDPath,"index")
    ; 5, 6
    notify("Moving to output folder",CLIArgs)
    Destination:=(InStr(Deref(guiOut.Settings.ExecutionDirectory),A_Desktop)?0:guiOut.Settings.ExecutionDirectory)
        , rmd_Path:=copyBack(rmd_Path,Destination,guiOut.manuscriptpath)
    SplitPath % rmd_Path,, OutDir
    rawinputCopyLocation:=regexreplace(OutDir "\" guiOut.manuscriptName "_vault.md","\\{2,}","\")
        , EL.output_path
        , EL.rawInputcopyLocation:=rawinputCopyLocation
    ; 7
    notify("Converting Image SRC's",CLIArgs)
    NewContents:=ConvertSRC_SYNTAX_V4(rmd_Path,guiOut.Settings.bRemoveObsidianHTMLErrors,guiOut.Settings.bStripLocalMarkdownLinks)
    notify("Processing Tags",CLIArgs)
    NewContents:=processTags(NewContents,guiOut.Settings.bRemoveHashTagFromTags)
    notify("Processing Abstract",CLIArgs)
    NewContents:=processAbstract(NewContents)
    for _, format in guiOut.Outputformats {                        ;; rmd → qmd conversion
        if (format.package="quarto") {
            notify("Convert to QMD",CLIArgs)
            qmdContents:=convertToQMD(NewContents,guiOut.Settings.bRemoveQuartoReferenceTypesFromCrossrefs)
                , qmd_Path:=strreplace(rmd_Path,".rmd",".qmd")
            break                                               ;; if a format is of quarto, run the quarto-conversion once, then continue on.
        }
    }
    ;; postprocess rmd-filecontent (some of the steps below are already done to qmd-content during `convertToQMD()`)
    NewContents:=cleanLatexEnvironmentsforRMarkdown(NewContents)
        , NewContents:=fixNullFields(NewContents)
        , EL.Intermediary_Duration:=Codetimer_Log()
        , EL.Intermediary_End:=A_DD "." A_MM "." A_YYYY " - " A_Hour ":" A_Min ":" A_Sec

    ;; COMPILE VIA RSCRIPT OR QUARTO_CLI
    EL.Compilation_Start:=A_DD "." A_MM "." A_YYYY " - " A_Hour ":" A_Min ":" A_Sec
        , Codetimer_Log()
        , writeFile(rmd_Path,NewContents,"UTF-8",,true)
    if (qmd_Path!="") {
        if (CLIArgs.noMove) {
            qmd_Path:=regexreplace(guiOut.manuscriptdir "\" guiOut.manuscriptname ".qmd","\\{2,}","\")
                , qmdContents:=quartopurgeTags(qmdContents)
        }
        if (CLIArgs.noContent) {
            /*
            ;; #TODO decide if I want to implement this as an actual feature
            ;; or just as a commandline arg to extract the outline into its own file to be rendered, e.g. 

            qmd_Path_structure:=regexreplace(guiOut.manuscriptdir "\" guiOut.manuscriptname "_structure.qmd","\\{2,}","\")
            */
            qmdOutline:=quartopurgeContents(qmdContents) 
            answer:=AppError("Save outline-doc?", "Do you want to save the outline of the current document as a separte qmd-file?`nOtherwhise, the contents of the document will be copied to the clipboard.", Options := 0x24, TitlePrefix := "",Timeout:=0)
            if (answer=="Yes") {
                qmdOutline_Path:=regexreplace(guiOut.manuscriptdir "\" guiOut.manuscriptname "_outline.qmd","\\{2,}","\")
                writeFile(qmdOutline_Path,qmdOutline,"UTF-8-RAW",,true)
                MsgBox % "written outline to '" qmdOutline_Path "'"
            } else {
                Clipboard:=qmdOutline
            }
        }
        writeFile(qmd_Path,qmdContents,"UTF-8-RAW",,true)
    }
    if (script.config.config.useQuartoCLI) {
        EL.Quarto_Version:=quartogetVersion()
        if (guiOut.Settings.bRendertoOutputs) {
            if (guiOut.Settings.bBackupOutput && !CLIArgs.noMove) {
                ttip(-1)
                notify("Backing up Files",CLIArgs)
                BackupDirectory:=backupOutput(qmd_Path,guiOut)
            }
            if (script.config.config.backupCount) {
                limitBackups(BackupDirectory,script.config.config.backupCount)
            }
            ttip(-1)
            notify("Executing quarto-CLI",CLIArgs)
            SplitPath % qmd_Path,, OutDir
            quarto_ret:=["","",OutDir]
            tmp:=""
            for _, output_type in guiOut.sel {
                ;; use "index.qmd" if we explicitly use the flag to do so, or if we are not running in CLI-mode.
                if (CLIArgs.SourceNameIndex || CLIArgs="") { 
                    SourceFileName:="index"
                } else {
                    SourceFileName:=guiOut.manuscriptname
                }
                if (guiOut.Settings.bkeepFilename) {
                    guiOut.Outputformats[output_type].filename:=guiOut.manuscriptname
                    guiOut.Outputformats[output_type].filenameMod:=" (" guiOut.Outputformats[output_type].package ")"
                }
                tmp.=output_type ":`n" write_quarto_yaml(guiOut.Outputformats[output_type],OutDir,"qCLI_yaml_" guiOut.Outputformats[output_type].filesuffix ".yaml")
                    , CMD:="quarto render " SourceFileName ".qmd --to " guiOut.Outputformats[output_type].filesuffix 
                    , CMD.=" --metadata-file=""qCLI_yaml_" guiOut.Outputformats[output_type].filesuffix ".yaml"""
                    , CMD.=" --output """ guiOut.Outputformats[output_type].Filename guiOut.Outputformats[output_type].FilenameMod "."  guiOut.Outputformats[output_type].filesuffix """"
                    , GetStdStreams_WithInput(CMD, OutDir, InOut:="`n")
                    , quarto_ret[1].="`nFormat " output_type ":`n" InOut
                    , quarto_ret[2].=CMD
                if (DEBUG) {
                    Clipboard:=(IsObject(InOut)?ttip_Obj2Str(InOut):InOut)
                }
                if (!CLIArgs.noIntermediates) {
                    writeFile(OutDir "\build_" guiOut.Outputformats[output_type].filesuffix ".cmd",CMD,"UTF-8-RAW",,true)
                }
            }
            EL.Rdata_out:=quarto_ret[1]
                , EL.RCMD:=quarto_ret[2]
                , EL.RWD:=quarto_ret[3]
            EL.DocumentSettings:=tmp
        }
    } else {
        notify("Creating R-BuildScript",CLIArgs)
        if (guiOut.Settings.bKeepFilename) {
            tmp:=buildRScriptContent(rmd_Path,guiOut.manuscriptName,guiOut)
        } else {
            tmp:=buildRScriptContent(rmd_Path,,guiOut)
        }
        if (qmd_Path!="") {
            tmp.1:=modifyQuartobuildscript(tmp.1,tmp.3,guiOut)
        }
        format:=tmp.2 
        script_contents:=tmp.1
        if (guiOut.Settings.bRendertoOutputs) {
            ttip(-1)
            notify("Executing R-BuildScript",CLIArgs)
            if (guiOut.Settings.bBackupOutput) {
                BackupDirectory:=backupOutput(rmd_Path,guiOut)
            }
            if (script.config.config.backupCount) {
                limitBackups(BackupDirectory,script.config.config.backupCount)
            }
            rscript_ret:=runRScript(rmd_Path,script_contents,guiOut.Outputformats,script.config.config.RScriptPath)
            EL.Rdata_out:=rscript_ret[1]
                , EL.RCMD:=rscript_ret[2]
                , EL.RWD:=rscript_ret[3]
        } Else {
            notify("Opening RMD-File",CLIArgs)
            SplitPath % rmd_Path,, OutDir
            writeFile(OutDir "\build.R",script_contents,"UTF-8-RAW",,true)
            if (!DEBUG) {
                run % rmd_Path
            }
        }
        ;; create ahk starter if running via rscript
        notify("Building AHK-Starterscript",CLIArgs)
        buildAHKScriptContent(rmd_Path,script.config.config.RScriptPath)
        EL.DocumentSettings:=tmp[2]
    }

    EL.Compilation_Duration:=Codetimer_Log()
        , EL.Compilation_End:=A_DD "." A_MM "." A_YYYY " - " A_Hour ":" A_Min ":" A_Sec
        , EL.getTotalDuration(ATC1,A_TickCount)
        , EL.getTotalDuration(ATC_TOTAL1,A_TickCount,"TOTAL_COUNT")
    ;; moving shit to output folder
    SplitPath % Path,, OutDir
    SplitPath % OutDir,, OutDir2
    if (script.config.config.OpenParentfolderInstead) {
        EL.output_path:=OutDir
    } else {
        EL.output_path:=OutDir2
    }
    if !DEBUG && !CLIArgs.HasKey("--noOpen") {
        openFolder(rmd_Path)
    }
    SplitPath % rmd_Path,, OutDir
    if (!CLIArgs.noMove) {
        if (FileExist(quarto_ret[3])) {
            ; removeTempDir(quarto_ret[3],false) ;; FIXME: Which directory should get remvoed here? Under which conditions? 
        } else if (FileExist(rscript_ret.Output_Path)) {
            ; removeTempDir(rscript_ret.OutputPath,false)
        }
    }
    ;; CLEANUP
    if (CLIArgs.count()) {
        if (FileExist(EL.__path)) {
            if (CLIArgs.noOKLog) {
                FileDelete % EL.__path
            } else if (CLIArgs.keepOKLog) {
                FileMove % EL.__path , % A_ScriptDir "\Executionlog (" guiOut.manuscriptname ").txt", true
            } else {  ;; only copy back the log if it is required
                SplitPath % rmd_Path,, OutDir
                FileMove % EL.__path, % OutDir "\Executionlog.txt",true
            }
        }
    } else {
        FileMove % EL.__path, % OutDir "\Executionlog.txt",true
    }
    if (CLIArgs.noIntermediates) {
        guiOut.removableintermediates:=collectQuartoIntermediates(guiOut,CLIArgs)
        failedRemovals:=cleanupIntermediatequartoFiles(guiOut)
        if (failedRemovals.Count()) {
            Title:=": clean-up of intermediates unsuccessful"
            Message:="The following intermediate-files resulting from executing quarto could not be removed:"
            for _, path in failedRemovals {
                Message.="`n '" path "'"
            }
            Message.="`n`nYou may either ignore this warning, or remove them yourself"
            AppError(Title, Message,0x40010," > " A_ThisFunc)
        }
    }
    if (!CLIArgs.Count()) { ;; only change config when running in GUI mode
        script.config.LastRun.manuscriptpath:=StrReplace(script.config.LastRun.manuscriptpath, "/","\")
        script.save()
    }
    return
}
openFolder(Path) {
    SplitPath % Path,, OutDir
    SplitPath % OutDir, OutFileName, OutDir2
    if (WinExist(OutFileName " ahk_exe explorer.exe")) {
        WinActivate
        return
    }
    if (script.config.config.OpenParentfolderInstead) {
        run % OutDir2
    } else {
        run % OutDir
    }
    return
}
buildAHKScriptContent(Path,RSCRIPT_PATH:="") {
    SplitPath % Path,, OutDir
    if (script.config.config.bundleStarterScript && (RSCRIPT_PATH!="")) {
        BUILD_RPATH:=strreplace(OutDir "\build.R","\","\\")
            , OUTDIR_PATH:=OutDir
        AHK_Build=
            (Join`s LTRIM
                #Requires AutoHotkey v1.1.36+
                `nrun, `% `"`"`"%RSCRIPT_PATH%"""
                A_Space """%BUILD_RPATH%"""
                , `% "%OUTDIR_PATH%"
            )
        writeFile(OutDir "\build.ahk",AHK_Build,"UTF-8",,true)
    }
    return
}
copyBack(Source,noDesktopDestination,manuscript_path) {
    SplitPath % Source, OutFileName, Dir,
    SplitPath % manuscript_path,,,,manuscript_name,
    if noDesktopDestination {
        FileCopyDir % Dir, % Output_Path:=regexreplace(noDesktopDestination "\" manuscript_name "\","\\{2,}","\"), true
        writeFile(Output_Path "\index.md",manuscriptcontent,,,true)
        pd:=Trim(regexreplace(Output_Path "\" manuscript_name "_vault.md ","\\{2,}","\"))
        FileCopy % manuscript_path, % pd, 1
    } Else {
        FileCopyDir % Dir, % Output_Path:= A_Desktop "\TempTemporal\" manuscript_name "\" , true
        if Errorlevel {
            msgbox % Errorlevel
        }
        pd:=Trim(regexreplace(Output_Path "\" manuscript_name "_vault.md ","\\{2,}","\"))
        FileCopy % manuscript_path, % pd, 1
    }
    path:=regexreplace(Output_Path OutFileName,"\\{2,}","\")
    return path 
}
removeTempDir(Path,RemoveParent:=TRUE) {
    SplitPath % Path,, OutDir
    if RemoveParent {
        FileRemoveDir % OutDir,1
        if FileExist(OutDir) {
            Title:=": folder is busy"
            Message:="The temp-directory '" OutDir "' could not be removed"
            AppError(Title, Message,0x40010," > " A_ThisFunc)
            Run % "explorer " OutDir
        }
    } else {
        FileRemoveDir % Path,1
        if FileExist(Path) {
            Title:=": folder is busy"
            Message:="The temp-directory '" OutDir "' could not be removed"
            AppError(Title, Message,0x40010," > " A_ThisFunc)
            Run % "explorer " Path
        }
    }
    return
}
getPotentialWorkDir(File,ExecutionDirectory) {
    gui submit, nohide
    SplitPath % File,, OutDir

    ExecutionDirectories:= OutDir "\ObsidianKnittr_output"
    return {relativeToNote:ExecutionDirectory,ExecutionDirectories:ExecutionDirectories}
}
getDefinedOutputFormats(Path) {
    PotentialOutputs:=["bookdown::word_document2", "html_document", "bookdown::html_document2", "bookdown::pdf_document2", "odt_document", "rtf_document", "md_document", "tufte::tufte_html", "github_document"]
        , Arr:=[]
        , filesuffixes:=[]
        , inputsuffixes:=[]
    if !FileExist(Path) {
        Gui +OwnDialogs
        Title:="File not found"
        Message:="A required file containing the GUI definitions for the output formats does not exist under `n`n'" Path "`n`nThis script will only use the default options for any format not found in this file"
        AppError(Title, Message,0x40030," > " A_ThisFunc)
        Arr:=PotentialOutputs ;; fallback to hardcoded default
    } else {
        FileRead FileString, % Path
        if (!InStr(FileString,"`r`n") && InStr(FileString,"`n")) {
            FileString:=StrReplace(FileString, "`n","`r`n")
            writeFile(Path,FileString,,,true)
            FileRead FileString, % Path
        }
        Lines:=strsplit(FileString,"`r`n")
        bFindSuffix:=false
        for _, Line in Lines {
            if SubStr(LTrim(Line),1,1)=";" {
                continue
            }
            if (Line="") {
                continue
            } else {
                if (RegexMatch(Line,"m)^\S")) {
                    Pos:=HasVal(PotentialOutputs,Line)
                        , PotentialOutputs.RemoveAt(Pos,1)
                        , Arr.push(Line)
                        , bFindSuffix:=true
                }
            }
            if (bFindSuffix) {
                if InStr(Line, "filesuffix:Meta") {
                    filesuffixes[Arr[Arr.MaxIndex()]]:=strsplit(Line,"Value:").2
                }
                if InStr(Line, "inputsuffix:Meta") {
                    inputsuffixes[Arr[Arr.MaxIndex()]]:=strsplit(Line,"Value:").2
                }
            }
        }
        for _, potential_output_type in PotentialOutputs {
            Arr.push(potential_output_type)
        }
    }
    return [Arr,filesuffixes,inputsuffixes]
}
concat_formats(formats) {
    for _,format in formats {
        if format.HasKey("Error") && (format.Error.ID=0) {
            Reload
            ExitApp -1 ;; fucking weird bug. DO NOT remove this exitapp below the reload-command. for some reason, removing it results in the script just ignoring the reload and continuing on as normal under certain situations
        }
        format_str.=_ ", "
    }
    format_str:=SubStr(format_str,1,StrLen(format_str)-2)
    return format_str
}
buildHistory(History,NumberOfRecords,manuscriptpath:="") {
    if (manuscriptpath!="") {
        if HasVal(History,manuscriptpath) {
            History.RemoveAt(HasVal(History,manuscriptpath),1)
        }
        History.InsertAt(1,manuscriptpath)
    }
    if (History.Count()>NumberOfRecords) {
        History.Delete(NumberOfRecords+1,History.Count())
    }
    h:=[]
    for _, file in History {
        h.push(file)
    }
    History:=h.clone()
    return History
}
editMainConfig(configfile) {
    static
    gui Submit, NoHide
    RunWait % configfile,,,PID
    WinWaitClose % "ahk_PID" PID
    Gui +OwnDialogs
    OnMessage(0x44, "DA_OnMsgBox")
    Title:=this.ClassName " > " A_ThisFunc
    Message:="You modified the configuration for this class.`nReload?"
    AppError(Title, Message, 0x40044,"")
    OnMessage(0x44, "")
    IfMsgBox Yes, {
        reload
    }
}
chooseFile() {
    if FileExist(strreplace(clipboard,"/","\")) {
        clipboard:=strreplace(clipboard,"/","\")
    } else {
        ttip("Clipboard does not contain a valid path.")
    }
    SplitPath % clipboard,,, Ext
    if CF_bool:=FileExist(clipboard) && (Ext="md") && !GetKeyState("LShift","P") {
        manuscriptpath:=(CF_bool?clipboard:script.config.searchroot)
    } else {
        if (script.config.config.SetSearchRootToLastRunManuscriptFolder) {
            SplitPath % script.config.Lastrun.manuscriptpath,, LastRunDir
            FileSelectFile manuscriptpath, 3, % (FileExist(clipboard)?clipboard:LastRunDir) , % "Choose &manuscript file", *.md
        } else {
            FileSelectFile manuscriptpath, 3, % (FileExist(clipboard)?clipboard:script.config.config.searchroot) , % "Choose &manuscript file", *.md
        }
        if (manuscriptpath="") {
            return
        }
    }
    script.config.DDLHistory:=buildHistory(script.config.DDLHistory,script.config.Config.HistoryLimit,manuscriptpath)
        , HistoryString:=""
    for each, File in script.config.DDLHistory {
        SplitPath % File,, OutDir,, FileName
        SplitPath % OutDir,OutFileName
        HistoryString.=((each=1)?"":"|") FileName "(" OutFileName ")" " -<>- " File
        if (each=1) {
            HistoryString.="|"
        }
    }
    GuiControl,, ChosenFile, |
    guicontrol,, ChosenFile, % HistoryString
    return manuscriptpath
}
fTraySetup() {
    b64QuickIcon_64x64 := "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"
    hICON := Base64PNG_to_HICON( b64QuickIcon_64x64 ) ; Create a HICON for Tray
    Menu Tray, Icon, HICON:*%hICON% ; AHK makes a copy of HICON when * is used
    Menu Tray, Icon
    DllCall( "DestroyIcon", "Ptr",hICON ) ; Destroy original HICON
    menu tray, add,
    Menu tray, add, Update ObsidianHTML to Master Branch ,updateObsidianHTMLToMaster
    Menu tray, add, Update ObsidianHTML to Last Release ,updateObsidianHTMLToLastRelease
    return
}

#Include <PrettyTickCount>
#Include <st_count>
#Include <HasVal>
#Include <Base64PNG_to_HICON>
#Include <script>
#Include <enableGuiDrag>
#Include <Quote>
#Include <ttip>
#Include <DynamicArguments>
#Include <SRC_ImageConverter>
#Include <ObsidianHTML>
#Include <writeFile>
#Include <RScript>
#Include <RMarkdown>
#Include <RegexMatchAll>
#Include <Deref>
#Include <OnError>
#Include <OnExit>
#Include <Log>
#Include <Outputbackup>
#Include <TemporaryObsidianVaultRoot>
#Include <Quarto>
#Include <script>
#Include <ownCLI>
#Include <Configuration>
#Include <messageboxes>
#Include <notify>
#Include <processing>
#Include <gui>
