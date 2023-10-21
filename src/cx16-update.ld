.file                               [name="%O", type="prg", segments="Program"]
.segmentdef Program                 [segments="Basic, Code, Data, CodeOverwrite, DataOverwrite"]
.segmentdef Basic                   [start=$0801]
.segmentdef Code                    [start=%P]
.segmentdef Data                    [startAfter="Code",max=$7800]
.segmentdef CodeOverwrite           [startAfter="Data"] 
.segmentdef DataOverwrite           [startAfter="CodeOverwrite"] 



.segment Basic
:BasicUpstart(%E)
.segment Code
.segment Data

