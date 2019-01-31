
/*
CP_ACP   = 0
CP_OEMCP = 1
CP_MACCP = 2
CP_UTF7  = 65000 
CP_UTF8  = 65001 
*/

Ansi2Oem(sString)
{
    Ansi2Unicode(sString, wString, 0)
    Unicode2Ansi(wString, zString, 1)
    Return zString
}

Oem2Ansi(zString)
{
    Ansi2Unicode(zString, wString, 1)
    Unicode2Ansi(wString, sString, 0)
    Return sString
}

Ansi2UTF8(sString)
{
    Ansi2Unicode(sString, wString, 0)
    Unicode2Ansi(wString, zString, 65001)
    Return zString
}

UTF82Ansi(zString)
{
    Ansi2Unicode(zString, wString, 65001)
    Unicode2Ansi(wString, sString, 0)
    Return sString
}

Ansi2Unicode(ByRef sString, ByRef wString, CP = 0)
{
      nSize := DllCall("MultiByteToWideChar"
        , "Uint", CP
        , "Uint", 0
        , "Uint", &sString
        , "int",  -1
        , "Uint", 0
        , "int",  0)

    VarSetCapacity(wString, nSize * 2)

    DllCall("MultiByteToWideChar"
        , "Uint", CP
        , "Uint", 0
        , "Uint", &sString
        , "int",  -1
        , "Uint", &wString
        , "int",  nSize)
}

Unicode2Ansi(ByRef wString, ByRef sString, CP = 0)
{
      nSize := DllCall("WideCharToMultiByte"
        , "Uint", CP
        , "Uint", 0
        , "Uint", &wString
        , "int",  -1
        , "Uint", 0
        , "int",  0
        , "Uint", 0
        , "Uint", 0)

    VarSetCapacity(sString, nSize)

    DllCall("WideCharToMultiByte"
        , "Uint", CP
        , "Uint", 0
        , "Uint", &wString
        , "int",  -1
        , "str",  sString
        , "int",  nSize
        , "Uint", 0
        , "Uint", 0)
}

;=================================================================================================
;=================================================================================================

; ======================================================================================================================
; Namespace:   Base64
; AHK version: AHK 1.1.+ (required)
; Function:    Methods for Base64 en/decoding.
; Language:    English
; Tested on:   Win XPSP3, Win VistaSP2 (U32) / Win 7 (U64)
; Version:     1.0.00.00/2012-08-12/just me
; URL:         http://msdn.microsoft.com/en-us/library/windows/desktop/aa380252(v=vs.85).aspx
; Remarks:     The ANSI functions are used by default to save space. ANSI needs about 133 % of the original size for
;              encoding, whereas Unicode needs about 266 %.
; ======================================================================================================================
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from the use of this software.
; ======================================================================================================================
Class Base64 {
   ; CRYPT_STRING_BASE64 = 0x01
   ; ===================================================================================================================
   ; Base64.Encode()
   ; Parameters:
   ;    VarIn  - Variable containing the input buffer
   ;    SizeIn - Size of the input buffer in bytes
   ;    VarOut - Variable to receive the encoded buffer
   ;    Use    - Use ANSI (A) or Unicode (W) function
   ;             Default: A
   ; Return values:
   ;    On success: Number of bytes copied to VarOut, not including the terminating null character
   ;    On failure: False
   ; Remarks:
   ;    VarIn may contain any binary contents including NUll bytes.
   ; ===================================================================================================================
   Encode(ByRef VarIn, SizeIn, ByRef VarOut, Use = "A") {
      Static Codec := 0x01 ; CRYPT_STRING_BASE64
      If (Use <> "W")
         Use := "A"
      Enc := "Crypt32.dll\CryptBinaryToString" . Use
      If !DllCall(Enc, "Ptr", &VarIn, "UInt", SizeIn, "UInt", Codec, "Ptr", 0, "UIntP", SizeOut)
         Return False
      VarSetCapacity(VarOut, SizeOut << (Use = "W"), 0)
      If !DllCall(Enc, "Ptr", &VarIn, "UInt", SizeIn, "UInt", Codec, "Ptr", &VarOut, "UIntP", SizeOut)
         Return False
      Return SizeOut << (Use = "W")
   }
   ; ===================================================================================================================
   ; Base64.Decode()
   ; Parameters:
   ;    VarIn  - Variable containing a null-terminated Base64 encoded string
   ;    VarOut - Variable to receive the decoded buffer
   ;    Use    - Use ANSI (A) or Unicode (W) function
   ;          Default: A
   ; Return values:
   ;    On success: Number of bytes copied to VarOut
   ;    On failure: False
   ; Remarks:
   ;    VarOut may contain any binary contents including NUll bytes.
   ; ===================================================================================================================
   Decode(ByRef VarIn, ByRef VarOut, Use = "A") {
      Static Codec := 0x01 ; CRYPT_STRING_BASE64
      If (Use <> "W")
         Use := "A"
      Dec := "Crypt32.dll\CryptStringToBinary" . Use
      If !DllCall(Dec, "Ptr", &VarIn, "UInt", 0, "UInt", Codec, "Ptr", 0, "UIntP", SizeOut, "Ptr", 0, "Ptr", 0)
         Return False
      VarSetCapacity(VarOut, SizeOut, 0)
      If !DllCall(Dec, "Ptr", &VarIn, "UInt", 0, "UInt", Codec, "Ptr", &VarOut, "UIntP", SizeOut, "Ptr", 0, "Ptr", 0)
         Return False
      Return SizeOut
   }
}

;=================================================================================================
;=================================================================================================
