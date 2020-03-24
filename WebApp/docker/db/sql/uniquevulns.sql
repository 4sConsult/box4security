CREATE SEQUENCE public.uniquevulns_vul_id_seq
    INCREMENT 1
    START 27275
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;
ALTER SEQUENCE public.uniquevulns_vul_id_seq
    OWNER TO postgres;
CREATE TABLE public.uniquevulns
 (
     vul_id integer NOT NULL DEFAULT nextval('uniquevulns_vul_id_seq'::regclass),
     uniqueidentifier character varying(50) COLLATE pg_catalog."default" NOT NULL,
     CONSTRAINT uniquevulns_pkey PRIMARY KEY (vul_id),
     CONSTRAINT uniquevulns_uniqueidentifier_key UNIQUE (uniqueidentifier)

 )
 WITH (
     OIDS = FALSE
 )
 TABLESPACE pg_default;

ALTER TABLE public.uniquevulns
    OWNER to postgres;
