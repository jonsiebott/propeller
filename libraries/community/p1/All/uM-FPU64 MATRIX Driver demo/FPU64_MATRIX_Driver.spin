{{
┌────────────────────────────┬────────────────────┬──────────────────────┐
│  FPU64_MATRIX_Driver v1.1  │ Author: I. Kövesdi │   Rel.: 30 Nov 2011  │
├────────────────────────────┴────────────────────┴──────────────────────┤
│                    Copyright (c) 2011 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This driver object expands the matrix operation command set of the    │
│ uM-FPU64 floating point coprocessor and provides the user a simple     │
│ interface for calculations with vectors and matrices in SPIN programs. │
│ Beside the basic matrix algebra, including copy, equality check,       │
│ transpose, add, subtract, multiply, maximum, minimum, the driver       │
│ implements inversion of square matrices, eigen-decomposition of square │
│ symmetric matrices and singular value decomposition of any rectangular │
│ matrices up to the size of [11-by-11]. A minimal set of vector and     │
│ float operations and float random number generation is provided, too.  │
│ The driver uses one additional COG for the FPU SPI communication.      │
│  It inherits the version number of the latest FPU64_SPI_Driver, from   │
│ which it is expanded.                                                  │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  The FPU provides the user a comprehensive set of IEE 754 32-bit float,│
│ 32-bit long, string, FFT and matrix operations. It also has two 12-bit │
│ ADCs, a programmable serial TTL interface and an NMEA parser. The FPU  │
│ contains Flash memory and EEPROM for storing user defined functions and│
│ data and 128 32-bit registers for float and integer data.              │
│  If your embedded application has anything to do with the physical     │
│ reality, e.g. it deals with position, speed, acceleration, rotation,   │
│ attitude or even with airplane navigation or UAV flight control then   │
│ you should use vectors and matrices in your calculations. A matrix can │
│ be a "storage" for a bunch of related numbers, e.g. a covariance matrix│
│ or can define a transform on a vector or on other matrices. The use of │
│ matrix algebra shines in many areas of computation mathematics as in   │
│ coordinate transformations, rotational dynamics, control theory        │
│ including the Kalman filter. Matrix algebra can simplify complicated   │
│ problems and its rules are not artificial mathematical constructions,  │
│ but come from the nature of the problems and their solutions. A good   │
│ summary that might give you some inspiration is as follows:            │
│                                                                        │
│ "In the worlds of math, engineering and physics, it's the matrix that  │ 
│ separates the men from the boys, the  women from the girls."           │
│                                                (Jack W. Crenshaw).     │
│                                                                        │
│  A matrix is an array of numbers organized in rows and columns. We     │
│ usually give the row number first, then the column. So a [3-by-4]      │
│ matrix has twelve numbers arranged in three rows where each row has a  │
│ length of four                                                         │
│                                                                        │
│                          ┌               ┐                             │
│                          │ 1  2  3   4   │                             │
│                          │ 2  3  4   5   │                             │
│                          │ 3  4  5  6.28 │                             │
│                          └               ┘                             │
│                                                                        │
│  Since computer RAM is organized sequentially, as we access it with a  │
│ single number that we call address, we have to find a way to map the   │
│ two dimensions of the matrix onto the one-dimensional, sequential      │
│ memory. In Propeller SPIN that is rather easy since we can use arrays. │
│ For the previous matrix we can declare an array of LONGs, e.g.         │
│                                                                        │
│                           VAR   LONG mA[12]                            │
│                                                                        │
│ that is large enough to contain the "three times four" 32-bit IEEE 754 │
│ float numbers of the  matrix. In SPIN language the indexing starts with│
│ zero, so the first row, first column element of this matrix is placed  │
│ in mA[0]. The second row, fourth column element is placed in mA[7]. The│
│ general convention that I used with the "FPU_Matrix_Driver.spin" object│
│ is that the ith row, jth column element is accessed at the index       │
│                                                                        │ 
│                          "mA[i,j]" = mA[index]                         │
│                                                                        │
│ where                                                                  │
│                                                                        │
│                      index = (i-1)*(#col) + (j-1)                      │
│                                                                        │
│ and #col = 4 in this example. There are the 'Matrix_Put' and the       │
│ 'Matrix_Get' procedures in the driver to aid the access to the elements│
│ of a matrix. In this example the second row, fourth column element of  │
│ mA can be set to 5.0 using                                             │
│                                                                        │
│            OBJNAME.Matrix_Put(@mA, 5.0, 2, 4, #row, #col)              │
│                                                                  │
│         Address of mA in HUB───┘    │   │  │    │     │                │
│         Float value─────────────────┘   │  │    │     │                │
│         Target indexes──────────────────┻──┘    │     │                │
│         Matrix dimensions───────────────────────┻─────┘                │
│                                                                        │
│ Like in the previous example, the bunch of data in matrices is accessed│
│ by the driver using the starting HUB memory address of the data. For   │
│ example, after you declared mB and mC matrices to be the same [3-by-4] │
│ size as mA                                                             │
│                                                                        │
│                           VAR   LONG mB[12]                            │
│                           VAR   LONG mC[12]                            │
│                                                                        │
│ you can add mB to mC and store the result in mA with the following     │
│ single procedure call                                                  │
│                                                                        │
│  OBJNAME.Matrix_Add(@mA, @mB, @mC, 3, 4)     (meaning mA := mB + mC)   │
│                                                                        │
│ You can't multiply mB with mC, of course, but you can multiply mB with │
│ the transpose of mC. To obtain this transpose use                      │
│                                                                        │
│  OBJNAME.Matrix_Transpose(@mCT, @mC, 3, 4)   (meaning mCT := Tr. of mC)│
│                                                                        │
│ mCT is a [4-by-3] matrix, which can be now multiplied from the left    │
│ with mB as                                                             │
│                                                                        │
│  OBJNAME.Matrix_Multiply(@mD,@mB,@mCT,3,4,3) (meaning mD := mB * mCT)  │
│                                                                        │
│ where the result mD is a [3-by-3] matrix. This matrix algebra coding   │
│ convention can yield compact and easy to debug code. The following 8   │      
│ lines of SPIN code (OBJNAME here is FPUMAT) were taken from the        │
│ 'FPU_ExtendedKF.spin' application and calculate the Kalman gain matrix │
│ from five other matrices (A, P, C, CT, Sz) at a snap                   │
│                                                                        │
│        (    Formula: K = A * P * CT * Inv[C * P * CT + Sz]   )         │
│                                                                        │            
│      FPUMAT.Matrix_Transpose(@mCT, @mC, _R, _N)                        │
│      FPUMAT.Matrix_Multiply(@mAP, @mA, @mP, _N, _N, _N)                │
│      FPUMAT.Matrix_Multiply(@mAPCT, @mAP, @mCT, _N, _N, _R)            │
│      FPUMAT.Matrix_Multiply(@mCP, @mC, @mP, _R, _N, _N)                │
│      FPUMAT.Matrix_Multiply(@mCPCT, @mCP, @mCT, _R, _N, _R)            │
│      FPUMAT.Matrix_Add(@mCPCTSz, @mCPCT, @mSz, _R, _R)                 │
│      FPUMAT.Matrix_Invert(@mCPCTSzInv, @mCPCTSz, _R)                   │       
│      FPUMAT.Matrix_Multiply(@mK, @mAPCT, @mCPCTSzInv, _N, _R, _R)      │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  You can calculate with square or rectangular matrices with the driver.│
│ The only restriction is that the row*column product should be less than│
│ 128. So you can make algebra with, let's say [3-by-37] matrices or with│
│ [91-by-1] vectors. However, both the inverse calculations and the      │
│ eigen-decompositions are for square matrices only, so here the maximum │
│ size is [11-by-11]. Since the singular value decomposition is based    │
│ here on eigen-decomposition, the same size limit applies to the SVD. In│
│ other words, neither row nor column can be larger than 11 for the      │
│ rectangular (or even square) matrix that is submitted to SVD.          │
│  The matrix operations are done with 32-bit FLOATs, the same as with   │
│ the FPU32_MATRIX_Driver.                                               │
│  The MATRIX driver is a member of a family of drivers for the uM-FPU64 │
│ with 2-wire SPI connection. The family has been placed on OBEX:        │
│                                                                        │
│  FPU64_SPI     (Core driver of the FPU64 family)                       │
│  FPU64_ARITH   (Basic arithmetic operations)                           │
│ *FPU64_MATRIX  (Basic and advanced matrix operations)                  │
│  FPU64_FFT     (FFT with advanced options as, e.g. ZOOM FFT)     (soon)│
│                                                                        │
│  The procedures and functions of these drivers can be cherry picked and│
│ used together to build application specific uM-FPU64 drivers.          │
│  Other specialized drivers, as GPS, MEMS, IMU, MAGN, NAVIG, ADC, DSP,  │
│ ANN, STR are in preparation with similar cross-compatibility features  │
│ around the instruction set and with the user defined function ability  │
│ of the uM-FPU64.                                                       │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘
}}


CON

_SMALL =  10
_LARGE =  43
_BIG   = 128

#1,  _INIT, _RST, _CHECK, _WAIT                                   '1-4
#5,  _WRTBYTE, _WRTCMDBYTE, _WRTCMD2BYTES, _WRTCMD3BYTES          '5-8
#9,  _WRTCMD4BYTES, _WRTCMDREG, _WRTCMDRNREG, _WRTCMDSTRING       '9-12
#13, _RDBYTE, _RDREG, _RDSTRING                                   '13-15
#16, _WRTCMDDREG, _WRTCMDRNDREG                                   '16-17
#18, _WRTREGS, _RDREGS                                            '18-19
'These are the enumerated PASM command No.s (_INIT=1, _RST=2,etc..)They
'should be in harmony with the Cmd_Table of the PASM program in the DAT
'section of this object

_MAXSTRL   = 32        'Max string length
_FTOAD     = 40_000    'FTOA delay max 500 us
  
'uM-FPU64 opcodes and indexes---------------------------------------------
_NOP       = $00       'No Operation
_SELECTA   = $01       'Select register A  
_SELECTX   = $02       'Select register X

_CLR       = $03       'Reg[nn] = 0
_CLRA      = $04       'Reg[A] = 0
_CLRX      = $05       'Reg[X] = 0, X = X + 1
_CLR0      = $06       'Reg[0] = 0

_COPY      = $07       'Reg[nn] = Reg[mm]
_COPYA     = $08       'Reg[nn] = Reg[A]
_COPYX     = $09       'Reg[nn] = Reg[X], X = X + 1
_LOAD      = $0A       'Reg[0] = Reg[nn]
_LOADA     = $0B       'Reg[0] = Reg[A]
_LOADX     = $0C       'Reg[0] = Reg[X], X = X + 1
_ALOADX    = $0D       'Reg[A] = Reg[X], X = X + 1
_XSAVE     = $0E       'Reg[X] = Reg[nn], X = X + 1
_XSAVEA    = $0F       'Reg[X] = Reg[A], X = X + 1
_COPY0     = $10       'Reg[nn] = Reg[0]
_LCOPYI    = $11       'Copy immediate value of signed byte as (d)long
                       'into Reg
_SWAP      = $12       'Swap Reg[nn] and Reg[mm]
_SWAPA     = $13       'Swap Reg[A] and Reg[nn]
  
_LEFT      = $14       'Left parenthesis
_RIGHT     = $15       'Right parenthesis
  
_FWRITE    = $16       'Write 32-bit float to Reg[nn]
_FWRITEA   = $17       'Write 32-bit float to Reg[A]
_FWRITEX   = $18       'Write 32-bit float to Reg[X], X = X + 1
_FWRITE0   = $19       'Write 32-bit float to Reg[0]

_FREAD     = $1A       'Read 32-bit float from Reg[nn]
_FREADA    = $1B       'Read 32-bit float from Reg[A]
_FREADX    = $1C       'Read 32-bit float from Reg[X], X = X + 1
_FREAD0    = $1D       'Read 32-bit float from Reg[0]

_ATOF      = $1E       'Convert ASCII string to float, store in Reg[0]
_FTOA      = $1F       'Convert float in Reg[A] to ASCII string.
  
_FSET      = $20       'Reg[A] = Reg[nn] 

_FADD      = $21       'Reg[A] = Reg[A] + Reg[nn]
_FSUB      = $22       'Reg[A] = Reg[A] - Reg[nn]
_FSUBR     = $23       'Reg[A] = Reg[nn] - Reg[A]
_FMUL      = $24       'Reg[A] = Reg[A] * Reg[nn]
_FDIV      = $25       'Reg[A] = Reg[A] / Reg[nn]
_FDIVR     = $26       'Reg[A] = Reg[nn] / Reg[A]
_FPOW      = $27       'Reg[A] = Reg[A] ** Reg[nn]
_FCMP      = $28       'Float compare Reg[A] - Reg[nn]
  
_FSET0     = $29       'Reg[A] = Reg[0]
_FADD0     = $2A       'Reg[A] = Reg[A] + Reg[0]
_FSUB0     = $2B       'Reg[A] = Reg[A] - Reg[0]
_FSUBR0    = $2C       'Reg[A] = Reg[0] - Reg[A]
_FMUL0     = $2D       'Reg[A] = Reg[A] * Reg[0]
_FDIV0     = $2E       'Reg[A] = Reg[A] / Reg[0]
_FDIVR0    = $2F       'Reg[A] = Reg[0] / Reg[A]
_FPOW0     = $30       'Reg[A] = Reg[A] ** Reg[0]
_FCMP0     = $31       'Float compare Reg[A] - Reg[0]  

_FSETI     = $32       'Reg[A] = float(bb)
_FADDI     = $33       'Reg[A] = Reg[A] + float(bb)
_FSUBI     = $34       'Reg[A] = Reg[A] - float(bb)
_FSUBRI    = $35       'Reg[A] = float(bb) - Reg[A]
_FMULI     = $36       'Reg[A] = Reg[A] * float(bb)
_FDIVI     = $37       'Reg[A] = Reg[A] / float(bb) 
_FDIVRI    = $38       'Reg[A] = float(bb) / Reg[A]
_FPOWI     = $39       'Reg[A] = Reg[A] ** bb
_FCMPI     = $3A       'Float compare Reg[A] - float(bb)
  
_FSTATUS   = $3B       'Float status of Reg[nn]
_FSTATUSA  = $3C       'Float status of Reg[A]
_FCMP2     = $3D       'Float compare Reg[nn] - Reg[mm]

_FNEG      = $3E       'Reg[A] = -Reg[A]
_FABS      = $3F       'Reg[A] = | Reg[A] |
_FINV      = $40       'Reg[A] = 1 / Reg[A]
_SQRT      = $41       'Reg[A] = sqrt(Reg[A])    
_ROOT      = $42       'Reg[A] = root(Reg[A], Reg[nn])
_LOG       = $43       'Reg[A] = log(Reg[A])
_LOG10     = $44       'Reg[A] = log10(Reg[A])
_EXP       = $45       'Reg[A] = exp(Reg[A])
_EXP10     = $46       'Reg[A] = exp10(Reg[A])
_SIN       = $47       'Reg[A] = sin(Reg[A])
_COS       = $48       'Reg[A] = cos(Reg[A])
_TAN       = $49       'Reg[A] = tan(Reg[A])
_ASIN      = $4A       'Reg[A] = asin(Reg[A])
_ACOS      = $4B       'Reg[A] = acos(Reg[A])
_ATAN      = $4C       'Reg[A] = atan(Reg[A])
_ATAN2     = $4D       'Reg[A] = atan2(Reg[A], Reg[nn])
_DEGREES   = $4E       'Reg[A] = degrees(Reg[A])
_RADIANS   = $4F       'Reg[A] = radians(Reg[A])
_FMOD      = $50       'Reg[A] = Reg[A] MOD Reg[nn]
_FLOOR     = $51       'Reg[A] = floor(Reg[A])
_CEIL      = $52       'Reg[A] = ceil(Reg[A])
_ROUND     = $53       'Reg[A] = round(Reg[A])
_FMIN      = $54       'Reg[A] = min(Reg[A], Reg[nn])
_FMAX      = $55       'Reg[A] = max(Reg[A], Reg[nn])
  
_FCNV      = $56       'Reg[A] = conversion(nn, Reg[A])
  _F_C       = 0       '├─>F to C
  _C_F       = 1       '├─>C to F
  _IN_MM     = 2       '├─>in to mm
  _MM_IN     = 3       '├─>mm to in
  _IN_CM     = 4       '├─>in to cm
  _CM_IN     = 5       '├─>cm to in
  _IN_M      = 6       '├─>in to m
  _M_IN      = 7       '├─>m to in
  _FT_M      = 8       '├─>ft to m
  _M_FT      = 9       '├─>m to ft
  _YD_M      = 10      '├─>yd to m
  _M_YD      = 11      '├─>m to yd
  _MI_KM     = 12      '├─>mi to km
  _KM_MI     = 13      '├─>km to mi
  _NMI_M     = 14      '├─>nmi to m
  _M_NMI     = 15      '├─>m to nmi
  _ACR_M2    = 16      '├─>acre to m2
  _M2_ACR    = 17      '├─>m2 to acre
  _OZ_G      = 18      '├─>oz to g
  _G_OZ      = 19      '├─>g to oz
  _LB_KG     = 20      '├─>lb to kg
  _KG_LB     = 21      '├─>kg to lb
  _USGAL_L   = 22      '├─>USgal to l
  _L_USGAL   = 23      '├─>l to USgal
  _UKGAL_L   = 24      '├─>UKgal to l
  _L_UKGAL   = 25      '├─>l to UKgal
  _USOZFL_ML = 26      '├─>USozfl to ml
  _ML_USOZFL = 27      '├─>ml to USozfl
  _UKOZFL_ML = 28      '├─>UKozfl to ml
  _ML_UKOZFL = 29      '├─>ml to UKozfl
  _CAL_J     = 30      '├─>cal to J
  _J_CAL     = 31      '├─>J to cal
  _HP_W      = 32      '├─>hp to W
  _W_HP      = 33      '├─>W to hp
  _ATM_KP    = 34      '├─>atm to kPa
  _KP_ATM    = 35      '├─>kPa to atm
  _MMHG_KP   = 36      '├─>mmHg to kPa
  _KP_MMHG   = 37      '├─>kPa to mmHg
  _DEG_RAD   = 38      '├─>degrees to radians
  _RAD_DEG   = 39      '└─>radians to degrees    

_FMAC      = $57       'Reg[A] = Reg[A] + (Reg[nn] * Reg[mm])
_FMSC      = $58       'Reg[A] = Reg[A] - (Reg[nn] * Reg[mm])

_LOADBYTE  = $59       'Reg[0] = float(signed bb)
_LOADUBYTE = $5A       'Reg[0] = float(unsigned byte)
_LOADWORD  = $5B       'Reg[0] = float(signed word)
_LOADUWORD = $5C       'Reg[0] = float(unsigned word)
  
_LOADE     = $5D       'Reg[0] = 2.7182818             
_LOADPI    = $5E       'Reg[0] = 3.1415927
  
_FCOPYI    = $5F       'Copy immediate value of signed byte as float into
                       'Reg

_FLOAT     = $60       'Reg[A] = float(Reg[A])     :LONG to float  
_FIX       = $61       'Reg[A] = fix(Reg[A])       :float to LONG
_FIXR      = $62       'Reg[A] = fix(round(Reg[A])):rounded float to lng
_FRAC      = $63       'Reg[A] = fraction(Reg[A])  
_FSPLIT    = $64       'Reg[A] = int(Reg[A]), Reg[0] = frac(Reg[A])
  
_SELECTMA  = $65       'Select matrix A
_SELECTMB  = $66       'Select matrix B
_SELECTMC  = $67       'Select matrix C
_LOADMA    = $68       'Reg[0] = matrix A[bb, bb]
_LOADMB    = $69       'Reg[0] = matrix B[bb, bb]
_LOADMC    = $6A       'Reg[0] = matrix C[bb, bb]
_SAVEMA    = $6B       'Matrix A[bb, bb] = Reg[0] Please correct TFM!                     
_SAVEMB    = $6C       'Matrix B[bb, bb] = Reg[0] Please correct TFM!                         
_SAVEMC    = $6D       'Matrix C[bb, bb] = Reg[0] Please correct TFM!

_MOP       = $6E       'Matrix operation
  '-------------------------For each r(ow), c(olumn)--------------------
  _SCALAR_SET  = 0     '├─>MA[r, c] = Reg[0]
  _SCALAR_ADD  = 1     '├─>MA[r, c] = MA[r, c] + Reg[0]
  _SCALAR_SUB  = 2     '├─>MA[r, c] = MA[r, c] - Reg[0]
  _SCALAR_SUBR = 3     '├─>MA[r, c] = Reg[0] - MA[r, c] 
  _SCALAR_MUL  = 4     '├─>MA[r, c] = MA[r, c] * Reg[0]
  _SCALAR_DIV  = 5     '├─>MA[r, c] = MA[r, c] / Reg[0]
  _SCALAR_DIVR = 6     '├─>MA[r, c] = Reg[0] / MA[r, c]
  _SCALAR_POW  = 7     '├─>MA[r, c] = MA[r, c] ** Reg[0]
  _EWISE_SET   = 8     '├─>MA[r, c] = MB[r, c]
  _EWISE_ADD   = 9     '├─>MA[r, c] = MA[r, c] + MB[r, c]
  _EWISE_SUB   = 10    '├─>MA[r, c] = MA[r, c] - MB[r, c]                                 
  _EWISE_SUBR  = 11    '├─>MA[r, c] = MB[r, c] - MA[r, c]
  _EWISE_MUL   = 12    '├─>MA[r, c] = MA[r, c] * MB[r, c]
  _EWISE_DIV   = 13    '├─>MA[r, c] = MA[r, c] / MB[r, c]
  _EWISE_DIVR  = 14    '├─>MA[r, c] = MB[r, c] / MA[r, c]
  _EWISE_POW   = 15    '├─>MA[r, c] = MA[r, c] ** MB[r, c]
  '---------------------│-----------------------------------------------
  _MX_MULTIPLY = 16    '├─>MA = MB * MC 
  _MX_IDENTITY = 17    '├─>MA = I = Identity matrix (Diag. of ones)
  _MX_DIAGONAL = 18    '├─>MA = Reg[0] * I
  _MX_TRANSPOSE= 19    '├─>MA = Transpose of MB
  '---------------------│-----------------------------------------------
  _MX_COUNT    = 20    '├─>Reg[0] = Number of elements in MA 
  _MX_SUM      = 21    '├─>Reg[0] = Sum of elements in MA
  _MX_AVE      = 22    '├─>Reg[0] = Average of elements in MA
  _MX_MIN      = 23    '├─>Reg[0] = Minimum of elements in MA 
  _MX_MAX      = 24    '├─>Reg[0] = Maximum of elements in MA
  '---------------------│------------------------------------------------
  _MX_COPYAB   = 25    '├─>MB = MA 
  _MX_COPYAC   = 26    '├─>MC = MA
  _MX_COPYBA   = 27    '├─>MA = MB 
  _MX_COPYBC   = 28    '├─>MC = MB
  _MX_COPYCA   = 29    '├─>MA = MC 
  _MX_COPYCB   = 30    '├─>MB = MC
  '---------------------│-----------------------------------------------
  _MX_DETERM   = 31    '├─>Reg[0]=Determinant of MA (for 2x2 OR 3x3 MA)
  _MX_INVERSE  = 32    '├─>MA = Inverse of MB (for 2x2 OR 3x3 MB)
  '---------------------│-----------------------------------------------
  _MX_ILOADRA  = 33    '├─>Indexed Load Registers to MA
  _MX_ILOADRB  = 34    '├─>Indexed Load Registers to MB
  _MX_ILOADRC  = 35    '├─>Indexed Load Registers to MC
  _MX_ILOADBA  = 36    '├─>Indexed Load MB to MA
  _MX_ILOADCA  = 37    '├─>Indexed Load MC to MA 
  _MX_ISAVEAR  = 38    '├─>Indexed Load MA to Registers
  _MX_ISAVEAB  = 39    '├─>Indexed Load MA to MB
  _MX_ISAVEAC  = 40    '└─>Indexed Load MA to MC

_FFT       = $6F       'FFT operation
  _FIRST_STAGE = 0     '├─>Mode : First stage 
  _NEXT_STAGE  = 1     '├─>Mode : Next stage 
  _NEXT_LEVEL  = 2     '├─>Mode : Next level
  _NEXT_BLOCK  = 3     '├─>Mode : Next block
'-----------------------│-------------------------------------------------
  _BIT_REVERSE = 4     '├─>Mode : Pre-processing bit reverse sort 
  _PRE_ADJUST  = 8     '├─>Mode : Pre-processing for inverse FFT
  _POST_ADJUST = 16    '└─>Mode : Post-processing for inverse FFT
  
_WRIND     = $70       'Write register block
_RDIND     = $71       'Read register block
'Data types
  _INT8        = $08
  _UINT8       = $09
  _INT16       = $0A
  _UINT16      = $0B
  _LONG32      = $0C
  _FLOAT32     = $0D
  _LONG64      = $0E
  _FLOAT64     = $0F
  
_DWRITE    = $72       'Write 64-bit register value
_DREAD     = $73       'Read 64-bit register value

_LBIT      = $74       'Bit clear/set/toggle/test

_SETIND    = $77       'Set indirect pointer value
  _INC         = $80   'Auto-increment the pointer when used
  _DMA         = $10   'DMA buffer pointer
  _REG_LONG    = $00   'Register, LONG integer data
  _REG_FLOAT   = $01   'Register, Floating point data
  _INC_LONG    = $80   'Incremented LONG integer
  _INC_FLOAT   = $81   'Incremented FLOAT
'-------------------------------------------------------------------------    
  _MEM_INT8    = $08
  _MEM_UINT8   = $09
  _MEM_INT16   = $0A
  _MEM_UINT16  = $0B
  _MEM_LONG32  = $0C
  _MEM_FLOAT32 = $0D
  _MEM_LONG64  = $0E
  _MEM_FLOAT64 = $0F
  
_ADDIND    = $78       'Add to indirect pointer value
_COPYIND   = $79       'Copy using indirect pointers

_LOADIND   = $7A       'Reg[0] = indirect(reg[nn]) 
_SAVEIND   = $7B       'Indirect(reg[nn]) = reg[A]
_INDA      = $7C       'Select A using Reg[nn]
_INDX      = $7D       'Select X using Reg[nn]

_FCALL     = $7E       'Call function in Flash memory
_EVENT     = $7F       'Event setup 
  
_RET       = $80       'Return from function
_BRA       = $81       'Unconditional branch
_BRACC     = $82       'Conditional branch
_JMP       = $83       'Unconditional jump
_JMPCC     = $84       'Conditional jump
_TABLE     = $85       'Table lookup
_FTABLE    = $86       'Floating point reverse table lookup
_LTABLE    = $87       'LONG integer reverse table lookup
_POLY      = $88       'Reg[A] = nth order polynomial
_GOTO      = $89       'Computed goto
_RETCC     = $8A       'Conditional return from function
 
_LWRITE    = $90       'Write 32-bit LONG integer to Reg[nn]
_LWRITEA   = $91       'Write 32-bit LONG integer to Reg[A]
_LWRITEX   = $92       'Write 32-bit LONG integer to Reg[X], X = X + 1
_LWRITE0   = $93       'Write 32-bit LONG integer to Reg[0]

_LREAD     = $94       'Read 32-bit LONG integer from Reg[nn] 
_LREADA    = $95       'Read 32-bit LONG integer from Reg[A]
_LREADX    = $96       'Read 32-bit LONG integer from Reg[X], X = X + 1   
_LREAD0    = $97       'Read 32-bit LONG integer from Reg[0]

_LREADBYTE = $98       'Read lower 8 bits of Reg[A]
_LREADWORD = $99       'Read lower 16 bits Reg[A]
  
_ATOL      = $9A       'Convert ASCII to LONG integer
_LTOA      = $9B       'Convert LONG integer to ASCII

_LSET      = $9C       'reg[A] = reg[nn]
_LADD      = $9D       'reg[A] = reg[A] + reg[nn]
_LSUB      = $9E       'reg[A] = reg[A] - reg[nn]
_LMUL      = $9F       'reg[A] = reg[A] * reg[nn]
_LDIV      = $A0       'reg[A] = reg[A] / reg[nn]
_LCMP      = $A1       'Signed LONG compare reg[A] - reg[nn]
_LUDIV     = $A2       'reg[A] = reg[A] / reg[nn]
_LUCMP     = $A3       'Unsigned LONG compare of reg[A] - reg[nn]
_LTST      = $A4       'LONG integer status of reg[A] AND reg[nn] 
_LSET0     = $A5       'reg[A] = reg[0]
_LADD0     = $A6       'reg[A] = reg[A] + reg[0]
_LSUB0     = $A7       'reg[A] = reg[A] - reg[0]
_LMUL0     = $A8       'reg[A] = reg[A] * reg[0]
_LDIV0     = $A9       'reg[A] = reg[A] / reg[0]
_LCMP0     = $AA       'Signed LONG compare reg[A] - reg[0]
_LUDIV0    = $AB       'reg[A] = reg[A] / reg[0]
_LUCMP0    = $AC       'Unsigned LONG compare reg[A] - reg[0]
_LTST0     = $AD       'LONG integer status of reg[A] AND reg[0] 
_LSETI     = $AE       'reg[A] = LONG(bb)
_LADDI     = $AF       'reg[A] = reg[A] + LONG(bb)
_LSUBI     = $B0       'reg[A] = reg[A] - LONG(bb)
_LMULI     = $B1       'Reg[A] = Reg[A] * LONG(bb)
_LDIVI     = $B2       'Reg[A] = Reg[A] / LONG(bb); Remainder in Reg0

_LCMPI     = $B3       'Signed LONG compare Reg[A] - LONG(bb)
_LUDIVI    = $B4       'Reg[A] = Reg[A] / unsigned LONG(bb)
_LUCMPI    = $B5       'Unsigned LONG compare Reg[A] - uLONG(bb)
_LTSTI     = $B6       'LONG integer status of Reg[A] AND uLONG(bb)
_LSTATUS   = $B7       'LONG integer status of Reg[nn]
_LSTATUSA  = $B8       'LONG integer status of Reg[A]
_LCMP2     = $B9       'Signed LONG compare Reg[nn] - Reg[mm]
_LUCMP2    = $BA       'Unsigned LONG compare Reg[nn] - Reg[mm]
  
_LNEG      = $BB       'Reg[A] = -Reg[A]
_LABS      = $BC       'Reg[A] = | Reg[A] |
_LINC      = $BD       'Reg[nn] = Reg[nn] + 1
_LDEC      = $BE       'Reg[nn] = Reg[nn] - 1
_LNOT      = $BF       'Reg[A] = NOT Reg[A]

_LAND      = $C0       'reg[A] = reg[A] AND reg[nn]
_LOR       = $C1       'reg[A] = reg[A] OR reg[nn]
_LXOR      = $C2       'reg[A] = reg[A] XOR reg[nn]
_LSHIFT    = $C3       'reg[A] = reg[A] shift reg[nn]
_LMIN      = $C4       'reg[A] = min(reg[A], reg[nn])
_LMAX      = $C5       'reg[A] = max(reg[A], reg[nn])
_LONGBYTE  = $C6       'reg[0] = LONG(signed byte bb)
_LONGUBYTE = $C7       'reg[0] = LONG(unsigned byte bb)
_LONGWORD  = $C8       'reg[0] = LONG(signed word wwww)
_LONGUWORD = $C9       'reg[0] = LONG(unsigned word wwww)

_LSHIFTI   = $CA        'reg[A] = reg[A] shift bb
_LANDI     = $CB        'reg[A] = reg[A] AND bb
_LORI      = $CC        'reg[A] = reg[A] OR bb

_SETSTATUS = $CD       'Set status byte

_SEROUT    = $CE       'Serial output
_SERIN     = $CF       'Serial Input

_DIGIO     = $D0       'Digital I/O
_ADCMODE   = $D1       'Set A/D trigger mode
_ADCTRIG   = $D2       'A/D manual trigger
_ADCSCALE  = $D3       'ADCscale[ch] = B
_ADCLONG   = $D4       'reg[0] = ADCvalue[ch]
_ADCLOAD   = $D5       'reg[0] = float(ADCvalue[ch]) * ADCscale[ch]
_ADCWAIT   = $D6       'wait for next A/D sample
_TIMESET   = $D7       'time = reg[0]
_TIMELONG  = $D8       'reg[0] = time (LONG)
_TICKLONG  = $D9       'reg[0] = ticks (LONG)
_DEVIO     = $DA       'Device I/O
_DELAY     = $DB       'Delay in milliseconds
_RTC       = $DC       'Real-time clock
_SETARGS   = $DD       'Set FCALL argument mode

_EXTSET    = $E0       'external input count = reg[0]
_EXTLONG   = $E1       'reg[0] = external input counter (LONG)
_EXTWAIT   = $E2       'wait for next external input
_STRSET    = $E3       'Copy string to string buffer
_STRSEL    = $E4       'Set selection point
_STRINS    = $E5       'Insert string at selection point
_STRCMP    = $E6       'Compare string with string buffer
_STRFIND   = $E7       'Find string and set selection point
_STRFCHR   = $E8       'Set field separators
_STRFIELD  = $E9       'Find field and set selection point
_STRTOF    = $EA       'Convert string selection to float
_STRTOL    = $EB       'Convert string selection to LONG
_READSEL   = $EC       'Read string selection
_STRBYTE   = $ED       'Insert 8-bit byte at selection point
_STRINC    = $EE       'increment selection point
_STRDEC    = $EF       'decrement selection point  
 
_SYNC      = $F0       'Get synchronization character 
  _SYNC_CHAR = $5C     '└─>Synchronization character(Decimal 92)
    
_READSTAT  = $F1       'Read status byte 
_READSTR   = $F2       'Read string from string buffer    
_VERSION   = $F3       'Copy version string to string buffer
_IEEEMODE  = $F4       'Set IEEE mode (default)
_PICMODE   = $F5       'Set PIC mode    
_CHECKSUM  = $F6       'Calculate checksum for uM-FPU   

_TRACEOFF  = $F8       'Turn debug trace off
_TRACEON   = $F9       'Turn debug trace on
_TRACESTR  = $FA       'Send string to debug trace buffer
_TRACEREG  = $FB       'Send register value to trace buffer

_READVAR   = $FC       'Read internal variable, store in Reg[0]
  _A_REG     = 0       '├─>Reg[0] = A register
  _X_REG     = 1       '├─>Reg[0] = X register
  _MA_REG    = 2       '├─>Reg[0] = MA register
  _MA_ROWS   = 3       '├─>Reg[0] = MA rows
  _MA_COLS   = 4       '├─>Reg[0] = MA columns
  _MB_REG    = 5       '├─>Reg[0] = MB register
  _MB_ROWS   = 6       '├─>Reg[0] = MB rows
  _MB_COLS   = 7       '├─>Reg[0] = MB columns
  _MC_REG    = 8       '├─>Reg[0] = MC register
  _MC_ROWS   = 9       '├─>Reg[0] = MC rows
  _MC_COLS   = 10      '├─>Reg[0] = MC columns
  _INTMODE   = 11      '├─>Reg[0] = Internal mode word
  _STATBYTE  = 12      '├─>Reg[0] = Last status byte
  _TICKS     = 13      '├─>Reg[0] = Clock ticks per milisecond
  _STRL      = 14      '├─>Reg[0] = Current length of string buffer
  _STR_SPTR  = 15      '├─>Reg[0] = String selection starting point
  _STR_SLEN  = 16      '├─>Reg[0] = String selection length
  _STR_SASC  = 17      '├─>Reg[0] = ASCII char at string selection point
  _INSTBUF   = 18      '├─>Reg[0] = Number of bytes in instr. buffer
  _REVNO     = 19      '├─>Reg[0] = Silicon revision number
  _DEVTYPE   = 20      '└─>Reg[0] = Device type

_SETREAD   = $FD       'This instruction should be used by the foreground
                       'process prior to any read instruction  

_RESET     = $FF       'NOP (but 9 consecutive $FF bytes cause a reset
                       'in SPI protocol)
'Status register bits
_ZERO_BIT  = %0000_0001     'Zero bit mask of the status register  
_SIGN_BIT  = %0000_0010     'Sign bit mask of the status register
_NAN_BIT   = %0000_0100     'Not-a-Number bit mask of the status reg.
_INF_BIT   = %0000_1000     'Infinity bit mask of the status register                         


VAR

LONG   ownCOG
LONG   command, par1, par2, par3, par4, par5

BYTE   str[_MAXSTRL]   'The holder of strings. StartDriver passes the 
                       'address of this byte array to the PASM code when
                       'it calls the COG/#_INIT procedure

LONG     mU[121]   'Auxiliary arrays for matrix multiplication, inversion,
LONG     mP[121]   'eigen-decomposition and singular value decomposition, 
LONG     mV[121]   'index calculations, etc. 121 comes from 11x11



DAT '------------------------Start of SPIN code---------------------------


PUB StartDriver(dio_Pin, clk_Pin, addrCogID_) : oKay
'-------------------------------------------------------------------------
'-----------------------------┌─────────────┐-----------------------------
'-----------------------------│ StartDriver │-----------------------------
'-----------------------------└─────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: -Starts a COG to run uMFPU_Driver
''             -Initializes FPU
''             -Makes a hardware test of the FPU           
'' Parameters: -Propeller pin to the DIO line of the FPU
''             -Propeller pin to the CLK line of the FPU
''             -HUB address of COG ID
''     Result: oKay as boolean
''     Effect: Driver in COG is initialised
''+Reads/Uses: CON/_INIT
''    +Writes: command, ownCOG, par1, par2, par3 
''      Calls: DoCommand>>activates COG/#Init
''       Note: The COG/#Init procedure initialises and checks the FPU
'-------------------------------------------------------------------------
StopDriver                           'Stop previous copy of this driver,
                                     'if any
command~
ownCOG := COGNEW(@uMFPU64, @command) 'Try to start a COG with a PASM
                                     'program from label uMFPU64. It
                                     'passes the adress of HUB/VAL/LONG
                                     'command variabble to the PASM code.
                                     'command must be followed with the
                                     'par1, ..., par5 variables. 
                                     
                                     'If sucesfull then
                                     '  ownCOG = actual COG No.
                                     'else
                                     '  ownCOG = -1

LONG[addrCogID_] := ownCOG++         'Use, then increment ownCOG
                                       
IF (ownCOG)                          'if ownCOG is not zero then
                                     'Own COG has been started.
  par1 := dio_Pin                    'Initialize PASM Driver with passing 
  par2 := clk_Pin                    'the DIO and CLK pins and the pointer
  par3 := @str                       'to the HUB/str BYTE array
                  
  DoCommand(_INIT)           'Trigger COG/#Init procedure
  
  oKay := par1               'Signal back FPU state (from par1)
      
ELSE                         'Else Own COG has not been started

  oKay := FALSE              'Signal back error
 
RETURN oKay                  'if oKay then the driver started and
                             'initialized in OwnCOG and FPU seems to be
                             'present.
'----------------------------End of StartDriver---------------------------


PUB StopDriver                                          
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ StopDriver │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Stops uMFPU_Driver PASM code by freeing its COG
'' Parameters: None
''     Result: None
''     Effect: COG of driver is released
''+Reads/Uses: ownCOG                                  VAR/LONG
''    +Writes: command, ownCOG                         VAR/LONG
''      Calls: None
''       Note: Own COG (to stop) is identified via ownCOG global variable 
'-------------------------------------------------------------------------
command~                             'Clear "command" register
                                     'Here you can initiate a shut off
                                     'PASM routine if necessary 

IF (ownCOG)                          'if ownCOG is not zero then
                                     'it is running so we can stop it
                                     
                                     'Actual COG ID is one less! 
  COGSTOP(ownCOG~ - 1)               'Stop Own COG, then clear ownCOG
'-------------------------------End of StopDriver-------------------------

DAT 'Matrix operations


PUB Matrix_Put(a_, floatV, i, j, r, c) | k                                  
'-------------------------------------------------------------------------
'--------------------------------┌────────────┐---------------------------
'--------------------------------│ Matrix_Put │---------------------------
'--------------------------------└────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Stores a float value into the [i, j] element of the matrix                                                 
'' Parameters: -Address of matrix 
''             -Float value
''             -Indexes of target element
''             -Row and Column of matrix                         
''    Results: None 
''+Reads/Uses: None
''    +Writes: None        
''      Calls: None
'-------------------------------------------------------------------------
IF (i > 0) AND (i =< r) AND (j > 0) AND (j =< c)
  k := (i - 1) * c + (j - 1)
  LONG[a_][k] := floatV
ELSE
  ABORT
'-------------------------------------------------------------------------


PUB Matrix_Get(a_, i, j, r, c) | k                                          
'-------------------------------------------------------------------------
'--------------------------------┌────────────┐---------------------------
'--------------------------------│ Matrix_Get │---------------------------
'--------------------------------└────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads a float value from the [i, j] element of the matrix                                                 
'' Parameters: -Address of matrix array
''             -Indexes of matrix element to read
''             -Row and Column of the matrix                     
''    Results: Float value
''+Reads/Uses: None
''    +Writes: None        
''      Calls: None
'-------------------------------------------------------------------------
IF (i > 0) AND (i =< r) AND (j > 0) AND (j =< c)
  k := (i - 1) * c + (j - 1)
  RESULT := LONG[a_][k]
ELSE
  ABORT
'-------------------------------------------------------------------------


PUB Matrix_LongToFloat(a_, r, c) | size, i, fV                                  
'-------------------------------------------------------------------------
'--------------------------┌────────────────────┐-------------------------
'--------------------------│ Matrix_LongToFloat │-------------------------
'--------------------------└────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Converts Long valued matrix in place to Float valued one                                                 
'' Parameters: -Address of matrix   
''             -Row and Column of matrix      
''    Results: Matrix of the same size but with float format elements
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
''       Note: Primarily for test and debug purposes, original {A} is
''             overwritten
'-------------------------------------------------------------------------
size := r * c
IF (size < _BIG)                       'Check size of matrix  
  'Do conversion inside FPU
  WriteRegs(a_, size, 1)               'Load MA from HUB into FPU

  REPEAT i FROM 2 TO size              'Covert longs to floats in FPU
    WriteCmdByte(_SELECTA, i)
    WriteCmd(_FLOAT)
  WriteCmdByte(_SELECTA, 1)
  WriteCmd(_FLOAT)  

  ReadRegs(2, size - 1, a_ + 4)        'Now reload FPU/MA into HUB/{A}
  WriteCmdByte(_SELECTA, 1)
  WriteCmd(_FREADA)
  fV := ReadReg
  LONG[a_][0] := fV

ELSE
  ABORT   
'-------------------------------------------------------------------------


PUB Matrix_Copy(a_, b_, n, m) | size, fV                                  
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ Matrix__Copy │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Copies {B} into {A}                                                  
'' Parameters: -Address of matrices
''             -Row and Column of matrices
''    Results: {A}={B} 
''+Reads/Uses: None 
''    +Writes: None        
''      Calls: None
''       Note: {A} and {B} has to be the same size
'------------------------------------------------------------------------- 
size := n * m
IF (size < _BIG)                      'Check size of matrix
  LONGMOVE(a_, b_, size)
ELSE
  ABORT
'-------------------------------------------------------------------------


PUB Matrix_EQ(a_,b_,r,c,eps):oKay|sz,sz1,i,maxV,minV,ok1,ok2,v1,v2                                 
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ Matrix_EQ │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Checks equality of {A} and {B} matrices within Epsilon                                               
'' Parameters: -Pointer to matrices
''             -Row and Col of matrices
''             -Epsilon           
''    Results: True if each element of {A} is closer to the corresponding
''             element of {B} than eps 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
''             Float_GT
'------------------------------------------------------------------------
sz := r * c
sz1 := sz - 1
  
IF (sz < _BIG)
  IF ((2 * sz) < _BIG)                     'Check size of matrices 
    'Do it inside FPU
    'Decleare matrices in FPU 
    WriteCmd3Bytes(_SELECTMA, 1, r, c)
    WriteRegs(a_, sz, 1)                  'Load HUB/{A} into FPU/MA
    
    WriteCmd3Bytes(_SELECTMB, 1 + sz, r, c)
    WriteRegs(b_, sz, 1 + sz)             'Load HUB/{B} into FPU/MB
    
    WriteCmdByte(_MOP, _EWISE_SUB)         'Do subraction MA=MA-MB
    WriteCmdByte(_MOP, _MX_MAX)            'Reg[0]=Max. of MA's elements
    Wait
    WriteCmd(_FREAD0)
    maxV := ReadReg   
    WriteCmdByte(_MOP, _MX_MIN)            'Reg[0]=Min. of MA's elements
    Wait
    WriteCmd(_FREAD0)
    minV := ReadReg
    WriteCmdByte(_SELECTA, 127)
    WriteCmdLONG(_FWRITEA, maxV)
    WriteCmd(_FABS)
    Wait
    WriteCmd(_FREADA)
    maxV := ReadReg
    WriteCmdLONG(_FWRITEA, minV)
    WriteCmd(_FABS)
    Wait
    WriteCmd(_FREADA)
    minV := ReadReg        
    ok1 := F32_GT(eps, maxV, 0.0)
    ok2 := F32_GT(eps, minV, 0.0)
    oKay := (ok1 AND ok2)
  ELSE
    'Do it in HUB
    REPEAT i FROM 0 TO sz1
      v1 := LONG[a_][i] 
      v2 := LONG[b_][i]
      oKay := F32_EQ(v1, v2, eps)
      IF (NOT oKay)
        QUIT
ELSE
  ABORT
  
RETURN oKay  
'-------------------------------------------------------------------------


PUB Matrix_Identity(a_, n) | size, fV                                  
'-------------------------------------------------------------------------
'--------------------------┌──────────────────┐---------------------------
'--------------------------│ Matrix__Identity │---------------------------
'--------------------------└──────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Creates an [n-by-n] Identity matrix                                                  
'' Parameters: -Address of matrix
''             -Dimension
''    Results: Diagonal matrix with one-s in the diagonal, zeroes
''             elsewhere
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
'------------------------------------------------------------------------- 
size := n * n
IF (size < _BIG)                      'Check size of matrix
  'Do it inside FPU
  WriteCmd3Bytes(_SELECTMA, 1, n, n)  'Decleare matrix MA in FPU 
  WriteCmdByte(_MOP, _MX_IDENTITY)    'Create NxN Identity matrix MA
      
  ReadRegs(2, size - 1, a_ + 4)       'Now reload matrix MA into HUB
  LONG[a_][0] := 1.0      
ELSE
  ABORT
'-------------------------------------------------------------------------


PUB Matrix_Diagonal(a_, n, floatV) | size, d, i, fV
'-------------------------------------------------------------------------
'--------------------------┌──────────────────┐---------------------------
'--------------------------│ Matrix__Diagonal │---------------------------
'--------------------------└──────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Creates an [n-by-n] diagonal matrix                                                  
'' Parameters: -Address of matrix
''             -Dimension
''             -Float value for the diagonal
''    Results: Diagonal matrix with the given float in the diagonal
''+Reads/Uses:/_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
size := n * n
IF (size < _BIG)                       'Check size of matrix    
  'Do it inside FPU
  WriteCmdLONG(_FWRITE0, floatV) 
  WriteCmd3Bytes(_SELECTMA, 1, n, n)   'Decleare matrix MA in FPU 
  WriteCmdByte(_MOP, _MX_DIAGONAL)     'Create diagonal matrix MA
    
  ReadRegs(2, size - 1, a_ + 4)       'Now reload FPU/MA into HUB/{A}
  WriteCmdByte(_SELECTA, 1)
  WriteCmd(_FREADA)
  fV := ReadReg
  LONG[a_][0] := fV      
ELSE
  ABORT
'-------------------------------------------------------------------------


PUB Matrix_Transpose(a_, b_, n, m) | size, s2, fV, i, j                                 
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ Matrix_Transpose │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Transposes a matrix                                                      
'' Parameters: -Pointer to matrices
''             -Raw and Column of matrices
''    Results: Transpose of {B}
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
''       Note: -{A} is a [m-by-n] matrix, while {B} is [n-by-m].
''             -Does not work for in place transpose 
'-------------------------------------------------------------------------  
size := n * m
IF (size => _BIG)
  ABORT
s2 := 2 * size
IF (s2 < _BIG)                             'Check total size of {A}, {B}
  'Do transpose within FPU
  'Declare MA [NxM], MB [NxM]  
  WriteCmd3Bytes(_SELECTMA, 1, m, n)        
  WriteCmd3Bytes(_SELECTMB, 1 + size, n, m)
   
  WriteRegs(b_, size, 1 + size)            'Load HUB/{B} into FPU/MB
  
  WriteCmdByte(_MOP, _MX_TRANSPOSE)         'MA=MBT 

  ReadRegs(2, size - 1, a_ + 4)             'Reload FPU/MA into HUB/{A}
  WriteCmdByte(_SELECTA, 1)
  WriteCmd(_FREADA)
  fV := ReadReg
  LONG[a_][0] := fV
ELSE
  'Do it in HUB
  REPEAT i FROM 0 TO (n - 1)
    REPEAT j FROM 0 TO (m - 1)
      'A(J,I) = B(I,J) 
      LONG[a_][(j * n) + i] := LONG[b_][(i * m) + j] 
'-------------------------------------------------------------------------


PUB Matrix_Max(a_, r, c) | size                                 
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ Matrix_Max │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Finds the maximum element of a matrix
'' Parameters: -Pointer to matrix in HUB,
''             -Row and Column of matrix                            
''    Results: Max. of elements of matrix
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------  
size := r * c
IF (size < _BIG)                         'Check total size of MB, MA
  'Do within FPU
  'Declare MA
  WriteCmd3Bytes(_SELECTMA, 1, r, c)
   
  WriteRegs(a_, size, 1)                 'Load HUB/{A} into FPU/MA 

  WriteCmdByte(_MOP, _MX_MAX)            'Reg[0]=Max. of MA's elements
  Wait
  WriteCmd(_FREAD0)
  RESULT := ReadReg 
ELSE
  ABORT
'-------------------------------------------------------------------------


PUB Matrix_Min(a_, r, c) | size                                 
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ Matrix_Min │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Finds the minimum element of {A} [NxM] matrix
'' Parameters: -Pointer to matrix  in HUB,
''             -Row and Column of matrix                            
''    Results: Min. of elements of matrix
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------  
size := r * c
IF (size < _BIG)                         'Check total size of MB, MA
  'Do within FPU
  'Declare MA
  WriteCmd3Bytes(_SELECTMA, 1, r, c)
   
  WriteRegs(a_, size, 1)                 'Load HUB/{A} into FPU/MA

  WriteCmdByte(_MOP, _MX_MIN)            'Reg[0]=Max. of MA's elements
  Wait
  WriteCmd(_FREAD0)
  RESULT := ReadReg   
ELSE
  ABORT    
'-------------------------------------------------------------------------


PUB Matrix_Add(a_, b_, c_, r, c) | size, s1, fV, fV1, i                                  
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Matrix_Add │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Adds {B} and {C} matrices and stores the result in {A}                                               
'' Parameters: -Pointer to matrices {A}, {B} and {C} in HUB
''             -Row and Column of matrices                  
''    Results: {A} = {B} + {C} 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: FPU Reg:127, 126        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
size := r * c
IF (size => _BIG)
  ABORT

s1 := size - 1
IF (((2 * size) < _BIG) AND (r > 1) AND (c > 1))
  'Decleare matrices in FPU
  WriteCmd3Bytes(_SELECTMA, 1, r, c)

  WriteRegs(b_, size, 1)               'Load HUB/{B} into FPU/MA
  
  WriteCmd3Bytes(_SELECTMB, 1 + size, r, c)  

  WriteRegs(c_, size, 1 + size)        'Load HUB/{C} into FPU/MB
  
  WriteCmdByte(_MOP, _EWISE_ADD)       'MA=MA+MB 

  ReadRegs(2, size - 1, a_+ 4)         'Reload FPU/MA into HUB/{A}
  WriteCmdByte(_SELECTA, 1)
  WriteCmd(_FREADA)
  LONG[a_][0] := ReadReg   
ELSE
  'Do it in HUB 
  REPEAT i FROM 0 TO s1
    fV := LONG[b_][i]
    fV1 := LONG[c_][i]
    WriteCmdByte(_SELECTA, 127)
    WriteCmdLONG(_FWRITEA, fV1)
    WriteCmdByte(_SELECTA, 126)
    WriteCmdLONG(_FWRITEA, fV)
    WriteCmdByte(_FADD, 127)
    Wait
    WriteCmd(_FREADA)
    LONG[a_][i] := ReadReg  
'-------------------------------------------------------------------------


PUB Matrix_Subtract(a_, b_, c_, r, c) | size, s1, i, fV, fV1                                  
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ Matrix_Subtract │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Subtracts {C} from {B} and writes the result into {A}                                                
'' Parameters: -Pointer to matrices {A}, {B} and {C} in HUB
''             -Row and Column of matrices                  
''    Results: {A} = {B} - {C} 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: FPU Reg: 127, 126        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
size := r * c
IF (size => _BIG)
  ABORT

s1 := size - 1
IF (((2 * size) < _BIG) AND (r > 1) AND (c > 1))
  'Decleare matrices in FPU
  WriteCmd3Bytes(_SELECTMA, 1, r, c)

  WriteRegs(b_, size, 1)               'Load HUB/{B} into FPU/MA
  
  WriteCmd3Bytes(_SELECTMB, 1 + size, r, c)  

  WriteRegs(c_, size, 1 + size)        'Load HUB/{C} into FPU/MB
  
  WriteCmdByte(_MOP, _EWISE_SUB)       'MA=MA-MB
  
  ReadRegs(2, size - 1, a_+ 4)         'Reload FPU/MA into HUB/{A}
  WriteCmdByte(_SELECTA, 1)
  WriteCmd(_FREADA)
  LONG[a_][0] := ReadReg 
ELSE
  'Do it in HUB
  REPEAT i FROM 0 TO s1
    fV := LONG[b_][i]
    fV1 := LONG[c_][i]
    WriteCmdByte(_SELECTA, 127)
    WriteCmdLONG(_FWRITEA, fV1)
    WriteCmdByte(_SELECTA, 126)
    WriteCmdLONG(_FWRITEA, fV)
    WriteCmdByte(_FSUB, 127)
    Wait
    WriteCmd(_FREADA)
    LONG[a_][i] := ReadReg   
'-------------------------------------------------------------------------


PUB Matrix_Multiply(a_,b_,c_,rB,cBrC,cC)|sA,sB,sC,fV,fV1,i,j,k,i1,a1,a2,a3                                  
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ Matrix_Multiply │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies {B} and {C} matrices                                              
'' Parameters: -Pointer to matrices {A}, {B} and {C} in HUB
''             -Row and Column of matrices as
''                      Row of {A},
''                      Col of {B} (=Raw of {C}),
''                      Col of {C} order
''    Results: {A} = {B} * {C} matrix product    
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: FPU Reg:127, 126, 125        
''      Calls: FPU Read/Write procedures
''       Note: The columns of {B} should be equal with the rows of {C},
''             that's why they are specified with a single number cBrC
'-------------------------------------------------------------------------
'Calculate size of matrices
sA := rB * cC
sB := rB * cBrC
sC := cBrC * cC
a3 := cBrC - 1
       
IF ((sA + sB + sC) < _BIG)             'Check total  size
  'Then do it within FPU
  'Check for dot product 
   IF ((rB == 1) AND (cC == 1))
     WriteCmdByte(_CLR, 127)
     REPEAT i FROM 0 TO a3
       fV := LONG[b_][i]
       fV1 := LONG[c_][i]
       WriteCmdByte(_SELECTA, 126)
       WriteCmdLONG(_FWRITEA, fV)
       WriteCmdByte(_SELECTA, 125)
       WriteCmdLONG(_FWRITEA, fV1)
       WriteCmdByte(_FMUL, 126)
       WriteCmdByte(_SELECTA, 127)
       WriteCmdByte(_FADD, 125)
     Wait  
     WriteCmd(_FREADA)
     LONG[a_][0] := ReadReg       
   ELSE
     'Decleare matrices in FPU
     WriteCmd3Bytes(_SELECTMA, 1, rB, cC)  
     WriteCmd3Bytes(_SELECTMB, 1 + sA, rB, cBrC)  

     WriteRegs(b_, sB, 1 + sA)           'Load HUB/{B} into FPU/MB
     
     WriteCmd3Bytes(_SELECTMC, 1 + sA + sB, cBrC, cC) 
      
     WriteRegs(c_, sC, 1 + sA + sB)      'Load HUB/{C} into FPU/MC

     WriteCmdByte(_MOP, _MX_MULTIPLY)    'MA=MB*MC

     ReadRegs(2, sA - 1, a_ + 4)         'Reload FPU/MA into HUB/{A}
     WriteCmdByte(_SELECTA, 1)
     WriteCmd(_FREADA)
     LONG[a_][0] := ReadReg  
ELSE
  'Do it within HUB
  IF ((sA + sB + sC) < (3 * _BIG))
     a1 := rB - 1
     a2 := cC - 1
     REPEAT i FROM 0 TO a2
       mP[i] := i * cC
     REPEAT i FROM 0 TO a3
       mV[i] := i * cBrC
       
    'Multiply HUB/{B} with HUB/{C}
    REPEAT i FROM 0 TO a1
      i1 := mP[i]
      REPEAT j FROM 0 TO a2
        WriteCmdByte(_CLR, 127)
        REPEAT k FROM 0 TO a3
          'Use temp matrix U not to overwrite A in case of e.g. A=A*B
          'U(I,J)=U(I,J)+B(I,K)*C(K,J)        
          fV := LONG[b_][mV[i] + k]
          WriteCmdRnLONG(_FWRITE, 126, fV)
          fV := LONG[c_][mP[k] + j]
          WriteCmdRnLONG(_FWRITE, 125, fV)
          WriteCmdByte(_SELECTA, 126)    
          WriteCmdByte(_FMUL, 125)
          WriteCmdByte(_SELECTA, 127)
          WriteCmdByte(_FADD, 126)
        Wait    
        WriteCmd(_FREADA)
        mU[i1 + j] := ReadReg

    'Now copy U within HUB TO A
    LONGMOVE(a_, @mU, sa)
    
  ELSE   
    ABORT
'-------------------------------------------------------------------------


PUB Matrix_ScalarMultiply(a_, b_, r, c, floatV) | size, i, fV                                
'-------------------------------------------------------------------------
'------------------------┌───────────────────────┐------------------------
'------------------------│ Matrix_ScalarMultiply │------------------------
'------------------------└───────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies {B} with a scalar (float) value and stores in {A}                             
'' Parameters: -Pointer to matrices in HUB                   
''             -Common Row and Column of matrices
''             -Scalar float value
''    Results: {A} = Scalar * {B} 
''+Reads/Uses: /_BIG, FPU CONs
''    +Writes: FPU Reg:0        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
size := r * c
  
IF (size) < _BIG                         'Check size of {B}
  'Load float value into Reg[0]
  WriteCmdLONG(_FWRITE0, floatV)   
  WriteCmd3Bytes(_SELECTMA, 1, r, c)     'Declare FPU/MA

  WriteRegs(b_, size, 1)                 'Load HUB/{B} into FPU/MA

  REPEAT i FROM 1 TO size
    WriteCmdByte(_SELECTA, i)
    WriteCmd(_FMUL0)
    Wait
    WriteCmd(_FREADA)
    LONG[a_][i - 1] := ReadReg
          
ELSE
  ABORT  
'-------------------------------------------------------------------------


PUB Matrix_InvertSmall(a_, b_, n) | size, fV                              
'-------------------------------------------------------------------------
'-------------------------┌────────────────────┐--------------------------
'-------------------------│ Matrix_QuickInvert │--------------------------
'-------------------------└────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Inverts {B} [3 by 3], [2 by 2] or [1 by 1] square matrix                                        
'' Parameters: -Pointer to matrices in HUB
''             -Common Size of matrices             
''    Results: {A}={1/B}=Inverse of {B}
''+Reads/Uses:  /_SMALL, FPU CONs  
''    +Writes: FPU Reg:127        
''      Calls: FPU Read/Write procedures
''       Note: Quick inversion within FPU. It just hangs up and lets you
''             down when {B} is singular (i.e. not invertible).
'-------------------------------------------------------------------------
IF (n > 1)
  size := n * n
  IF size<_SMALL
    'Do inversion with one shot
    WriteCmd3Bytes(_SELECTMA, 1, n, n)        'Declare MA
    WriteCmd3Bytes(_SELECTMB, 1 + size, n, n) 'Declare MB 
  
    WriteRegs(b_, size, 1 + size)             'Load HUB/{B} into FPU/MB
    
    WriteCmdByte(_MOP, _MX_INVERSE)           'MA=1/MB               

    ReadRegs(2, size - 1, a_ + 4)             'Reload FPU/MA into HUB/{A} 
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FREADA)
    LONG[a_][0] := ReadReg
  ELSE
    ABORT  
ELSE
  'Take care of a [1-by-1] matrix
  fV := LONG[b_][0]
  WriteCmdByte(_SELECTA, 127)
  WriteCmdLONG(_FWRITEA, fV)
  WriteCmd(_FINV)
  Wait
  WriteCmd(_FREADA)
  LONG[a_][0] := ReadReg                         
'-------------------------------------------------------------------------


PUB Matrix_Invert(a_, b_, n) | size, s1, st, fV, z, i, j, k, t, n1, i1, i2                              
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Matrix_Invert │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Inverts a square matrix by the method of Gauss-Jordan 
''             eliminations using a pivot technique.                                                
'' Parameters: -Pointers to matrices {A}, {B} in HUB
''             -Common Size of square matrices
''    Results: {A}={1/B} 
''+Reads/Uses: - /FPU CONs
''    +Writes: - FPU Reg: 127, 126, 125, 0
''             - mV, mP, mU arrays in HUB                         
''      Calls: FPU Read/Write procedures
''       Note: - Original {B} matrix is left intact in HUB.
''             - The code here uses the memory very economically and
''             because of the pivoting it has excellent numerical 
''             stability. As compared with naive Gaussian elimination
''             pivoting avoids division by zero and largely reduces (but
''             not completely eliminates) round off error.
'-------------------------------------------------------------------------
IF (n > 1)
  
  IF (n > 11)
    ABORT
      
  size := n * n
  s1 := size - 1
  n1 := n - 1
  REPEAT  i FROM 0 TO n1
    mV[i] := i * n
    
  'Load an identity matrix into the permutation matrix
  WriteCmd3Bytes(_SELECTMA, 1, n, n)  'Decleare FPU/MA 
  WriteCmdByte(_MOP, _MX_IDENTITY)    'Create nxn Identity matrix in it
  
  ReadRegs(2, s1, @mP + 4)            'Reload FPU/MA into HUB/{P}
  WriteCmdByte(_SELECTA, 1)
  WriteCmd(_FREADA)
  mP[0] := ReadReg

  WriteRegs(b_, size, 1)
    
  'Main loop
  REPEAT z FROM 0 TO n1

    'Search for pivot element in z columnn inc. & below diagonal
    WriteCmdByte(_SELECTA, 127)
    WriteCmd(_CLRA)
    REPEAT i FROM z TO n1
      WriteCmd2Bytes(_LOADMA, i, z)
      WriteCmdByte(_SELECTA, 0)
      WriteCmd(_FABS)
      WriteCmdByte(_SELECTA, 127)
      WriteCmd(_FCMP0)
      WriteCmd(_READSTAT)
      st := ReadByte 
      IF (st & _SIGN_BIT)                'Mask Sign Bit
        WriteCmd(_FSET0) 
        t := i

    'Check for singular matrix
    fV := 1E-24
    WriteCmdLONG(_FWRITE0, fV)
    WriteCmd(_FCMP0)
    WriteCmd(_READSTAT)
    st := ReadByte
    IF (st & _SIGN_BIT)                  'Mask Sign Bit
      ABORT
      
    'Swap lines z, t    
    IF (NOT (t == z))
      i1 := mV[z]
      i2 := mV[t] 
      REPEAT i FROM 0 TO n1
        'Swap lines in MA
        WriteCmdByte(_SELECTA, 127)
        WriteCmd2Bytes(_LOADMA, z, i)
        WriteCmd(_FSET0)
        WriteCmd2Bytes(_LOADMA, t, i)
        WriteCmd2Bytes(_SAVEMA, z, i)
        WriteCmdByte(_SELECTA, 0)
        WriteCmdByte(_FSET, 127)
        WriteCmd2Bytes(_SAVEMA, t, i)
        'Swap lines in HUB/{P}
        j := i1 + i
        k := i2 + i
        fV := mP[j]
        mP[j] := mP[k]
        mP[k] := fV

    'Do Gauss-Jordan elimination
    'Calculate 1/A(Z,Z)    
    WriteCmd2Bytes(_LOADMA, z, z)
    WriteCmdByte(_SELECTA, 0) 
    WriteCmd(_FINV)
    WriteCmdByte(_COPY0, 127)
    i1 := mV[z] 
    REPEAT i FROM 0 TO n1
      i2 := mV[i]
      REPEAT j FROM 0 TO n1
        IF (i == z)
          IF (i == j)
            'U(Z,Z)=1/A(Z,Z)
            WriteCmdByte(_SELECTA, 127)
            Wait
            WriteCmd(_FREADA)
            mU[i1 + z] := ReadReg
          ELSE
            'U(I,J)=-A(I,J)/A(Z,Z)
            WriteCmd2Bytes(_LOADMA, i, j)
            WriteCmdByte(_SELECTA, 0)
            WriteCmdByte(_FMUL, 127)
            WriteCmd(_FNEG)
            Wait
            WriteCmd(_FREADA)
            mU[i2 + j] := ReadReg
        ELSE
          IF (j == z)
            'U(I,Z)=A(I,Z)/A(Z,Z)
            WriteCmd2Bytes(_LOADMA, i, z)
            WriteCmdByte(_SELECTA, 0)
            WriteCmdByte(_FMUL, 127)
            Wait
            WriteCmd(_FREADA)
            mU[i2 + z] := ReadReg
          ELSE
            'U(I,J)=A(I,J)-A(Z,J)*A(I,Z)/A(Z,Z)
            WriteCmd2Bytes(_LOADMA, i, j)
            WriteCmdByte(_COPY0, 126)
            WriteCmd2Bytes(_LOADMA, z, j)
            WriteCmdByte(_COPY0, 125)
            WriteCmd2Bytes(_LOADMA, i, z)
            WriteCmdByte(_SELECTA, 0) 
            WriteCmdByte(_FMUL, 125)
            WriteCmdByte(_FMUL, 127)
            WriteCmd(_FNEG)
            WriteCmdByte(_FADD, 126)
            Wait
            WriteCmd(_FREADA)
            mU[i2 + j] := ReadReg

    WriteRegs(@mU, size, 1)              'Reload HUB/{U} to FPU/MA 

  'Main loop finished
    
  'Multiply FPU/MA with {P} to obtain final result
  REPEAT i FROM 0 TO n1
    i1 := mV[i]
    REPEAT j FROM 0 TO n1
      WriteCmdByte(_CLR, 127)
      REPEAT k FROM 0 TO n1
        'U(I,J)=U(I,J)+A(I,K)*P(K,J)            
        fV := mP[mV[k] + j]
        WriteCmdRnLONG(_FWRITE, 126, fV)
        WriteCmd2Bytes(_LOADMA, i, k)
        WriteCmdByte(_SELECTA, 0)    
        WriteCmdByte(_FMUL, 126)
        WriteCmdByte(_SELECTA, 127)
        WriteCmd(_FADD0)
      Wait    
      WriteCmd(_FREADA)
      mU[i1 + j] := ReadReg

  'Now copy {U} within HUB TO {A}
  LONGMOVE(a_, @mU, size)
          
ELSE
  'Take care of a [1-by-1] matrix
  fV := LONG[b_][0]
  WriteCmdByte(_SELECTA, 127)
  WriteCmdLONG(_FWRITEA, fV)
  WriteCmd(_FINV)
  Wait
  WriteCmd(_FREADA)
  LONG[a_][0] := ReadReg                          
'-------------------------------------------------------------------------


PUB Matrix_Eigen(a_,u_,n)|sz,s1,n1,n2,i,i1,j,k1,k2,st,m1,m2,f1                                                                  
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ Matrix_Eigen │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Calculates the eigenvalues and the eigenvectors of an
''             [n-by-n] symmetric matrix by Jacobi's method with pivoting.
''             The result is called eigen-decomposition as it expresses
''             the original matrix with three simple ones:
''
''                     a diagonal one {L} of the eigenvalues and 
''                     orthogonal one {U} of the eigenvectors and
''                                 its transpose {UT}
''
''             The original {A} matrix can be reconstructed from these by
''             the product
''
''                              {A} = {U} * {L} * {UT} 
''
''             These three matrices have usefull algebraic properties.                            
'' Parameters: - Pointers to HUB/{A}, HUB/{U}
''             - Common Size of matrices
''    Results: - Eigenvalues in the diagonal of {L} in place of HUB/{A}
''             - HUB/{U} : n-by-n array of eigenvectors, column wise
''                         stored, this matrix is orthogonal   
''+Reads/Uses: /FPU CONs
''    +Writes: - FPU Reg:127, 126, 125, 124, 123, 122, 0
''             - mV, mU HUB arrays
''      Calls: FPU Read/Write procedures
''       Note: - The Jacobi method consists of a sequence of simple Jacobi
''             rotations designed to zap one pair of the off-diagonal
''             matrix elements. Successive transformations undo previously
''             set zeros, but the off-diagonal elements nevertheless get
''             smaller and smaller, until the matrix is diagonal to preset
''             precision. Accumulating the product of Jacobi rotations as
''             you go gives the matrix of eigenvectors, while the elements
''             of the final diagonal matrix are the eigenvalues.
''             - I used here full pivoting, although it takes some more
''             time then otherwise, to search for the pivot element. The
''             full pivoting ensures a numerically robust procedure. We
''             are using here only 32-bit IEEE 754 floats, so it is worth
''             the effort. 
''             - Original {A} matrix is overwritten in HUB with the diagonal
''             matrix of eigenvalues. This "matrix" form of the eigevalues
''             eigevalues allows the user to work with the eigenvalues  in
''             matrix equations, e.g. like in the restoration of {A},
''             immediately and conveniently. 
''             - The {U} array of eigenvectors is an orthogonal matrix,
''             which means a lot of nice properties but especially that
''
''                                  {U} * {UT} = {I}
''
''             With other words, it's inverse is it's transpose. You can  
''             make easy algebra with {A} expressed in the form as
'' 
''                               {A} = {U} * {L} * {UT}
''
''             For example the inverse of {A} can be obtained quickly as
''
''                             {1/A} = {U} * {1/L} * {UT}
''
''             where {1/L} is just the reciprocals of the diagonal {L}.
''             -Finally, you should not forget that {A} must be square and
''             symmetric to apply eigen-decomposition.
'-------------------------------------------------------------------------
IF (n > 1)
  IF (n > 11)
    ABORT

  sz := n * n
  s1 := sz - 1
  n1 := n - 1
  n2 := n - 2
  REPEAT  i FROM 0 TO n1
    mV[i] := i * n
    
  'Load an identity matrix into the HUB/{U} matrix of eigenvectors
  WriteCmd3Bytes(_SELECTMA, 1, n, n)  'Decleare FPU/MA 
  WriteCmdByte(_MOP, _MX_IDENTITY)    'Create nxn Identity matrix in it
  
  ReadRegs(2, s1, @mU + 4)            'Reload FPU/MA into HUB/{U}
  WriteCmdByte(_SELECTA, 1)
  WriteCmd(_FREADA)
  mU[0] := ReadReg

  'Read in HUB/{A} into FPU/MA
  WriteRegs(a_, sz, 1)

  'Main loop for Jacobi rotations
  REPEAT 200
    
    'Search for pivot element in the lower triangular region
    WriteCmdByte(_SELECTA, 127)
    WriteCmd(_CLRA)
    REPEAT i FROM 0 TO n2
      i1 := i + 1
      REPEAT j FROM i1 TO n1
        WriteCmd2Bytes(_LOADMA, i, j)
        WriteCmdByte(_SELECTA, 0)
        WriteCmd(_FABS)
        WriteCmdByte(_SELECTA, 127)
        WriteCmd(_FCMP0)
        WriteCmd(_READSTAT)
        st := ReadByte
        IF (st & _SIGN_BIT)               'Mask Sign Bit 
          WriteCmd(_FSET0) 
          m1 := i
          m2 := j

    'Check for job done, i.e. off-diagonal elements are small
    f1 := 0.0001                     '1E-4 
    WriteCmdLONG(_FWRITE0, f1)
    WriteCmd(_FCMP0)
    WriteCmd(_READSTAT)
    st := ReadByte
    IF (st & _SIGN_BIT)             'Mask Sign Bit
      QUIT                          'Quit main loop
        
    'Large off-diagonal element is found. We have to rotate  
    'f1 := A(M1,M1) 
    WriteCmd2Bytes(_LOADMA, m1, m1)
    WriteCmdByte(_SELECTA, 126)            'f1
    WriteCmd(_FSET0)

    'f2 := A(M2,M2)
    WriteCmd2Bytes(_LOADMA, m2, m2)
    WriteCmdByte(_SELECTA, 125)            'f2
    WriteCmd(_FSET0)

    'f3 := A(M1,M2)
    WriteCmd2Bytes(_LOADMA, m1, m2)
    WriteCmdByte(_SELECTA, 124)            'f3
    WriteCmd(_FSET0)
      
    'p := 2 * f3 /(f2 - f1)
    'p := ATN(p) / 2
    's := SIN(p)
    'c := COS(p)
    WriteCmdByte(_SELECTA, 127)
    WriteCmdByte(_FSET, 125)
    WriteCmdByte(_FSUB, 126)
    WriteCmd(_FINV)
    WriteCmdByte(_FMUL, 124)
    WriteCmdByte(_FMULI, 2)
    WriteCmd(_ATAN)
    WriteCmdByte(_FDIVI, 2)
      
    WriteCmdByte(_COPYA, 123)              's
    WriteCmdByte(_COPYA, 122)              'c

    WriteCmdByte(_SELECTA, 123)
    WriteCmd(_SIN)

    WriteCmdByte(_SELECTA, 122)
    WriteCmd(_COS)
      
    'We have the sine and cosine of the rotation angle.
    'Now we can modify the matrices
    'A = RT * A * R
    'U = U * R
    REPEAT i FROM 0 TO n1
      IF ((NOT (i == m1)) AND (NOT (i == m2)))
        'f1 := A(I,M1)
        WriteCmd2Bytes(_LOADMA, i, m1)
        WriteCmdByte(_SELECTA, 126)            'f1
        WriteCmd(_FSET0)

        'f2 := A(I,M2)
        WriteCmd2Bytes(_LOADMA, i, m2)
        WriteCmdByte(_SELECTA, 125)            'f2
        WriteCmd(_FSET0)
          
        'f3 := (f1 * c) - (f2 * s)
        WriteCmdByte(_SELECTA, 127)
        WriteCmdByte(_FSET, 125)
        WriteCmdByte(_FMUL, 123)
        WriteCmdByte(_SELECTA, 0)
        WriteCmdByte(_FSET, 126)
        WriteCmdByte(_FMUL, 122)
        WriteCmdByte(_FSUB, 127)

        'Store result 
        'A(I,M1) := f3
        'A(M1,I) := f3
        WriteCmd2Bytes(_SAVEMA, i, m1)
        WriteCmd2Bytes(_SAVEMA, m1, i)
          
        'f3 := (f1 * s) + (f2 * c)
        WriteCmdByte(_SELECTA, 127)
        WriteCmdByte(_FSET, 126)
        WriteCmdByte(_FMUL, 123)
        WriteCmdByte(_SELECTA, 0)
        WriteCmdByte(_FSET, 125)
        WriteCmdByte(_FMUL, 122)
        WriteCmdByte(_FADD, 127)

        'Store result
        'A(I,M2) := f3
        'A(M2,I) := f3
        WriteCmd2Bytes(_SAVEMA, i, m2)
        WriteCmd2Bytes(_SAVEMA, m2, i)

      'Now transform M1, M2 columns of the eigenvector matrix U
      'f1 := U(I,M1)
      k1 := mV[i] + m1
      f1 := mU[k1]
      WriteCmdByte(_SELECTA, 126)         'f1
      WriteCmdLONG(_FWRITEA, f1)

      'f2 := U(I,M2)
      k2 := mV[i] + m2
      f1 := mU[k2]
      WriteCmdByte(_SELECTA, 125)         'f2
      WriteCmdLONG(_FWRITEA, f1)

      'f3 := (f1 * c) - (f2 * s)
      WriteCmdByte(_SELECTA, 127)
      WriteCmdByte(_FSET, 125)
      WriteCmdByte(_FMUL, 123)
      WriteCmdByte(_SELECTA, 0)
      WriteCmdByte(_FSET, 126)
      WriteCmdByte(_FMUL, 122)
      WriteCmdByte(_FSUB, 127)

      'U(I,M1) := f3
      Wait
      WriteCmd(_FREADA)
      mU[k1] := ReadReg

      'f3 := (f1 * s) + (f2 * c)
      WriteCmdByte(_SELECTA, 127)
      WriteCmdByte(_FSET, 126)
      WriteCmdByte(_FMUL, 123)
      WriteCmdByte(_SELECTA, 0)
      WriteCmdByte(_FSET, 125)
      WriteCmdByte(_FMUL, 122)
      WriteCmdByte(_FADD, 127)
                    
      'U(I,M2) := f3
      Wait
      WriteCmd(_FREADA)
      mU[k2] := ReadReg
          
    'Now comes the transformation of the diagonals of A
    'f1 := A(M1,M1)
    WriteCmd2Bytes(_LOADMA, m1, m1)
    WriteCmdByte(_SELECTA, 126)            'f1
    WriteCmd(_FSET0)
      
    'f2 := A(M2,M2)
    WriteCmd2Bytes(_LOADMA, m2, m2)
    WriteCmdByte(_SELECTA, 125)            'f2
    WriteCmd(_FSET0)
      
    'f3 := A(M1,M2)
    WriteCmd2Bytes(_LOADMA, m1, m2)
    WriteCmdByte(_SELECTA, 124)            'f3  (s2)
    WriteCmd(_FSET0)

    's2 := 2*c*s*f3
    WriteCmdByte(_FMUL, 123)               
    WriteCmdByte(_FMUL, 122)
    WriteCmdByte(_FMULI, 2)
      
    's := s*s
    WriteCmdByte(_SELECTA, 123)
    WriteCmdByte(_FMUL, 123)
      
    'c := c*c
    WriteCmdByte(_SELECTA, 122)
    WriteCmdByte(_FMUL, 122)
      
    'f3 := f1*c - s2 + f2*s
    WriteCmdByte(_SELECTA, 127)
    WriteCmdByte(_FSET, 126)
    WriteCmdByte(_FMUL, 122)
    WriteCmdByte(_FSUB, 124)
    WriteCmdByte(_SELECTA, 0)
    WriteCmdByte(_FSET, 125)
    WriteCmdByte(_FMUL, 123)
    WriteCmdByte(_FADD, 127)
      
    'A(M1,M1) := f3
    WriteCmd2Bytes(_SAVEMA, m1, m1)
      
    'f3 := f1*s + s2 + f2*c
    WriteCmdByte(_SELECTA, 127)
    WriteCmdByte(_FSET, 126)
    WriteCmdByte(_FMUL, 123)
    WriteCmdByte(_FADD, 124)
    WriteCmdByte(_SELECTA, 0)
    WriteCmdByte(_FSET, 125)
    WriteCmdByte(_FMUL, 122)
    WriteCmdByte(_FADD, 127)
      
    'A(M2,M2) := f3
    WriteCmd2Bytes(_SAVEMA, m2, m2)
      
    'And clear the pivot, at last...
    WriteCmd(_CLR0)
    'A(M1,M2) := 0
    WriteCmd2Bytes(_SAVEMA, m1, m2)
    'A(M2,M1) := 0
    WriteCmd2Bytes(_SAVEMA, m2, m1)    
     
  'End of main loop here
    
  ReadRegs(2, s1, a_ + 4)        'Reload diagonalized matrix FPU/MA
  WriteCmdByte(_SELECTA, 1)      'to HUB/{A}
  WriteCmd(_FREADA)
  LONG[a_][0] := ReadReg

  'Copy HUB/{mU} TO HUB/{U}
  LONGMOVE(u_, @mU, sz)

ELSE
  'Take care of a [1-by-1] matrix
  LONG[u_][0] := 1.0
'-------------------------------------------------------------------------


PUB Matrix_SVD(a_, u_, v_, n, m) | sz, s1, n1, m1, i, j, k, l, fV                             
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ Matrix_SVD │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Decomposes any [11-by-11] or smaller rectangular [n-by-m]
''             {A} matrix into three simple and easy to invert matrices:
''
''                - Two square and orthogonal ones {U} [n-by-n] and
''                                                 {VT} [m-by-m]
''                - and one (semi) diagonal matrix {SV} that has the
''                  same size as {A}.
''
''             To decompose {A} means to represent {A} faithfully, (i.e.
''             within numerical precision) with the product of easy to 
''             to calculate with matrices: 
'' 
''                                 {A}={U}*{SV}*{VT}
''
''             It's worth mentioning here that {A} can be as simple as a
''             square [n-by-n] matrix. The algorithm works perfectly in
''             that case, too.
'' Parameters: - Pointers to HUB/{A}  [n-by-m] matrix (n<12, m<12)
''                           HUB/{U}  [n-by-n]
''                           HUB/{VT} [m-by-m]
''             - Raw and Column of matrix {A}
''    Results: - {SV} [n-by-m] diagonal matrix in place of HUB/{A}[n-by-m]
''                    It contains the singular values in the (sub)diagonal
''             - {U}  [n-by-n] rectangular orthogonal matrix  
''             - {VT} [m-by-m] rectangular orthogonal matrix
''+Reads/Uses: /FPU CONs
''             - {U}, {P}, {V}  
''    +Writes: FPU Reg: 0      
''      Calls: FPU Read/Write procedures
''             Matrix_Transpose
''             Matrix_Multiply
''             Matrix_Eigen
''       Note: - The product of a matrix by its transpose is obviously
''             square and symmetric, but also (and this is less obvious)
''             its eigenvalues are all positive or null and the
''             eigenvectors corresponding to different eigenvalues are
''             pairwise orthogonal. The SVD algorithm here is based upon
''             the eigen-decomposition of such matrices, either {A}*{AT}
''             or {AT}*{A}, selecting the smaller.    
''             - {SV} has the same size as {A}. The singular values or
''             'principle gains' of {A} lie on the diagonal of {SV} and
''             are the square root of the eigenvalues of both {A}*{AT}
''             and {AT}*{A}, that is, the eigenvectors in {U} and the
''             eigenvectors in {V} share the same eigenvalues. And that
''             means, too, that we have to calculate them only once. We
''             calculate either {U} or {V} (the smaller one) and the
''             corresponding pair is obtained with simple matrix algebra.  
''             The singular values are all positive or zero.
''              Algebra usually simplifies when using the SVD form of {A}.
''             E.g. you can calculate the (pseudo) inverses for any truly
''             rectangular matrix (where n is not equal with m), as well. 
''             The left pseudo inverse, for example, of an arbitrary {A}
''             is
''
''                              {1/A}={V}*{SVRT}*{UT}
''
''             as you can confirm easily that
''
''                             {1/A}*{A}={I}   [m-by-m].
'' 
''             where {SVRT} means the transpose of {SV} with reciprocal
''             of the nonzero values in the diagonal. Pseudo inverses are
''             also called Moore-Penrose inverses.
''              {U} and {V} are orthogonal matrices that can be obtained
''             for any(!) {A} matrix. Because of this it is worth to
''             summarize some useful properties of orthogonal {U}
''             matrices:
''
''                                   {U}*{UT}={I}
''
''                 {U}{x} vector has the same length as {x} vector
''
''             product of any number of orthogonal matrices is orthogonal
''
''                the {U}{S}{UT} transform preserves symmetry of {S}
''
''                       if {U} is symmetric then {U}*{U}={I}
''
''             The fact that orthogonal matrices don't change the length
''             of vectors makes them very desirable in numerical
''             applications since they will not increase rounding errors
''             significantly. They are therefore favored for stable
''             algorithms.
''             - Finally, you should not forget that {A} has not to be
''             either square or symmetric to get it's SVD form to make
''             easy calculations with {U}, {SV} and {V} in your algorithm.  
'-------------------------------------------------------------------------
'Check size    
IF ((n > 11) OR (m > 11))
  ABORT

'Take care of a [1-by-1] matrix
IF ((n == 1) AND (m == 1))
  LONG[u_][0] := 1.0
  LONG[v_][0] := 1.0
  RETURN
  
sz := n * m
s1 := sz - 1
n1 := n - 1
m1 := m - 1
  
'Find smaller side
IF (n =< m)
  'Calculate {A}*{AT} which is [n-by-n]
  Matrix_Transpose(@mP, a_, n, m)
  Matrix_Multiply(@mP, a_, @mP, n, m, n)

  'Do the number crunching
  Matrix_Eigen(@mP, u_, n)

  'Construct {SV} [n-by-m] from [n-by-n] diagonal of eigenvalues
  'At the same sweep calculate essence INV({SV}) in {mU}, as well.
  'Prepare INV({SV}) [m-by-n], fill zeros
  REPEAT i FROM 0 TO m1
    REPEAT j FROM 0 TO n1
      k := (i * n) + j
      mU[k] := 0.0
  'Take square root (and reciprocal for INV({SV}) of the diagonals mP
  WriteCmdByte(_SELECTA, 0)
  REPEAT i FROM 0 TO n1
    k := (i * n) + i
    fV := mP[k]
    WriteCmdLONG(_FWRITEA, fV)
    WriteCmd(_SQRT)
    Wait
    WriteCmd(_FREADA)
    mP[k] := ReadReg
    WriteCmd(_FINV)
    Wait
    WriteCmd(_FREADA)
    mU[k] := ReadReg

  'mU is ready made mP is not. Make it.
  'Augment mP with zeroes
  REPEAT i FROM (n * n) TO ((n * m) - 1)
    mP[i] := 0.0
  'Shift the singular values to the new diagonal
  REPEAT i FROM 1 TO n1
    'Original index of diagonal
    j := i * (n + 1)
    'New index of diagonal
    k := j + i * (m - n)
    mP[k] := mP[j]
    'Clean up
    mP[j] := 0.0
    
  'Up till now mP contains the singular values [n-by-m] and LONG[u_]
  'contains the {U} [n-by-n]
    
  'Now calculate {VT}=INV({SV})*{UT}*{A} directly
  'Calculate {UT}. Let us use mV since mU contains INV({SV})
  Matrix_Transpose(@mV, u_, n, n)
  'Calculate {UT}*{A} 
  Matrix_Multiply(@mV, @mV, a_, n, n, m)
  'Finally {VT}=INV({SV})*{UT}*{A}
  Matrix_Multiply(v_, @mU, @mV, m, n, m)

  'Copy {SV} into HUB/{A}
  LONGMOVE(a_, @mP, sz)
    
ELSE
  'm is smaller than n
  'Calculate {AT}*{A}  which is [m-by-m]
  Matrix_Transpose(@mP, a_, n, m)
  Matrix_Multiply(@mP, @mP, a_, m, n, m)

  'Do the number crunching
  Matrix_Eigen(@mP, v_, m)

  'Construct {SV} [n-by-m] from [m-by-m] diagonal of eigenvalues
  'At the same sweep construct INV({SV}) in {mU}, as well.
  'Prepare INV({SV}) [m-by-n], Fill the zeros  
  REPEAT i FROM 0 TO m1
    REPEAT j FROM 0 TO n1
      k := (i * n) + j
      mU[k] := 0.0
  'Take square root (and reciprocal for INV({SV}) of the diagonals mP
  WriteCmdByte(_SELECTA, 0)
  REPEAT i FROM 0 TO m1
    k := (i * m) + i
    fV := mP[k]
    WriteCmdLONG(_FWRITEA, fV)
    WriteCmd(_SQRT)
    Wait
    WriteCmd(_FREADA)
    mP[k] := ReadReg
    WriteCmd(_FINV)
    Wait
    WriteCmd(_FREADA)
    l := (i * n) + i
    mU[l] := ReadReg
   
  'mU is ready made mP is not. Make it.
  'Augment mP with zeroes
  REPEAT i FROM (m * m) TO ((n * m) - 1)
    mP[i] := 0.0
    
  'Now calculate {U}={A}*{V}*INV({SV}) directly
  'Calculate {A}*{V}, {V} is ready 
  Matrix_Multiply(@mV, a_, v_, n, m, m)
  'Finally {U}={A}*{V}*INV({SV})
  Matrix_Multiply(u_, @mV, @mU, n, m, n)

  'Since we have {V}, calculate {VT}, user assumes that. If we just give
  '{V} TO her/him that would be a breach of contract.
  Matrix_Transpose(v_, v_, m, m)

  'Copy {SV} into HUB/{A}
  LONGMOVE(a_, @mP, sz)
'-------------------------------------------------------------------------


DAT 'Vector operations


PUB Vector_CrossProduct(a_, b_, c_) | b1, b2, b3, c1, c2, c3                              
'-------------------------------------------------------------------------
'------------------------┌─────────────────────┐--------------------------
'------------------------│ Vector_CrossProduct │--------------------------
'------------------------└─────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Calculates the Cross product of {b}, {c} 3D space vectors                                               
'' Parameters: Pointers to HUB/{a}, HUB/{b} and HUB/{c} [3x1] matrices                      
''    Results: {a}={b}x{c} 
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126, 125, 124        
''      Calls: FPU Read/Write procedures
''       Note: This operation is specialized to 3D "space" vectors
''             Vector dot product can be done with Matrix_Multiply as
''             Matrix_Multiply(@dp, @v1, @v2, 1, n, 1) where n is the
''             dimension of the vectors. This means that the dot product
''             is not specialized for 3 dimensional vectors 
'-------------------------------------------------------------------------
b1 := LONG[b_][0]
b2 := LONG[b_][1]
b3 := LONG[b_][2]
c1 := LONG[c_][0]
c2 := LONG[c_][1]
c3 := LONG[c_][2]
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, b3)
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, c2)
WriteCmdByte(_FMUL, 127)
WriteCmdByte(_SELECTA, 125)
WriteCmdLONG(_FWRITEA, b2)
WriteCmdByte(_SELECTA, 124)
WriteCmdLONG(_FWRITEA, c3)
WriteCmdByte(_FMUL, 125)
WriteCmdByte(_FSUB, 126)
Wait
WriteCmd(_FREADA)
LONG[a_][0] := ReadReg
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, b1)
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, c3)
WriteCmdByte(_FMUL, 127)
WriteCmdByte(_SELECTA, 125)
WriteCmdLONG(_FWRITEA, b3)
WriteCmdByte(_SELECTA, 124)
WriteCmdLONG(_FWRITEA, c1)
WriteCmdByte(_FMUL, 125)
WriteCmdByte(_FSUB, 126)
Wait
WriteCmd(_FREADA)
LONG[a_][1] := ReadReg
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, b2)
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, c1)
WriteCmdByte(_FMUL, 127)
WriteCmdByte(_SELECTA, 125)
WriteCmdLONG(_FWRITEA, b1)
WriteCmdByte(_SELECTA, 124)
WriteCmdLONG(_FWRITEA, c2)
WriteCmdByte(_FMUL, 125)
WriteCmdByte(_FSUB, 126)
Wait
WriteCmd(_FREADA)
LONG[a_][2] := ReadReg 
'-------------------------------------------------------------------------


