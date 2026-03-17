rule polymorphic_malware {
    meta:
        description = "Detekterer polymorf skadevare via byte-mønstre på faste offsets"
        author      = "soc-detection-lab"
        date        = "2025-02-22"
        mitre       = "T1027.007"

    strings:
        $stat1 = { 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 }
        $stat2 = { 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 }
        $stat3 = { 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 }

    condition:
        $stat1 at 0 and $stat2 at 256 and $stat3 at 1024
}
