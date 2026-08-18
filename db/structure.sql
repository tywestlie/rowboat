SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.datasets (
    id bigint NOT NULL,
    name character varying,
    source_url character varying,
    imported_at timestamp(6) without time zone,
    row_count integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description text
);


--
-- Name: datasets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.datasets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.datasets_id_seq OWNED BY public.datasets.id;


--
-- Name: exoplanets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exoplanets (
    id bigint NOT NULL,
    pl_name character varying,
    hostname character varying,
    discoverymethod character varying,
    disc_year integer,
    pl_orbper double precision,
    pl_rade double precision,
    pl_bmasse double precision,
    pl_eqt double precision,
    st_teff double precision,
    sy_dist double precision,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: exoplanets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exoplanets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exoplanets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exoplanets_id_seq OWNED BY public.exoplanets.id;


--
-- Name: queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.queries (
    id bigint NOT NULL,
    dataset_id bigint NOT NULL,
    question text,
    generated_query jsonb,
    result_summary text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.queries_id_seq OWNED BY public.queries.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: stellar_hosts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stellar_hosts (
    id bigint NOT NULL,
    hostname character varying,
    st_spectype character varying,
    st_teff double precision,
    st_rad double precision,
    st_mass double precision,
    st_met double precision,
    st_lum double precision,
    sy_dist double precision,
    ra double precision,
    "dec" double precision,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: stellar_hosts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stellar_hosts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stellar_hosts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stellar_hosts_id_seq OWNED BY public.stellar_hosts.id;


--
-- Name: datasets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets ALTER COLUMN id SET DEFAULT nextval('public.datasets_id_seq'::regclass);


--
-- Name: exoplanets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exoplanets ALTER COLUMN id SET DEFAULT nextval('public.exoplanets_id_seq'::regclass);


--
-- Name: queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.queries ALTER COLUMN id SET DEFAULT nextval('public.queries_id_seq'::regclass);


--
-- Name: stellar_hosts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_hosts ALTER COLUMN id SET DEFAULT nextval('public.stellar_hosts_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: datasets datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_pkey PRIMARY KEY (id);


--
-- Name: exoplanets exoplanets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exoplanets
    ADD CONSTRAINT exoplanets_pkey PRIMARY KEY (id);


--
-- Name: queries queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.queries
    ADD CONSTRAINT queries_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: stellar_hosts stellar_hosts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_hosts
    ADD CONSTRAINT stellar_hosts_pkey PRIMARY KEY (id);


--
-- Name: index_exoplanets_on_hostname; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exoplanets_on_hostname ON public.exoplanets USING btree (hostname);


--
-- Name: index_queries_on_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_queries_on_dataset_id ON public.queries USING btree (dataset_id);


--
-- Name: index_stellar_hosts_on_hostname; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stellar_hosts_on_hostname ON public.stellar_hosts USING btree (hostname);


--
-- Name: queries fk_rails_9223fd37d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.queries
    ADD CONSTRAINT fk_rails_9223fd37d7 FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260818210300'),
('20260818210000'),
('20260818202219'),
('20260818202217'),
('20260806191744'),
('20260806191743'),
('20260806191742'),
('20260806191741');