PUB Vector_Norm(a_) | a1, a2, a3                                      
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Vector_Norm │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Calculates the length of a 3D space vector                                               
'' Parameters: Pointers to HUB/{a} [3-by-1] matrix                   
''    Results: Length of {a} 
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126        
''      Calls: FPU Read/Write procedures
''       Note: Programmed for 3 dimensional vectors. You can easily code
''             it for the n dimensional case with n as a parameter
'-------------------------------------------------------------------------
a1 := LONG[a_][0]
a2 := LONG[a_][1]
a3 := LONG[a_][2]
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, a1)
WriteCmdByte(_FMUL, 127)
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, a2)
WriteCmdByte(_FMUL, 126)
WriteCmdByte(_FADD, 127)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, a3)
WriteCmdByte(_FMUL, 127)
WriteCmdByte(_FADD, 126)
WriteCmd(_SQRT)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'-------------------------------------------------------------------------


PUB Vector_Unitize(a_, b_) | l, b1, b2, b3                 
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Vector_Unitize │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Calculates unit vector in direction of {b}                                                
'' Parameters: Pointers to HUB/{a}, {b} [3-by-1] matrices (3D space vect.)                     
''    Results: {a}={b}/Norm({b}) 
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126        
''      Calls: WFPU Read/Write procedures
''       Note: Programmed for 3 dimensional vectors. You can easily code
''             it for the n dimensional case with n as a parameter
'-------------------------------------------------------------------------
l := Vector_Norm(b_)
b1 := LONG[b_][0]
b2 := LONG[b_][1]
b3 := LONG[b_][2]
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, l)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, b1)
WriteCmdByte(_FDIV, 126)
Wait
WriteCmd(_FREADA)
LONG[a_][0] := ReadReg
WriteCmdLONG(_FWRITEA, b2)
WriteCmdByte(_FDIV, 126)
Wait
WriteCmd(_FREADA)
LONG[a_][1] := ReadReg
WriteCmdLONG(_FWRITEA, b3)
WriteCmdByte(_FDIV, 126)
Wait
WriteCmd(_FREADA)
LONG[a_][2] := ReadReg
'-------------------------------------------------------------------------


