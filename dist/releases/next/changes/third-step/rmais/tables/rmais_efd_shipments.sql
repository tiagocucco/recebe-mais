-- liquibase formatted sql
-- changeset RMAIS:1777295651068 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_efd_shipments.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_efd_shipments.sql:null:b5c2ac34ab74d8b21e0d37596e7661305fd14350:create

create table rmais_efd_shipments (
    efd_shipment_id         number not null enable,
    efd_line_id             number not null enable,
    ship_to_organization_id number not null enable,
    ship_to_location_id     number not null enable,
    source_doc_shipment_id  number not null enable,
    quantity_to_receive     number,
    creation_date           date not null enable,
    created_by              number not null enable,
    last_update_date        date not null enable,
    last_updated_by         number not null enable,
    last_update_login       number,
    program_id              number,
    program_login_id        number,
    program_application_id  number,
    request_id              number,
    attribute_category      varchar2(150 byte),
    attribute1              varchar2(240 byte),
    attribute2              varchar2(240 byte),
    attribute3              varchar2(240 byte),
    attribute4              varchar2(240 byte),
    attribute5              varchar2(240 byte),
    attribute6              varchar2(240 byte),
    attribute7              varchar2(240 byte),
    attribute8              varchar2(240 byte),
    attribute9              varchar2(240 byte),
    attribute10             varchar2(240 byte),
    attribute11             varchar2(240 byte),
    attribute12             varchar2(240 byte),
    attribute13             varchar2(240 byte),
    attribute14             varchar2(240 byte),
    attribute15             varchar2(240 byte)
);

create unique index xxrmais_efd_shipments_pk on
    rmais_efd_shipments (
        efd_shipment_id
    );

alter table rmais_efd_shipments
    add constraint xxrmais_efd_shipments_pk primary key ( efd_shipment_id )
        using index xxrmais_efd_shipments_pk enable;

