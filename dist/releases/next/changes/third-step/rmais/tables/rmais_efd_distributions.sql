-- liquibase formatted sql
-- changeset RMAIS:1777295650637 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_efd_distributions.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_efd_distributions.sql:null:8c4a1b873d29dba60529fa64c61ee988c461de47:create

create table rmais_efd_distributions (
    efd_distribution_id         number not null enable,
    efd_line_id                 number not null enable,
    source_doc_shipment_id      number not null enable,
    distribution_num            number,
    quantity                    number,
    destination_type            varchar2(100 byte),
    project_id                  number,
    task_id                     number,
    expenditure_type            varchar2(100 byte),
    expenditure_organization_id number,
    expenditure_item_date       date,
    creation_date               date not null enable,
    created_by                  number not null enable,
    last_update_date            date not null enable,
    last_updated_by             number not null enable,
    last_update_login           number,
    program_id                  number,
    program_login_id            number,
    program_application_id      number,
    request_id                  number,
    attribute_category          varchar2(150 byte),
    attribute1                  varchar2(240 byte),
    attribute2                  varchar2(240 byte),
    attribute3                  varchar2(240 byte),
    attribute4                  varchar2(240 byte),
    attribute5                  varchar2(240 byte),
    attribute6                  varchar2(240 byte),
    attribute7                  varchar2(240 byte),
    attribute8                  varchar2(240 byte),
    attribute9                  varchar2(240 byte),
    attribute10                 varchar2(240 byte),
    attribute11                 varchar2(240 byte),
    attribute12                 varchar2(240 byte),
    attribute13                 varchar2(240 byte),
    attribute14                 varchar2(240 byte),
    attribute15                 varchar2(240 byte)
);