DAT 'Random numbers


PUB Rnd_Float_UnifDist(seed)                                  
'-------------------------------------------------------------------------
'---------------------------┌────────────────────┐------------------------
'---------------------------│ Rnd_Float_UnifDist │------------------------
'---------------------------└────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Calculates a pseudo random 32-bit FLOAT value from seed                                                 
'' Parameters: Seed                       
''    Results: Pseudo random float values that are uniformly distributed 
''             on the [0,1] intervall when the last value used as the seed 
''             for the next one.
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
''       Note: rndF=FRAC((PI+seed)^5)
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, seed)
WriteCmd(_LOADPI)
WriteCmd(_FADD0)
WriteCmdByte(_FPOWI, 5)
WriteCmd(_FRAC)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg 
'-------------------------------------------------------------------------


PUB Rnd_Float_NormDist(seed, avr, sd) | rnd1, rnd2                                        
'-------------------------------------------------------------------------
'-------------------------┌────────────────────┐--------------------------
'-------------------------│ Rnd_Float_NormDist │--------------------------
'-------------------------└────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Calculates a normally distributed pseudo random float value                                                    
'' Parameters: - Float seed value from [0, 1] interval,
''             - Mean,
''             - Standard Deviation
''    Results: Pseudo random floats that are normally distributed around
''             avr with a standard deviation sd when this routine is fed
''             with uniformly distributed random seed values from the
''             [0, 1] interval.
''+Reads/Uses: /Some FPU constants from the DAT section
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures          
''       Note: RESULT=avr+sd*SQRT((-2*LOG(rnd1)))*COS(2*PI*rnd2)
''             This routine is handy to simulate Gaussian noise.
'-------------------------------------------------------------------------
rnd1 := Rnd_Float_UnifDist(seed)
rnd2 := Rnd_Float_UnifDist(rnd1)
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, rnd1)
WriteCmd(_LOADPI)
WriteCmd(_FMUL0)
WriteCmdByte(_FMULI, 2)
WriteCmd(_COS)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, rnd2)
WriteCmd(_LOG)
WriteCmdByte(_FMULI, -2)
WriteCmd(_SQRT)
WriteCmdByte(_FMUL, 126)
WriteCmdLONG(_FWRITE0, sd)
WriteCmd(_FMUL0)
WriteCmdLONG(_FWRITE0, avr)
WriteCmd(_FADD0)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'-------------------------------------------------------------------------


