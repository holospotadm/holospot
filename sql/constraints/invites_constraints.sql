-- ============================================================================
-- CONSTRAINTS DA TABELA: invites
-- ============================================================================

ALTER TABLE public.invites ADD CONSTRAINT 2200_114392_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.invites ADD CONSTRAINT 2200_114392_2_not_null CHECK (code IS NOT NULL);

ALTER TABLE public.invites ADD CONSTRAINT invites_code_key UNIQUE (code);

ALTER TABLE public.invites ADD CONSTRAINT invites_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);

ALTER TABLE public.invites ADD CONSTRAINT invites_pkey PRIMARY KEY (id);

ALTER TABLE public.invites ADD CONSTRAINT invites_used_by_fkey FOREIGN KEY (used_by) REFERENCES public.profiles(id);

ALTER TABLE public.invites ADD CONSTRAINT valid_invite_code CHECK (((code)::text ~ '^HOLO-[A-Z0-9]{6}$'::text));

