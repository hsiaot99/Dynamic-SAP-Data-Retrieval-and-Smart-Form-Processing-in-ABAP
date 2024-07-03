# Dynamic-SAP-Data-Retrieval-and-Smart-Form-Processing-in-ABAP

## Components of the Application Program
```abap
DATA gv_func_name TYPE rs381 fnam.

" Data retrieval
SELECT *
  FROM <table>
  FIELDS *
  INTO TABLE @DATA(gt_data).

" Name of the generated function module name?
CALL FUNCTION 'SSF FUNCTION MODULE NAME'
  EXPORTING
    formname = 'ZMY_SMARTFORM' " SmartForm name
  IMPORTING
    fm_name = gv_func_name
  EXCEPTIONS
    no_form = 1
    no_function_module = 2
    OTHERS = 3.

LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<gs_data>).
  CALL FUNCTION gv_func_name. " Calling the function module
  " EXPORTING...
  " IMPORTING...
  " TABLES...
ENDLOOP.
```

## How to design / coding SmartForms
• Confirm output format (first page format, second page format, last page format...)
• Design SmartStyle
• Design SmartForms interface
• SmartForms: page, windows,...
• Coding Report program
• KISS 原則