PUB Rnd_Long_UnifDist(rndF, minL, maxL)                                  
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Rnd_Long_UnifDis │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Calculates a uniformly distributed pseudo random long value
''             from a pseudo random float value drawn from the interval
''             [0, 1]                                                
'' Parameters: - Random float value
''             - Minimum and Maximum of long values                     
''    Results: Pseudo random long values will be drawn from the [Min, Max] 
''             closed interval according to the random float value
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126, 125, 0       
''      Calls: FPU Read/Write procedures  
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_LWRITEA, minL)
WriteCmd(_FLOAT)
WriteCmdByte(_SELECTA, 125)
WriteCmdByte(_FSET, 126)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_LWRITEA, maxL)
WriteCmd(_FLOAT)
WriteCmdByte(_FSUB, 126)
WriteCmdByte(_FADDI, 1)
WriteCmdRnLONG(_FWRITE, 126, rndF)
WriteCmdByte(_FMUL, 126)
WriteCmdByte(_FADD, 125)
WriteCmd(_FLOOR)
WriteCmd(_FIX)
Wait
WriteCmd(_LREADA)
RESULT := ReadReg 
'-------------------------------------------------------------------------


DAT 'Float comparisons


PUB F32_EQ(fv1, fv2, eps) | status                                 
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ Float_EQ │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Checks equality of two floats within epsilon                                                    
'' Parameters: - Value1
''             - Value2
''             - Epsilon    
''    Results: TRUE if (ABS(Value1-Value2) < Epsilon) else FALSE
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: With Epsilon=0.0 you can test "true" equality. However,
''             that is sometimes misleading in floating point calculations
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, fv1)
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, fv2)
WriteCmdByte(_FSUB, 127)
WriteCmd(_FABS)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, eps)
WriteCmd(_FABS)   
WriteCmdByte(_FCMP, 126)
Wait   
WriteCmd(_READSTAT)
status := ReadByte
RESULT := NOT (status & _SIGN_BIT)
'-------------------------------------------------------------------------


