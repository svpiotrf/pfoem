 
 /*------------------------------------------------------------------------
    File        : ExHelper
    Purpose     : 
    Syntax      : 
    Description : Error/Exception handling helper
    Author(s)   : Piotr Filipovic
    Created     : Wed Jul 10 05:20:20 EEST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.AppError.
USING Progress.Lang.Error.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS pfoem.ex.ExHelper:
    METHOD PUBLIC STATIC CHARACTER GetErrorMessages(poError AS CLASS Error):
        DEFINE VARIABLE i               AS INTEGER      NO-UNDO.
        DEFINE VARIABLE iMaxNum         AS INTEGER      NO-UNDO.
        DEFINE VARIABLE cErrorMessages  AS CHARACTER    NO-UNDO INITIAL "".
        DEFINE VARIABLE cReturnValue    AS CHARACTER    NO-UNDO.
        DEFINE VARIABLE cShortCallStack AS CHARACTER    NO-UNDO.

        IF NOT VALID-OBJECT(poError) THEN
            RETURN "Errors(s): Not valid error object (1)".

        iMaxNum = poError:NumMessages.
        DO i = 1 TO iMaxNum:
            cErrorMessages = SUBSTITUTE("&1 &2", cErrorMessages, GetUnifiedErrorMessage(poError, i)).
        END.
        IF cErrorMessages > "" THEN
            cErrorMessages = SUBSTRING(cErrorMessages, 2).

        cErrorMessages = SUBSTITUTE("Error(s:) &1", cErrorMessages).
        
        IF poError:GetClass():IsA("Progress.Lang.AppError") THEN DO:
            cReturnValue = CAST(poError, AppError):ReturnValue.
            IF cReturnValue = ? OR cReturnValue > "" THEN
                cErrorMessages = SUBSTITUTE("&1 ReturnValue: &2", cErrorMessages, cReturnValue).
        END.
        
        cShortCallStack = GetShortCallStack(poError).
        IF cShortCallStack > "" THEN
            cErrorMessages = SUBSTITUTE("&1 @ &2", cErrorMessages, cShortCallStack).

        RETURN cErrorMessages.
    END METHOD.
    
    METHOD PUBLIC STATIC CHARACTER GetUnifiedErrorMessage(poError AS CLASS Error, piMessageNum AS INTEGER):
        IF NOT VALID-OBJECT(poError) THEN
            RETURN "Not valid error object (1)".

        IF piMessageNum = ? OR piMessageNum < 1 OR piMessageNum > poError:NumMessages THEN
            RETURN SUBSTITUTE("Not valid error message number &1 (1)", piMessageNum).

        CASE poError:GetClass():TypeName:
            WHEN "Progress.Lang.AppError" THEN
                RETURN SUBSTITUTE("&1 (&2)", poError:GetMessage(piMessageNum), poError:GetMessageNum(piMessageNum)).
            OTHERWISE
                RETURN poError:GetMessage(piMessageNum).
        END CASE.
    END METHOD.
    
    METHOD PUBLIC STATIC CHARACTER GetShortCallStack (poError AS CLASS Error):
        DEFINE VARIABLE cCallStack      AS LONGCHAR     NO-UNDO.
        DEFINE VARIABLE iPos            AS INTEGER      NO-UNDO.

        IF NOT VALID-OBJECT(poError) THEN
            RETURN ?.

        cCallStack = poError:CallStack.
        IF cCallStack = ? OR cCallStack = "" THEN
            RETURN ?.

        iPos = INDEX(cCallStack, "~n").
        IF iPos > 0 THEN
             cCallStack = SUBSTRING(cCallStack, 1, iPos). /* First line of CallStack */

        iPos = INDEX(cCallStack, " at line ").
        iPos = INDEX(cCallStack, "(", iPos). /* Not need full file name */

        RETURN STRING(TRIM(SUBSTRING(cCallStack, 1, iPos - 1))).
        
        CATCH oError AS Progress.Lang.Error:
            /* Silent error. */
            RETURN ?.
        END CATCH.
    END METHOD.
END CLASS.
