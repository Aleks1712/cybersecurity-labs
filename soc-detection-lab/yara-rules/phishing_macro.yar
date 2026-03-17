rule CYB2100_Phishing_Macro {
    meta:
        description = "Detekterer VBA-makro fra spearphishing Office-dokument"
        author      = "soc-detection-lab"
        date        = "2025-11-29"
        mitre       = "T1566.001, T1027, T1204.002, T1105, T1070"
        reference   = "completelysafeandnotmalicious.ru/invoice.exe"

    strings:
        $url   = "completelysafeandnotmalicious.ru" ascii
        $path  = "C:\\Appl\\invoice.exe"            ascii
        $api1  = "URLDownloadToFileA"               ascii
        $api2  = "ShellExecuteA"                    ascii
        $macro = "Document_Open"                    ascii

    condition:
        any of them
}