PUB F32_GT(fv1, fv2, eps) | status                                 
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ Float_GT │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Checks that Value1 is greater or not than Value2 with a
''             margin.                                                   
'' Parameters: - Value1
''             - Value2
''             - Epsilon    
''    Results: TRUE if (Value1-Value2)>Epsilon else FALSE
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: You can use eps=0.0, of course
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, fv2)
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, fv1)
WriteCmdByte(_FSUB, 127)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, eps)
WriteCmd(_FABS)   
WriteCmdByte(_FCMP, 126)
Wait   
WriteCmd(_READSTAT)
status := ReadByte
RESULT := status & _SIGN_BIT           'Sign bit in FPU's status byte
'-------------------------------------------------------------------------


DAT 'Float operations           


PUB F32_INV(fV)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_INV │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Takes reciprocal of a float value                           
'' Parameters: Float Value
''    Results: Reciprocal of argument
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
''       Note: No check for zero or NaN argument 
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, fV)
WriteCmd(_FINV)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'-------------------------------------------------------------------------


DAT 'Core FPU64 procedures


PUB Reset                                 
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ Reset │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Initiates a Software Reset of the FPU                                                 
'' Parameters: None                      
''     Result: TRUE if reset was succesfull else FALSE
''+Reads/Uses: CON/_RST
''    +Writes: HUB/VAR/LONG command, par1        
''      Calls: DoCommand>>activates #Rst (in COG)
'-------------------------------------------------------------------------
DoCommand(_RST)

