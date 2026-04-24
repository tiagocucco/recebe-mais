create or replace force editionable view rmais_fornec (
    issuer_document_number,
    issuer_name
) as
    select distinct
        issuer_document_number,
        issuer_name
    from
        rmais_efd_headers
    where
        issuer_document_number is not null;


-- sqlcl_snapshot {"hash":"c8e87918686ddc70456732e3de4aaac67e840b3d","type":"VIEW","name":"RMAIS_FORNEC","schemaName":"RMAIS","sxml":""}