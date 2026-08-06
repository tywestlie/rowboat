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
-- Name: dataset_columns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dataset_columns (
    id bigint NOT NULL,
    dataset_id bigint NOT NULL,
    name character varying,
    display_name character varying,
    data_type character varying,
    "position" integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dataset_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dataset_columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dataset_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dataset_columns_id_seq OWNED BY public.dataset_columns.id;


--
-- Name: dataset_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dataset_rows (
    id bigint NOT NULL,
    dataset_id bigint NOT NULL,
    data jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dataset_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dataset_rows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dataset_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dataset_rows_id_seq OWNED BY public.dataset_rows.id;


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
    updated_at timestamp(6) without time zone NOT NULL
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
-- Name: dataset_columns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_columns ALTER COLUMN id SET DEFAULT nextval('public.dataset_columns_id_seq'::regclass);


--
-- Name: dataset_rows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_rows ALTER COLUMN id SET DEFAULT nextval('public.dataset_rows_id_seq'::regclass);


--
-- Name: datasets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets ALTER COLUMN id SET DEFAULT nextval('public.datasets_id_seq'::regclass);


--
-- Name: queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.queries ALTER COLUMN id SET DEFAULT nextval('public.queries_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: dataset_columns dataset_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_columns
    ADD CONSTRAINT dataset_columns_pkey PRIMARY KEY (id);


--
-- Name: dataset_rows dataset_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_rows
    ADD CONSTRAINT dataset_rows_pkey PRIMARY KEY (id);


--
-- Name: datasets datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_pkey PRIMARY KEY (id);


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
-- Name: index_dataset_columns_on_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dataset_columns_on_dataset_id ON public.dataset_columns USING btree (dataset_id);


--
-- Name: index_dataset_rows_on_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dataset_rows_on_dataset_id ON public.dataset_rows USING btree (dataset_id);


--
-- Name: index_queries_on_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_queries_on_dataset_id ON public.queries USING btree (dataset_id);


--
-- Name: queries fk_rails_9223fd37d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.queries
    ADD CONSTRAINT fk_rails_9223fd37d7 FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);


--
-- Name: dataset_columns fk_rails_d2b414c3da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_columns
    ADD CONSTRAINT fk_rails_d2b414c3da FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);


--
-- Name: dataset_rows fk_rails_f69d46b114; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_rows
    ADD CONSTRAINT fk_rails_f69d46b114 FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260806191744'),
('20260806191743'),
('20260806191742'),
('20260806191741');