RESULT := par1               'Read back FPU's READY status
'-------------------------------End of Reset------------------------------                                                                    


PUB CheckReady                            
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ CheckReady │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Checks for an empty instruction buffer of the FPU. It
''             returns the result immediately and does not wait for that
''             "READY" state unlike the Wait command, which does wait                             
'' Parameters: None                      
''     Result: TRUE if FPU is idle else FALSE
''+Reads/Uses: CON/_CHECK    
''    +Writes: HUB/VAR/par1        
''      Calls: DoCommand>>activates #CheckForReady (in COG)
'-------------------------------------------------------------------------
DoCommand(_CHECK)
 
RESULT := par1
'-----------------------------End of CheckReady---------------------------


PUB Wait                                   
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Wait │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Waits for FPU ready                             
'' Parameters: None                      
''     Result: None 
''+Reads/Uses: CON/_WAIT    
''    +Writes: None        
''      Calls: DoCommand>>activates #WaitForReady (in COG)
'-------------------------------------------------------------------------
DoCommand(_WAIT)
'--------------------------------End of Wait------------------------------


PUB ReadSyncChar                                              
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ ReadSyncChar │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads syncronization character from FPU                             
'' Parameters: None                      
''     Result: Sync Char response of FPU (should be $5C=dec 92 if FPU OK)  
''+Reads/Uses: CON/_SYNC    
''    +Writes: None        
''      Calls: -WriteCmd
''             -ReadByte
''       Note: No Wait here before the read operation
'-------------------------------------------------------------------------
WriteCmd(_SYNC)

RESULT := ReadByte
'----------------------------End of ReadSyncChar--------------------------


PUB ReadInterVar(index)                                            
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ ReadInterVar │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads an Internal Variable from FPU                           
'' Parameters: Index of variable        
''     Result: Selected Internal variable of FPU
''+Reads/Uses: HUB/CON/_SETREAD, _READVAR, _LREAD0   
''    +Writes: None        
''      Calls: -WriteCmdByte
''             -Wait
''             -WriteCmd
''             -ReadReg
'-------------------------------------------------------------------------
writeCmd(_SETREAD)
WriteCmdByte(_READVAR, index)
Wait
WriteCmd(_LREAD0)
RESULT := ReadReg                
'-----------------------------End of ReadInterVar-------------------------


PUB ReadRaFloatAsStr(format)
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ ReadRaFloatAsStr │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Reads the FLOAT value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB/BYTE[_MAXSTRL] str                           
'' Parameters: Format of string in FPU convention        
''     Result: Pointer to string HUB/str
''+Reads/Uses: CON/_FTOA, _FTOAD   
''    +Writes: None        
''      Calls: -WriteCmdByte
''             -Wait
''             -ReadStr
''       Note: _MAXSTRL = 32 in this version 
'-------------------------------------------------------------------------
WriteCmdByte(_FTOA, format)
WAITCNT(_FTOAD + CNT)
Wait
RESULT := ReadStr
'-------------------------End of ReadRaFloatAsStr-------------------------


PUB ReadRaLongAsStr(format)
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ ReadRaLongAsStr │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads the LONG value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB/BYTE[_MAXSTRL] str                          
'' Parameters: Format of string in FPU convention        
''     Result: Pointer to string HUB/str
''+Reads/Uses: CON/_LTOA, _FTOAD   
''    +Writes: None        
''      Calls: -WriteCmdByte
''             -Wait
''             -ReadStr
'-------------------------------------------------------------------------
WriteCmdByte(_LTOA, format)
WAITCNT(_FTOAD + CNT)
Wait
RESULT := ReadStr
'--------------------------End of ReadRaLongAsStr-------------------------


PUB WriteCmd(cmd)                                    
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ WriteCmd │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte to FPU                           
'' Parameters: Command byte                       
''     Result: None
''+Reads/Uses: CON/_WRTBYTE    
''    +Writes: VAR/LONG/par1        
''      Calls: DoCommand>>activates #WrtByte (in COG)
'-------------------------------------------------------------------------
par1 := cmd

DoCommand(_WRTBYTE)
'------------------------------End of WriteCmd----------------------------


PUB WriteCmdByte(cmd, byt)                            
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ WriteCmdByte │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus a Data byte to FPU          
'' Parameters: -Command byte
''             -Data byte
''     Result: None
''+Reads/Uses: CON/_WRTCMDBYTE  
''    +Writes: VAR/LONG/par1, par2        
''      Calls: DoCommand>>activates #WrtCmdByte (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := byt

DoCommand(_WRTCMDBYTE)
'----------------------------End of WriteCmdByte--------------------------


PUB WriteCmd2Bytes(cmd, b1, b2)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd2Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 2 Data bytes to FPU          
'' Parameters: -Command byte
''             -Data bytes 1, 2
''     Result: None
''+Reads/Uses: CON/_WRTCMD2BYTES  
''    +Writes: VAR/LONG/par1, par2, par3        
''      Calls: DoCommand>>activates #WrtCmd2Bytes (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := b1
par3 := b2

DoCommand(_WRTCMD2BYTES)
'---------------------------End of WriteCmd2Bytes-------------------------


PUB WriteCmd3Bytes(cmd, b1, b2, b3)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd3Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 3 Data bytes to FPU          
'' Parameters: -Command byte
''             -Data bytes 1...3
''     Result: None
''+Reads/Uses: CON/_WRTCMD3BYTES  
''    +Writes: VAR/LONG/par1, par2, par3, par4        
''      Calls: DoCommand>>activates #WrtCmd3Bytes (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := b1
par3 := b2
par4 := b3

DoCommand(_WRTCMD3BYTES)
'--------------------------End of WriteCmd3Bytes--------------------------


PUB WriteCmd4Bytes(cmd, b1, b2, b3, b4)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd4Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 4 Data bytes to FPU          
'' Parameters: -Command byte
''             -Data bytes 1...4
''     Result: None
''+Reads/Uses: CON/_WRTCMD4BYTES  
''    +Writes: VAR/LONG/par1, par2, par3, par4, par5        
''      Calls: DoCommand>>activates #WrtCmd4Bytes (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := b1
par3 := b2
par4 := b3
par5 := b4

DoCommand(_WRTCMD4BYTES)
'--------------------------End of WriteCmd4Bytes--------------------------


PUB WriteCmdLong(cmd, longVal)                            
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ WriteCmdLong │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte plus a 32-bit LONG value to FPU          
'' Parameters: -Command byte
''             -32-bit LONG value
''     Result: None
''+Reads/Uses: CON/_WRTCMDREG  
''    +Writes: VAR/LONG/par1, par2        
''      Calls: DoCommand>>activates #WrtCmdReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := longVal

DoCommand(_WRTCMDREG)
'--------------------------End of WriteCmdLong----------------------------


PUB WriteCmdDLong(cmd, longValMSL, longValLSL)                            
'-------------------------------------------------------------------------
'----------------------------┌───────────────┐----------------------------
'----------------------------│ WriteCmdDLong │----------------------------
'----------------------------└───────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte plus a 64-bit DLONG value to FPU          
'' Parameters: -Command byte
''             -32-bit LONG value: Most Significant LONG of DLONG
''             -32-bit LONG value: Least Significant LONG of DLONG
''     Result: None
''+Reads/Uses: CON/_WRTCMDDREG  
''    +Writes: VAR/LONG/par1, par2, par3        
''      Calls: DoCommand>>activates #WrtCmdDReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := longValMSL
par3 := longValLSL

DoCommand(_WRTCMDDREG)
'---------------------------End of WriteCmdDlong--------------------------


PUB WriteCmdRnLong(cmd, regN, longVal)
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmdRnLong │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + RegNo byte + LONG data to FPU                          
'' Parameters: -Command byte
''             -RegNo byte
''             -LONG (32-bit) data                      
''     Result: None
''+Reads/Uses: CON/_WRTCMDRNREG   
''    +Writes: VAR/LONG/par1, par2, par3        
''      Calls: DoCommand>>activates  #WrtCmdRnReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := regN
par3 := longVal

DoCommand(_WRTCMDRNREG)
'--------------------------End of WriteCmdRnLONG--------------------------


PUB WriteCmdRnDLong(cmd, regN, longValMSL, longValLSL)
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ WriteCmdRnDLong │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + RegNo byte + LONG data to FPU                          
'' Parameters: -Command byte
''             -RegNo byte
''             -LONG (32-bit) data for MSL of 64-bit DLONG
''             -LONG (32-bit) data for LSL of 64-bit DLONG        
''     Result: None
''+Reads/Uses: CON/_WRTCMDRNREG   
''    +Writes: VAR/LONG/par1, par2, par3        
''      Calls: DoCommand>>activates #WrtCmdRnReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := regN
par3 := longValMSL
par4 := longValLSL

DoCommand(_WRTCMDRNDREG)
'--------------------------End of WriteCmdRnDLong-------------------------


PUB WriteCmdStr(cmd, strPtr)
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ WriteCmdStr │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + a String into FPU                          
'' Parameters: -Command byte
''             -Pointer to HUB/String                      
''     Result: None
''+Reads/Uses: CON/_WRTCMDSTRING     
''    +Writes: VAR/LONG/par1, par2       
''      Calls: DoCommand>>activates #WrtCmdString (in COG)
''       Note: No need for counter byte, zero terminates string
'-------------------------------------------------------------------------
par1 := cmd
par2 := strPtr

DoCommand(_WRTCMDSTRING)
'-----------------------------End of WriteCmdStr--------------------------


