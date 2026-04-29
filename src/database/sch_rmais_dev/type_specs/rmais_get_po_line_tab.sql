create or replace type rmais_get_po_line_tab is
    table of rmais_get_po_line_rec
/

create or replace type string_tbl_t as
    table of varchar2(2000);
/


-- sqlcl_snapshot {"hash":"015687f4bb5bcf077fe0223f3449547d675dbb10","type":"TYPE_SPEC","name":"RMAIS_GET_PO_LINE_TAB","schemaName":"SCH_RMAIS_DEV","sxml":""}