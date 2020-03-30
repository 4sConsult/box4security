CREATE TABLE blocks_by_bpffilter
       (
           id SERIAL primary key,
           src_ip inet,
           src_port integer,
           dst_ip inet,
           dst_port integer,
           proto  varchar(4)
       )
       WITH (
           OIDS = FALSE
       )
       TABLESPACE pg_default;
ALTER TABLE blocks_by_bpffilter
        OWNER to postgres;
INSERT INTO blocks_by_bpffilter (src_ip, src_port, dst_ip, dst_port, proto) VALUES ('127.0.0.1',0,'0.0.0.0',0,'');
INSERT INTO blocks_by_bpffilter (src_ip, src_port, dst_ip, dst_port, proto) VALUES ('0.0.0.0',0,'127.0.0.1',0,'');
CREATE TABLE blocks_by_logstashfilter
             (
                 id SERIAL primary key,
                 src_ip inet,
                 src_port integer,
                 dst_ip inet,
                 dst_port integer,
                 proto  varchar(4),
                 signature_id varchar(10),
                 signature varchar(256)
             )
             WITH (
                 OIDS = FALSE
             )
             TABLESPACE pg_default;
ALTER TABLE blocks_by_logstashfilter
            OWNER to postgres;