PUB WriteRegs(fromHUBAddr_, cntr, startFPUReg)
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ WriteRegs │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a 32-bit data array into FPU                          
'' Parameters: -Pointer to HUB address of data array
''             -Counter byte
''             -Register from where 32-bit data array is stored in FPU                
''     Result: None
''+Reads/Uses: CON/_WRTREGS     
''    +Writes: par1, par2, par3         
''      Calls: #WrtRegs (in COG)
''       Note: Cntr byte is the # of 32-bit data
'-------------------------------------------------------------------------
par1 := fromHUBAddr_
par2 := cntr
par3 := startFPUReg
DoCommand(_WRTREGS)
'------------------------------End of WriteRegs---------------------------


PUB ReadByte                                              
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadByte │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads a byte from FPU                           
'' Parameters: None                      
''     Result: Byte from FPU
''+Reads/Uses: CON/_RDBYTE
''    +Writes: VAR/LONG/par1        
''      Calls: DoCommand>>activates #RByte (in COG)
'-------------------------------------------------------------------------
DoCommand(_RDBYTE)

RESULT := par1               'Get fpuByte from par1
'------------------------------End of ReadByte----------------------------


PUB ReadReg                                             
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadReg │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a 32-bit Register from FPU                           
'' Parameters: None                      
''     Result: 32-bit LONG from FPU
''+Reads/Uses: CON/_RDREG    
''    +Writes: VAR/LONG/par1        
''      Calls: DoCommand>>activates #RdReg (in COG)
''       Note: To read 64-bit FPU registers, use this twice
'-------------------------------------------------------------------------
DoCommand(_RDREG)

RESULT := par1               'Get 32-bit register data from par1
'------------------------------End of ReadReg-----------------------------


PUB ReadStr                                             
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadStr │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a String from FPU                           
'' Parameters: None                      
''     Result: Pointer to HUB/str where the string from the FPU is copied
''+Reads/Uses: -CON/_SETREAD, _RDSTRING
''             -Pointer to VAR/BYTE[_MAXSTRL] str    
''    +Writes: None        
''      Calls: DoCommand>>activates #RdString (in COG)
'-------------------------------------------------------------------------
WriteCmd(_SETREAD)

DoCommand(_RDSTRING)

RESULT := @str               'Pointer to HUB/str
'-------------------------------------------------------------------------


PUB ReadRegs(fromFPUReg , cntr, startHUBAddress_)
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadRegs │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads a 32-bit data array from the FPU                          
'' Parameters: -FPU register # from where 32-bit data array is read
''             -Counter byte
''             -HUB address from where 32-bit data array is stored                
''     Result: None
''+Reads/Uses: CON/_RDREGS     
''    +Writes: par1, par2, par3         
''      Calls: #RdRegs (in COG)
''       Note: Cntr byte is the # of 32-bit data
'-------------------------------------------------------------------------
WriteCmd(_SETREAD)

par1 := fromFPUReg
par2 := cntr
par3 := startHUBAddress_
DoCommand(_RDREGS)
'------------------------------End of ReadRegs----------------------------


PRI DoCommand(cmd)
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ DoCommand │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: -Initiates a PASM routine via the command register in HUB
''             -Waits for the completition of PASM routine             
'' Parameters: Code of command                      
''     Result: Directly none, PASM routine is performed
''+Reads/Uses: None    
''    +Writes: command        
''      Calls: Corresponding PASM routines in COG
''       Note: Waits until command register is zeroed by the PASM code
'-------------------------------------------------------------------------
command := cmd
REPEAT WHILE command
'-----------------------------End of DoCommand----------------------------


DAT '-------------------------Start of PASM code-------------------------- 
'-------------------------------------------------------------------------
'-------------DAT section for PASM program and COG registers--------------
'-------------------------------------------------------------------------

uMFPU64  ORG             0             'Start of PASM code

Get_Command                            'Entry label of fetch command loop

RDLONG   r1,             PAR WZ        'Read "command" register from HUB
IF_Z     JMP             #Get_Command  'Wait for a nonzero value

                                       'If dropped here, then command
                                       'received

ADD      r1,             #Cmd_Table-1  'Add it to the value of
                                       '#Cmd_Table-1

JMP      r1                            'Jump to command in Cmd_Table
                                       'JMP counts jumps in register units    
                                     
Cmd_Table                              'Command dispatch table
JMP      #Init                         '(Init=command No.1)
JMP      #Rst                          '(Reset=command No.2)
JMP      #CheckForReady                '(Check=command No.3)
JMP      #WaitForReady                 '(Wait=command No.4)
JMP      #WrtByte                      '(WrtByte=command No. 5)
JMP      #WrtCmdByte                   '(WrtCmdByte=command No. 6)
JMP      #WrtCmd2Bytes                 '(WrtCmd2Bytes=command No. 7)
JMP      #WrtCmd3Bytes                 '(WrtCmd3Bytes=command No. 8)
JMP      #WrtCmd4Bytes                 '(WrtCmd4Bytes=command No. 9)
JMP      #WrtCmdReg                    '(WrtCmdReg=command No. 10)
JMP      #WrtCmdRnReg                  '(WrtCmdRnReg=command No. 11)
JMP      #WrtCmdString                 '(WrtCmdString=command No. 12)
JMP      #RByte                        '(RByte=command No. 13)
JMP      #RdReg                        '(RdReg=command No. 14)
JMP      #RdString                     '(RdString=command No. 15)
JMP      #WrtCmdDreg                   '(WrtCmdDReg=command No. 16)
JMP      #WrtCmdRnDreg                 '(WrtCmdRnDReg=command No. 17)
JMP      #WrtRegs                      '(WrtRegs=command No. 18)
JMP      #RdRegs                       '(WrtRegs=command No. 19)

Done                                   'Common return point of commands
   
'Command has been sent to the FPU and in the case of Read operations the
'actual data readings has been finished. Signal this back to the SPIN code
'of this driver by clearing the "command" register, then jump back to the
'entry point of this PASM code and fetch the next command.

WRLONG   _Zero,          PAR           'Write 0 to HUB/VAR/LONG command    
JMP      #Get_Command                  'Get next command

'Note that "command" is cleared usually after it is sent with the
'following attached data, not when it is actually finished by the FPU.
'Exceptions to this are the Read operations - e.g. RByte, RdReg, RdRegs,
'RdSring - where the command register is cleared only after the fully
'finished data reading. In other words, you can send several processing
'commands plus write data one after the other to the FPU that has a 256
'bytes instruction buffer. If you send many commands quickly you should
'check the instruction buffer sometimes (e.g. after 256 bytes sent) to
'prevent overflow. FPU can perform autonomously some kind of tasks, e.g.
'driving digital lines and/or sending serial data depending on the values
'in its internal registers and timers. However, in a usual programming
'situation sometimes you would like to get back some results from it.
'Before any read operation you should wait for all sent commands to be
'executed. For that task there is the #WaitForReady procedure. The
'#CheckForReady procedure will just return the "NOT BUSY" status of the
'FPU. TRUE means that FPU is ready (Idling) and can do a read operation
'immediately. FALSE means the FPU is busy with processing commands. In
'this case you can send a command to it, but you have to wait with a Read
'operation.   


DAT 'Init
'-------------------------------------------------------------------------
'---------------------------------┌──────┐--------------------------------
'---------------------------------│ Init │--------------------------------
'---------------------------------└──────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: -Initializes DIO and CLK Pin Masks
'             -Stores HUB addresses of parameters.
'             -Preforms a simple FPU ready TEST (DIO line is LOW?)
' Parameters: -HUB/LONG/dio, clk, @str
'             -COG/par
'     Result: HUB/par1 (Flag of success)  
'+Reads/Uses: None
'    +Writes: -COG/dio_Mask, clk_Mask
'             -COG/par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'             -COG/par5_Addr_, str_Addr_
'             -COG/r1, r2
'      Calls: None
'-------------------------------------------------------------------------
Init

MOV      r1,             PAR           'Get HUB memory address of "command"

ADD      r1,             #4            'r1 now points to "par1" in HUB 
MOV      par1_Addr_,     r1            'Store this address
RDLONG   r2,             r1            'Load DIO pin No. from HUB into r2
MOV      dio_Mask, #1                  'Setup DIO pin mask 
SHL      dio_Mask, r2
ANDN     OUTA,           dio_Mask      'Pre-Set Data pin LOW
ANDN     DIRA,           dio_Mask      'Set Data pin as INPUT 

ADD      r1,             #4            'r1 now points to "par2" in HUB       
MOV      par2_Addr_,     r1            'Store this address
RDLONG   r2,             r1            'Load CLK pin No. from HUB into r2
MOV      clk_Mask, #1                  'Setup CLK pin mask
SHL      clk_Mask, r2
ANDN     OUTA,           clk_Mask      'Pre-Set Clock pin LOW (Idle)
OR       DIRA,           clk_Mask      'Set Clock pin as an OUTPUT

ADD      r1,             #4            'r1 now points to "par3" in HUB       
MOV      par3_Addr_,     r1            'Store this address
RDLONG   str_Addr_,      r1            'Read pointer to str char array

ADD      r1,             #4            'r1 now points to "par4" in HUB        
MOV      par4_Addr_,     r1            'Store this address
ADD      r1,             #4            'r1 now points to "par5" in HUB       
MOV      par5_Addr_,     r1            'Store this address                              

'Check DIO line for FPU ready
TEST     dio_Mask,       INA WC        'Read DIO state into 'C' flag
                                       'If Cary then not LOW, not ready
IF_C     MOV r1,         #0            'Prepare to send FALSE back 
IF_C     JMP #:Signal                  'Send it

NEG      r1,             #1            'Prepare to send TRUE back

:Signal  
WRLONG   r1,             par1_Addr_    'Send back result of DIO line test
  
JMP      #Done         
'-------------------------------End of Init-------------------------------


DAT 'Rst
'-------------------------------------------------------------------------
'----------------------------------┌─────┐--------------------------------
'----------------------------------│ Rst │--------------------------------
'----------------------------------└─────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Does a Software Reset of FPU
' Parameters: None
'     Result: "Okay" in HUB/VAR/LONG/par1
'+Reads/Uses: -CON/_RESET
'             -COG/_Reset_Delay
'             -COG/dio_Mask, par1_Addr_
'    +Writes: COG/r1, r4, time
'      Calls: #Write_Byte
'       Note: #Write_Byte and descendants use r2, r3
'-------------------------------------------------------------------------
Rst

MOV      r1,             #_RESET       'Byte to send
MOV      r4,             #10           '10 times

:Loop
CALL     #Write_Byte                   'Write byte to FPU 
DJNZ     r4,             #:Loop        'Repeat Loop 10 times 

MOV      r1,             #0            'Write a 0 byte to enforce DIO LOW
CALL     #Write_Byte

'Wait for a  Reset Delay of 10 msec
MOV      time,           CNT           'Find the current time
ADD      time,           _Reset_Delay  'Prepare a 10 msec Reset Delay
WAITCNT  time,           #0            'Wait for 10 msec

'Check DIO for FPU ready
TEST     dio_Mask,       INA WC        'Read DIO state into 'C' flag
                                       'If Cary (DIO not LOW) 
IF_C     MOV r1,         #0            'Not ready, send FALSE back
IF_C     JMP #:Signal

NEG      r1,             #1            'Ready, send TRUE back

:Signal  
WRLONG   r1,             par1_Addr_  

JMP      #Done
'--------------------------------End of Rst-------------------------------


DAT 'CheckForReady
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ CheckForReady │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Checks for an empty instruction buffer of the FPU. It
'             returns immediately with the result and does not wait for
'             that state unlike the WaitForReady command, which does.
' Parameters: None
'     Result: True OR false in par1 according to FPU's ready status
'+Reads/Uses: COG/dio_Mask, _Data_Period
'    +Writes: COG/time, CARRY flag
'      Calls: None
'       Note: -This routine is especially useful when you have more than
'             one FPU in your system. If you use the "WaitForReady" (as
'             "Wait" in SPIN) procedure then your main program will really
'             wait and wait... for the busy FPU. However, If you use this 
'             ( as "CheckReady" in SPIN) procedure then you have back the  
'             control immediately. If the checked FPU is busy this routine
'             will respond with FALSE and you may delegate the pending
'             computing task to an other FPU. Idling FPU will respond with
'             TRUE. In this way you can feed with tasks several FPUs
'             parallely.
'             -Prop is fast enough at 80 MHz to check DIO line before FPU
'             is able to rise DIO line in response to a received command.
'             That is why a Data Period Delay is inserted before the
'             check.
'             -You can send commands and data one after the other without
'             checking the "availability" of the FPU since it has a 256
'             bytes instruction buffer. However, before you read any data
'             back from the FPU you have to wait for all of its previous
'             instructions to be completed.
'-------------------------------------------------------------------------
CheckForReady

ANDN     DIRA,           dio_Mask      'Set DIO pin as an INPUT

'Insert Data Period Delay 
MOV      time,           CNT           'Find the current time
ADD      time,           _Data_Period  '1.6 us Data Period Delay
WAITCNT  time,           #0            'Wait for 1.6 usec  

'Check DIO line for FPU ready, i.e. available
TEST     dio_Mask,       INA WC        'Read DIO state into 'C' flag
                                       'If Cary (DIO not LOW)
IF_C     MOV r1,         #0            'Not ready, send FALSE (busy) back
IF_C     JMP #:Signal                  'since the are unprocessed
                                       'instructions in the FPU. You can
                                       'send new processing commands but
                                       'not Read commands

NEG      r1,             #1            'DIO is LOW, i.e. FPU's instruction
                                       'buffer is empty and you can send a
                                       'Read commands or processing 
                                       'commands, as well. 

:Signal  
WRLONG   r1,             par1_Addr_  

JMP      #Done    
'--------------------------End of CheckForReady---------------------------


DAT 'WaitForReady
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WaitForReady │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Waits for a LOW DIO, i.e for a ready FPU with empty
'             instruction buffer
' Parameters: None
'     Result: None 
'+Reads/Uses: None
'    +Writes: None
'      Calls: #Wait_4_Ready
'-------------------------------------------------------------------------
WaitForReady
                                     
CALL     #Wait_4_Ready

JMP      #Done          
'-----------------------------End of WaitForReady-------------------------

                                      
DAT 'WrtByte 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ WrtByte │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
'      Action: Sends a byte to FPU 
'  Parameters: Byte to send in HUB/par1 (LS byte of a 32-bit value)
'      Result: None 
' +Reads/Uses: COG/par1_Addr_
'     +Writes: COG/r1
'       Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtByte

RDLONG   r1,             par1_Addr_    'Load byte from HUB
CALL     #Write_Byte                   'Write it to FPU
   
JMP      #Done        
'------------------------------End of WrtByte-----------------------------


DAT 'WrtCmdByte 
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ WrtCmdByte │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus Data byte sequence to FPU
' Parameters: -Command byte in HUB/par1
'             -Data byte    in HUB/par2
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_
'    +Writes: COG/r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmdByte

'Send an 8 bit Command + 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'----------------------------End of WrtCmdByte----------------------------


DAT 'WrtCmd2Bytes
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd2Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 2 Data bytes to FPU
' Parameters: -Command byte in HUB/VAR/LONG/par1
'             -Data bytes   in HUB/VAR/LONG/par2, par3
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: COG/r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd2Bytes

'Send an 8 bit Command + 2 x 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load 1st Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par3_Addr_    'Load 2nd Data byte from par3
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmd2Bytes---------------------------


DAT 'WrtCmd3Bytes
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd3Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 3 Data bytes to FPU
' Parameters: -Command byte in HUB/par1
'             -Data bytes   in HUB/par2, par3, par4
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'    +Writes: COG/r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd3Bytes

'Send an 8 bit Command + 3 x 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load 1st Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par3_Addr_    'Load 2nd Data byte from par3
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par4_Addr_    'Load 3nd Data byte from par4
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmd3Bytes---------------------------


DAT 'WrtCmd4Bytes
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd4Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 4 Data bytes to FPU
' Parameters: -Command byte in HUB/VAR/LONG/par1
'             -Data bytes   in HUB/VAR/LONG/par2, par3, par4, par5
'     Result: None                                                                                             
'+Reads/Uses: -COG/par1_Addr_,par2_Addr_,par3_Addr_
'             -COG/par4_Addr_ ,par5_Addr
'    +Writes: COG/r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd4Bytes

'Send an 8 bit Command + 3 x 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load 1st Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par3_Addr_    'Load 2nd Data byte from par3
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par4_Addr_    'Load 3nd Data byte from par4
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par5_Addr_    'Load 3nd Data byte from par4
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmd4Bytes---------------------------


DAT 'WrtCmdReg
'-------------------------------------------------------------------------
'------------------------------┌───────────┐------------------------------
'------------------------------│ WrtCmdReg │------------------------------
'------------------------------└───────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus a 32-bit Register sequence to FPU
' Parameters: -Command byte          in HUB/par1
'             -32-bit Register value in HUB/par2
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdReg

'Send an 8 bit Command + 32-bit Register sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par2_Addr_    'Load 32-bit Reg. value from par2
CALL     #Write_Register               'and write it to FPU
  
JMP      #Done
'----------------------------End of WrtCmdReg-----------------------------


DAT 'WrtCmdDReg
'-------------------------------------------------------------------------
'-----------------------------┌────────────┐------------------------------
'-----------------------------│ WrtCmdDReg │------------------------------
'-----------------------------└────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus a 64-bit Register sequence to FPU
' Parameters: -Command byte          in HUB/par1
'             -32-bit Register value in HUB/par2 MSL register
'             -32-bit Register value in HUB/par3 LSL register
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdDReg

'Send an 8 bit Command + 32-bit Register sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par2_Addr_    'Load 32-bit Reg. value from par2
CALL     #Write_Register               'and write it to FPU
RDLONG   r4,             par3_Addr_    'Load 32-bit Reg. value from par3
CALL     #Write_Register               'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmdDReg-----------------------------


DAT 'WrtCmdRnReg
'-------------------------------------------------------------------------
'-----------------------------┌─────────────┐-----------------------------
'-----------------------------│ WrtCmdRnReg │-----------------------------
'-----------------------------└─────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + Reg[n] byte + 32-bit data to FPU
' Parameters: -Command byte in HUB/par1
'             -Reg[n] byte  in HUB/par2
'             -32-bit data  in HUB/par3
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_,par2_Addr_,par3_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdRnReg

'Send Command byte + Reg[n] byte + 32-bit data to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load Reg[n] from par2
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par3_Addr_    'Load 32-bit Reg. value from par3
CALL     #Write_Register               'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmdRnReg----------------------------


