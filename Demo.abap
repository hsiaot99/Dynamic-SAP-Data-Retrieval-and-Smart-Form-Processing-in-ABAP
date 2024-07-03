REPORT Z24Q20001 NO STANDARD PAGE HEADING
  LINE-SIZE 135 LINE-COUNT 50(2).

***** Define **********************************************************
TYPES:BEGIN OF st_mara,
        matnr TYPE mara-matnr,
        werks TYPE t001l-werks,
        bwkey TYPE t001w-bwkey,
        lgort TYPE t001l-lgort,
        labst TYPE mard-labst,
        meins TYPE mara-meins,
      END OF st_mara,
      BEGIN OF st_mbew,
        matnr TYPE mbew-matnr,
        bwkey TYPE mbew-bwkey,
        bwtar TYPE mbew-bwtar,
        bukrs TYPE t001-bukrs,
        waers TYPE t001-waers,
        vprsv TYPE mbew-vprsv,
        verpr TYPE mbew-verpr,
        stprs TYPE mbew-stprs,
        peinh TYPE mbew-peinh,
      END OF st_mbew,
      tt_mbew TYPE TABLE OF st_mbew,
      BEGIN OF st_makt,
        matnr TYPE makt-matnr,
        spras TYPE makt-spras,
        maktx TYPE makt-maktx,
      END OF st_makt.

TYPE-POOLS: isoc. "only for ECC
***** Variant ********************************************************
DATA gs_mara TYPE st_mara.  "only for select-option!!
DATA: gt_mara   TYPE TABLE OF st_mara,
      gt_mbew   TYPE tt_mbew,
      gt_makt   TYPE TABLE OF st_makt,
      gv_uprice TYPE p DECIMALS 4,
      gv_amount TYPE p DECIMALS 2.

***** Selection Screen ************************************************
SELECTION-SCREEN BEGIN OF BLOCK bk1 WITH FRAME TITLE gv_title.
SELECT-OPTIONS: s_matnr FOR gs_mara-matnr,
                s_werks FOR gs_mara-werks,
                s_lgort FOR gs_mara-lgort.
SELECTION-SCREEN SKIP 1.
PARAMETERS: c_zero AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK bk1.

***** Initialization **************************************************
INITIALIZATION.
  gv_title = '資料篩選條件'(t01).

***** PAI *************************************************************
AT SELECTION-SCREEN.
  IF s_matnr[] IS INITIAL AND s_werks[] IS INITIAL
      AND s_lgort[] IS INITIAL.
    MESSAGE w000(oo) WITH TEXT-w01. "建議輸入篩選條件
  ENDIF.

***** Start of Selection **********************************************
START-OF-SELECTION.
  PERFORM: init_data,
           get_data.
  PERFORM print_data.

***** Top of Page *****************************************************
TOP-OF-PAGE.
  PERFORM print_title.

***** End of Page *****************************************************
END-OF-PAGE.
  ULINE.
  WRITE: 50 '頁次:'(b01), sy-pagno.

*&---------------------------------------------------------------------*
*&      Form  init_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_data.
  CLEAR: gt_mara, gt_mbew, gt_makt.
ENDFORM.                    "init_data

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_data.

  SELECT FROM mara INNER JOIN mard
      ON mara~matnr = mard~matnr
                   INNER JOIN t001w
      ON mard~werks = t001w~werks
    FIELDS mara~matnr, mara~meins, mard~werks, mard~lgort,
          mard~labst, t001w~bwkey
    WHERE mara~matnr IN @s_matnr
      AND mara~lvorm = ''
      AND mard~werks IN @s_werks
      AND mard~lgort IN @s_lgort
      AND mard~lvorm = ''
    INTO CORRESPONDING FIELDS OF TABLE @gt_mara.
  IF c_zero = 'X'.
    DELETE gt_mara WHERE labst = 0.
  ENDIF.
  IF gt_mara IS INITIAL.
    MESSAGE s000(oo) WITH 'Record not found.' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  SELECT FROM mbew INNER JOIN t001k
      ON mbew~bwkey = t001k~bwkey
                   INNER JOIN t001
      ON t001k~bukrs = t001~bukrs
    FIELDS mbew~matnr, mbew~bwkey, mbew~bwtar, mbew~vprsv, mbew~verpr,
           mbew~stprs, mbew~peinh,
           t001~bukrs, t001~waers
    FOR ALL ENTRIES IN @gt_mara
    WHERE mbew~matnr = @gt_mara-matnr
      AND mbew~bwkey = @gt_mara-bwkey
      AND mbew~lvorm = ''
      AND mbew~bwtar = ''
    INTO CORRESPONDING FIELDS OF TABLE @gt_mbew.

  SELECT FROM makt FIELDS *
    FOR ALL ENTRIES IN @gt_mara
    WHERE matnr = @gt_mara-matnr
      AND spras = @sy-langu
    INTO CORRESPONDING FIELDS OF TABLE @gt_makt.

