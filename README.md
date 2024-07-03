# Dynamic-SAP-Data-Retrieval-and-Smart-Form-Processing-in-ABAP

## Components of the Application Program
DATA gv func_name TYPE rs381 fnam.

"Data retrieval

1 SELECT FROM <table> FIELDS * INTO TABLE @DATA(gt_data)

" Name of the generated function module name?

2 CALL FUNCTION 'SSF FUNCTION MODULE NAME'

EXPORTING formname = 'ZMY_SMARTFORM' "SmartForm name

IMPORTING fm name = gv_func_name

EXCEPTIONS no form = 1

no function module = 2

OTHERS = 3.

3 LOOP AT gt data ASSIGNING FIELD-SYMBOL(<gs_data>).

  CALL FUNCTION gv_func_name "Calling the function module
  
    EXPORTING...
    
    IMPORTING...
    
    TABLES...
    
  ENDLOOP.