DAT 'WrtCmdRnDReg
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ WrtCmdRnDReg │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + Reg[n] byte + 64-bit data to FPU
' Parameters: -Command byte in HUB/par1
'             -Reg[n] byte  in HUB/par2
'             -32-bit data  in HUB/par3
'             -32-bit data  in HUB/par4
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdRnDReg

'Send Command byte + Reg[n] byte + 32-bit data to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load Reg[n] from par2
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par3_Addr_    'Load 32-bit Reg. value from par3
CALL     #Write_Register               'and write it to FPU
RDLONG   r4,             par4_Addr_    'Load 32-bit Reg. value from par4
CALL     #Write_Register               'and write it to FPU
  
JMP      #Done
'----------------------------End of WrtCmdRnDReg--------------------------


DAT 'WrtCmdString
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmdString │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + String to FPU
' Parameters: - Command byte      in HUB/par1
'             - Pointer to String in HUB/par2
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmdString

'Send Command byte + String (array of Chars then 0) to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par2_Addr_    'Load pointer to HUB/Str from par2

'Write String from HUB to FPU
:Loop
RDBYTE   r1,             r4 WZ         'Read character from HUB
CALL     #Write_Byte                   'Write char or zero to FPU
                                       'If char was not zero  
IF_NZ    ADD r4,         #1            'Increment pointer to HUB memory
IF_NZ    JMP #:Loop                    'Read next byte 
  
JMP      #Done
'----------------------------End of WrtCmdString--------------------------


DAT 'WrtRegs
'-------------------------------------------------------------------------
'---------------------------------┌─────────┐-----------------------------
'---------------------------------│ WrtRegs │-----------------------------
'---------------------------------└─────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a 32-bit data array to FPU
' Parameters: -Pointer to 32-bit data array in HUB/par1
'             -Counter byte                 in HUB/par2
'             -Register number              in HUB/par3
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: r1, r4, r5, r6          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtRegs

'Fetch parameters
RDLONG   r6,             par1_Addr_     'Load HUB address of data array
RDLONG   r5,             par2_Addr_     'Load Counter from par2
RDLONG   r4,             par3_Addr_     'Load start Reg # from par3

'Load indirect  Reg(127) with the start Reg(#)
'SELECTA 127
MOV      r1,             #_SELECTA
CALL     #Write_Byte
MOV      r1,             #127
CALL     #Write_Byte
'Write Start Reg(#) into Reg(127)
MOV      r1,             #_LSETI
CALL     #Write_Byte
MOV      r1,             r4
CALL     #Write_Byte

'WRIND _LONG32, 127, Counter
MOV      r1,             #_WRIND
CALL     #Write_Byte
MOV      r1,             #_LONG32      'Data type
CALL     #Write_Byte
MOV      r1,             #127          'Indirect Reg(#)
CALL     #Write_Byte
MOV      r1,             r5            'Data counter
CALL     #Write_Byte

:Loop
RDLONG   r4,             r6            'Load next 32-bit value from HUB
CALL     #Write_Register               'and write it to FPU 
ADD      r6,             #4            'Increment pointer to HUB memory
DJNZ     r5,             #:Loop        'Decrement r5; jump if not zero 
  
JMP      #Done
'------------------------------End of WrtRegs-----------------------------


DAT 'RByte
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ RByte │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Reads a byte from FPU 
' Parameters: None
'     Result: byte entry in HUB/par1 (LSB of) 
'+Reads/Uses: COG/par1_Addr_
'    +Writes: COG/r1
'      Calls: #Read_Setup_Delay , #Read_Byte
'-------------------------------------------------------------------------
RByte

CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Byte
WRLONG   r1,             par1_Addr_    'Write r1 into HUB/par1
   
JMP      #Done          
'--------------------------------End of RByte-----------------------------


DAT 'RdReg
'-------------------------------------------------------------------------
'----------------------------------┌───────┐------------------------------
'----------------------------------│ RdReg │------------------------------
'----------------------------------└───────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 32-bit register from FPU 
' Parameters: None
'     Result: Register Entry in HUB/par1 
'+Reads/Uses: COG/par1_Addr_
'    +Writes: COG/r1                       
'      Calls: #Read_Setup_Delay, #Read_Register
'-------------------------------------------------------------------------
RdReg

CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Register
WRLONG   r1,             par1_Addr_    'Write r1 into HUB/par1
   
JMP      #Done         
'--------------------------------End of RdReg-----------------------------


DAT 'RdDReg
'-------------------------------------------------------------------------
'---------------------------------┌────────┐------------------------------
'---------------------------------│ RdDReg │------------------------------
'---------------------------------└────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 64-bit register from FPU 
' Parameters: None
'     Result: -32-bit Register Entry in HUB/par1
'             -32-bit Register Entry in HUB/par2
'+Reads/Uses: COG/par1_Addr_, par2_Addr_
'    +Writes: COG/r1                       
'      Calls: #Read_Setup_Delay, #Read_Register
'-------------------------------------------------------------------------
RdDReg

CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Register
WRLONG   r1,             par1_Addr_    'Write r1 into HUB/par1
CALL     #Read_Register
WRLONG   r1,             par2_Addr_    'Write r1 into HUB/par2

JMP      #Done         
'------------------------------End of RdDReg------------------------------

DAT 'RdString
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ RdString │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads String from the String Buffer of FPU 
' Parameters: None
'     Result: String in HUB/str 
'+Reads/Uses: HUB/CON/_READSTR
'    +Writes: COG/r1
'      Calls: #Wait_4_Ready, #Write_Byte, #Read_Setup_Delay, #Read_String  
'-------------------------------------------------------------------------
RdString

'Send a _READSTR command to read the String Buffer from FPU
CALL     #Wait_4_Ready 
MOV      r1,             #_READSTR     'Send _READSTR          
CALL     #Write_Byte
CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_String                  'Now read String Buffer of FPU
                                       'into HUB RAM   
JMP      #Done       
'------------------------------End of RdString----------------------------


DAT 'RdRegs
'-------------------------------------------------------------------------
'---------------------------------┌────────┐------------------------------
'---------------------------------│ RdRegs │------------------------------
'---------------------------------└────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a 32-bit data from the FPU to HUB
' Parameters: -FPU Reg #                    in HUB/par1
'             -Counter byte                 in HUB/par2
'             -Pointer to 32-bit data array in HUB/par3
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: r1, r4, r5, r6          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
RdRegs

'Fetch parameters
RDLONG   r4,             par1_Addr_     'Load start Reg # from par1
RDLONG   r5,             par2_Addr_     'Load Counter from par2
RDLONG   r6,             par3_Addr_     'LOAD HUB address from par3

'Load indirect  Reg(127) with the start Reg(#)
'SELECTA 127
MOV      r1,             #_SELECTA
CALL     #Write_Byte
MOV      r1,             #127
CALL     #Write_Byte
'Write Start Reg(#) into Reg(127)
MOV      r1,             #_LSETI
CALL     #Write_Byte
MOV      r1,             r4
CALL     #Write_Byte

CALL     #Wait_4_Ready                 'Before a read operation

'WRIND _LONG32, 127, Counter
MOV      r1,             #_RDIND
CALL     #Write_Byte
MOV      r1,             #_LONG32      'Data type
CALL     #Write_Byte
MOV      r1,             #127          'Indirect Reg(#)
CALL     #Write_Byte
MOV      r1,             r5            'Data counter
CALL     #Write_Byte

:Loop
CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Register                'Read register from FPU
WRLONG   r1,             r6            'Write 32-bit reg data into HUB
ADD      r6,             #4  
DJNZ     r5,             #:Loop        'Get next register 
  
JMP      #Done
'------------------------------End of RdRegs------------------------------


DAT '---------------------------PRI PASM code-----------------------------
'Now come the "PRIVATE" PASM routines of this Driver. They are "PRI" in
'the sense that they do not have "command No." and they do not use par1,
'par2, etc.... They are service routines for the user accesable tasks.


DAT 'Wait_4_Ready
'-------------------------------------------------------------------------
'---------------------------┌──────────────┐------------------------------
'---------------------------│ Wait_4_Ready │------------------------------
'---------------------------└──────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Waits for a LOW DIO, i.e for a ready FPU with empty
'             instruction buffer
' Parameters: None
'     Result: None 
'+Reads/Uses: COG/dio_Mask, time, _Data_Period
'    +Writes: -COG/time,
'             -CARRY flag
'      Calls: None
'       Note: Prop is fast enough at 80 MHz to check DIO line before FPU
'             is able to rise it in response to a received command. That's
'             why a Data Period Delay is inserted before the check.
'-------------------------------------------------------------------------
Wait_4_Ready
                                     
ANDN     DIRA,           dio_Mask      'Set DIO pin as an INPUT

'Insert Data Period Delay 
MOV      time,           CNT           'Find the current time
ADD      time,           _Data_Period  '1.6 us Data Period Delay
WAITCNT  time,           #0            'Wait for 1.6 usec  

:Loop
TEST     dio_Mask,       INA WC        'Read SOUT state into 'C' flag
IF_C{
}JMP     #:Loop                        'Wait until DIO LOW

Wait_4_Ready_Ret
RET          
'----------------------------End of Wait_4_Ready--------------------------


DAT 'Write_Byte
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Write_Byte │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a byte to FPU 
' Parameters: Byte to send in Least Significant Byte of r1 32-bit register
'     Result: None 
'+Reads/Uses: COG/_Data_Period, dio_Mask
'    +Writes: COG/time
'      Calls: #Shift_Out_Byte
'-------------------------------------------------------------------------
Write_Byte

'Wait for the Minimum Data Period
MOV      time,           CNT           'Find the current time
ADD      time,           _Data_Period  '1.6 us minimum data period
WAITCNT  time,           #0            'Wait for  1.6 us

CALL     #Shift_Out_Byte               'Write byte to FPU via 2-wire SPI
   
Write_Byte_Ret
RET              
'-----------------------------End of Write_Byte---------------------------


DAT 'Write_Register
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ Write_Register │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Writes a 32-bit value to FPU
' Parameters: 32-bit value in r4 to send (MSB first)
'     Result: None 
'+Reads/Uses: COG/_Byte_Mask
'    +Writes: COG/r1
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
Write_Register

'Send MS byte of r4
MOV      r1,             r4
ROR      r1,             #24
CALL     #Write_Byte

'Send 2nd byte of r4
MOV      r1,             r4
ROR      r1,             #16
CALL     #Write_Byte

'Send 3rd byte of r4
MOV      r1,             r4
ROR      r1,             #8
CALL     #Write_Byte

'Send LS byte of r4
MOV      r1,             r4
CALL     #Write_Byte
  
Write_Register_Ret
RET              
'--------------------------End of Write_Register--------------------------


DAT 'Read_Setup_Delay
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Read_Setup_Delay │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Inserts 15 usec Read Setup Delay
' Parameters: None
'     Result: None
'+Reads/Uses: COG/_Read_Setup_Delay 
'    +Writes: COG/time
'      Calls: None
'-------------------------------------------------------------------------
Read_Setup_Delay

MOV      time,           CNT                 'Find the current time
ADD      time,           _Read_Setup_Delay   '15 usec Read Setup Delay
WAITCNT  time,           #0                  'Wait for 15 usec
  
Read_Setup_Delay_Ret
RET              
'---------------------------End of Read_Setup_Delay-----------------------


DAT 'Read_Byte
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ Read_Byte │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Reads a byte from FPU
' Parameters: None
'     Result: Entry in r1
'+Reads/Uses: COG/_Read_Byte_Delay
'    +Writes: COG/time
'      Calls: #Shift_In_Byte
'-------------------------------------------------------------------------
Read_Byte

'Insert a 1 us Read byte Delay
MOV      time,           CNT               'Find the current time
ADD      time,           _Read_Byte_Delay  '1 us Read byte Delay
WAITCNT  time,           #0                'Wait for 1 usec       
  
CALL     #Shift_In_Byte                    'Read a byte from FPU
  
Read_Byte_Ret
RET              
'-----------------------------End of Read_Byte----------------------------


DAT 'Read_Register
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Read_Register │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 32-bit register form FPU
' Parameters: None
'     Result: Entry in r1
'+Reads/Uses: None
'    +Writes: COG/r3
'      Calls: #Read_Byte
'       note: #Read_Byte's descendant uses r2
'-------------------------------------------------------------------------
Read_Register

'Collect FPU register in r3 
CALL     #Read_Byte
MOV      r3,             r1
CALL     #Read_Byte
SHL      r3,             #8
ADD      r3,             r1
CALL     #Read_Byte
SHL      r3,             #8
ADD      r3,             r1
CALL     #Read_Byte
SHL      r3,             #8
ADD      r3,             r1

MOV      r1,             r3            'Done. Copy sum from r3 into r1
  
Read_Register_Ret
RET              
'-----------------------------End of Read_Register------------------------


DAT 'Read_String
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Read_String │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Reads a zero terminated string from FPU into HUB memory
' Parameters: None
'     Result: Sring in HUB/BYTE[_MAXSTRL] str
'+Reads/Uses: COG/str_Addr_
'    +Writes: COG/r1, r3
'      Calls: #Read_Byte
'       Note: Writes to HUB the terminating zero, as well
'-------------------------------------------------------------------------
Read_String

'Prepare loop to read string from FPU to HUB
MOV      r3,             str_Addr_
 
:Loop
CALL     #Read_Byte                    'Read a character from FPU
WRBYTE   r1,             r3            'Write character to HUB memory
CMP      r1,             #0 WZ         'String terminated if char is 0
                                       'If char not zero    
IF_NZ{
}ADD     r3,             #1            'Increment pointer to HUB memory 
IF_NZ{
}JMP     #:Loop                        'Jump to fetch next character 
  
Read_String_Ret
RET              
'-----------------------------End of Read_String--------------------------


DAT '--------------------------------SPI----------------------------------

DAT 'Shift_Out_Byte
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Shift_Out_Byte │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Shifts out a byte to FPU  (MSBFIRST) via 2-wire SPI
' Parameters: Byte to send in r1
'     Result: None
'+Reads/Uses: COG/dio_Mask         
'    +Writes: COG/r2, r3
'      Calls: #Clock_Pulse
'-------------------------------------------------------------------------
Shift_Out_Byte                               

OR       DIRA,           dio_Mask      'Set DIO pin as an OUTPUT 
MOV      r2,             #8            'Set length of byte         
MOV      r3,             #%1000_0000   'Set bit mask (MSBFIRST)
                                                               
:Loop
TEST     r1,             r3 WC         'Test a bit of data byte
MUXC     OUTA,           dio_Mask      'Set DIO HIGH or LOW
SHR      r3,             #1            'Prepare for next data bit  
CALL     #Clock_Pulse                  'Send a clock pulse
DJNZ     r2,             #:Loop        'Decrement r2; jump if not zero
         
Shift_Out_Byte_Ret
RET
'---------------------------End of Shift_Out_Byte-------------------------


DAT 'Shift_In_Byte
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Shift_In_Byte │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Shifts in a byte from FPU (MSBPRE) via 2-wire SPI
' Parameters: None
'     Result: Entry byte in COG/r1
'+Reads/Uses: COG/dio_Mask 
'    +Writes: COG/r2
'      Calls: #Clock_Pulse
'-------------------------------------------------------------------------
Shift_In_Byte
ANDN     DIRA,           dio_Mask      'Set DIO pin as an INPUT
MOV      r2,             #8            'Set length of byte
MOV      r1,             #0            'Clear r1   
          
:Loop
TEST     dio_Mask,       INA WC        'Read Data Bit into 'C' flag
RCL      r1,             #1            'Left rotate 'C' flag into r1  
CALL     #Clock_Pulse                  'Send a clock pulse   
DJNZ     r2,             #:Loop        'Decrement r2; jump if not zero

Shift_In_Byte_Ret        
RET              
'---------------------------End of Shift_In_Byte--------------------------


DAT 'Clock_Pulse
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Clock_Pulse │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a 50 ns LONG HIGH pulse to CLK pin of FPU
' Parameters: None
'     Result: None 
'+Reads/Uses: COG/clk_Mask 
'    +Writes: None
'      Calls: None
'       Note: At 80_000_000 Hz the CLK pulse width is about 50 ns(4 ticks)
'             and the CLK pin is pulsed at the rate about 2.5 MHz. This
'             rate is determined by the cycle time of the loop containing
'             the "CALL #Clock_Pulse" instruction. You can make the rate a
'             bit faster using inline code instead of DJNZ in the shift
'             in/out routines. However, the overal data burst speed will
'             not increase that much since the necessary delays affect it,
'             as well. They should remain in the time sequence, of course.
'-------------------------------------------------------------------------
Clock_Pulse

OR       OUTA,           clk_Mask      'Set CLK Pin HIGH
ANDN     OUTA,           clk_Mask      'Set CLK Pin LOW

Clock_Pulse_Ret         
RET
'---------------------------End of Clock_Pulse---------------------------- 


DAT '-----------COG memory allocation defined by PASM symbols-------------
  
'-------------------------------------------------------------------------
'----------------------Initialized data for constants---------------------
'-------------------------------------------------------------------------
_Zero                LONG    0

'-------------------------Delays at 80_000_000 MHz------------------------
_Data_Period         LONG    128       '1.6 us Minimum Data Period  
_Reset_Delay         LONG    800_000   '10 ms Reset Delay
_Read_Setup_Delay    LONG    1_200     '15 us Read Setup Delay
_Read_Byte_Delay     LONG    80        '1 us Read byte Delay

'-------------------------------------------------------------------------
'---------------------Uninitialized data for variables--------------------
'-------------------------------------------------------------------------

'----------------------------------Pin Masks------------------------------
dio_Mask             RES     1         'Pin mask in Propeller for DIO
clk_Mask             RES     1         'Pin mask in Propeller for CLK

'----------------------------HUB memory addresses-------------------------
par1_Addr_           RES     1
par2_Addr_           RES     1
par3_Addr_           RES     1
par4_Addr_           RES     1
par5_Addr_           RES     1
str_Addr_            RES     1

'--------------------Time register for delay processes--------------------
time                 RES     1

'------------------------Recycled Temporary Registers---------------------
r1                   RES     1         
r2                   RES     1         
r3                   RES     1
r4                   RES     1
r5                   RES     1
r6                   RES     1          

FIT                  496               'For sure


DAT '---------------------------MIT License-------------------------------


{{

┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}   