ENDFORM.                    "get_data

*&---------------------------------------------------------------------*
*&      Form  print_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM print_data.
  DATA: l_verpr  TYPE wmto_s-amount,
        l_waers  TYPE t001-waers,
        l_factor TYPE isoc_factor.

  SORT gt_mara BY matnr werks lgort.

  LOOP AT gt_mara ASSIGNING FIELD-SYMBOL(<ls_mara>).
    CLEAR: gv_uprice, gv_amount.

    WRITE:/1 <ls_mara>-matnr.

    READ TABLE gt_makt WITH KEY matnr = <ls_mara>-matnr
      ASSIGNING FIELD-SYMBOL(<ls_makt>).
    IF sy-subrc = 0.
      WRITE <ls_makt>-maktx UNDER TEXT-002.
    ENDIF.

    WRITE: <ls_mara>-werks UNDER TEXT-003,
           <ls_mara>-lgort,
           <ls_mara>-labst RIGHT-JUSTIFIED," UNIT <ls_mara>-meins,
           <ls_mara>-meins.

    READ TABLE gt_mbew WITH KEY matnr = <ls_mara>-matnr
                                bwkey = <ls_mara>-bwkey
                       ASSIGNING FIELD-SYMBOL(<ls_mbew>).
    IF sy-subrc = 0.
      CASE <ls_mbew>-vprsv.
        WHEN 'S'.
          CALL FUNCTION 'CURRENCY_CONVERTING_FACTOR'
            EXPORTING
              currency          = <ls_mbew>-waers
            IMPORTING
              factor            = l_factor
            EXCEPTIONS
              too_many_decimals = 1
              OTHERS            = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE 'E'" sy-msgty
              NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          gv_uprice = <ls_mbew>-stprs * l_factor / <ls_mbew>-peinh.
          gv_amount = <ls_mbew>-stprs * l_factor * <ls_mara>-labst
                      / <ls_mbew>-peinh.

        WHEN 'V'.
          l_verpr = <ls_mbew>-verpr.
          l_waers = <ls_mbew>-waers.
          CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
            EXPORTING
              currency        = l_waers
              amount_internal = l_verpr
            IMPORTING
              amount_display  = l_verpr
            EXCEPTIONS
              internal_error  = 1
              OTHERS          = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE 'E' "sy-msgty
              NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          gv_uprice = l_verpr / <ls_mbew>-peinh.
          gv_amount = l_verpr * <ls_mara>-labst
                      / <ls_mbew>-peinh.
        WHEN OTHERS.
      ENDCASE.

      WRITE: gv_uprice,
             gv_amount," CURRENCY <ls_mbew>-waers,
             <ls_mbew>-waers.
    ENDIF.
  ENDLOOP.

  SKIP TO LINE 49.
  WRITE:19 space.
ENDFORM.                    "print_data

*&---------------------------------------------------------------------*
*&      Form  PRINT_TITLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM print_title .
  WRITE:/1 '程式名稱：', sy-cprog,
         60 'xxxx股份有限公司',
        110 '列印日期：', sy-datum.
  WRITE:/1 '使用者：', sy-uname,
        63 '物料庫存成本表',
       110 '列印時間：', sy-uzeit.
  SKIP 1.
  WRITE:/1 '料號'(001),
        20 '說明'(002),
        61 '廠別'(003),
        66 '倉別'(004),
*        82 '庫存數'(005),
        70(18) '庫存數'(005) RIGHT-JUSTIFIED,
        92(18) '單價'(006) RIGHT-JUSTIFIED,
       110(18) '總價'(007) RIGHT-JUSTIFIED.
  ULINE.

ENDFORM.                    " PRINT_TITLE
