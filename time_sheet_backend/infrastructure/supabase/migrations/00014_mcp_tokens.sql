-- ============================================
-- MCP Personal Access Tokens
-- Migration: 00014_mcp_tokens
--
-- Tokens long-lived utilisés par le serveur MCP HTTP distant pour
-- authentifier un PC d'entreprise et identifier l'utilisateur Supabase
-- correspondant. Le token en clair n'est JAMAIS stocké : seul son
-- SHA-256 est conservé. Le token est affiché à la création, une seule fois.
-- ============================================

CREATE TABLE public.mcp_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_mcp_tokens_user ON public.mcp_tokens(user_id);
CREATE INDEX idx_mcp_tokens_hash ON public.mcp_tokens(token_hash) WHERE revoked_at IS NULL;

ALTER TABLE public.mcp_tokens ENABLE ROW LEVEL SECURITY;

-- L'utilisateur peut lire et révoquer ses propres tokens (jamais le hash en clair via RLS,
-- mais on n'expose de toute façon que les métadonnées côté UI).
CREATE POLICY mcp_tokens_select_own ON public.mcp_tokens
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY mcp_tokens_update_own ON public.mcp_tokens
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY mcp_tokens_delete_own ON public.mcp_tokens
  FOR DELETE USING (user_id = auth.uid());

-- ============================================
-- RPC: create_mcp_token(name, expires_in_days)
-- Génère un token aléatoire, stocke son hash, retourne le token en clair.
-- Format : tsmcp_<32 chars hex>
-- ============================================
CREATE OR REPLACE FUNCTION public.create_mcp_token(
  p_name TEXT,
  p_expires_in_days INTEGER DEFAULT 365
)
RETURNS TABLE(id UUID, token TEXT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_raw TEXT;
  v_token TEXT;
  v_hash TEXT;
  v_id UUID;
  v_expires TIMESTAMPTZ;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifié';
  END IF;

  -- 32 chars hex = 16 bytes random
  v_raw := encode(gen_random_bytes(16), 'hex');
  v_token := 'tsmcp_' || v_raw;
  v_hash := encode(digest(v_token, 'sha256'), 'hex');

  IF p_expires_in_days IS NULL THEN
    v_expires := NULL;
  ELSE
    v_expires := now() + (p_expires_in_days || ' days')::interval;
  END IF;

  INSERT INTO public.mcp_tokens (user_id, name, token_hash, expires_at)
  VALUES (v_user_id, p_name, v_hash, v_expires)
  RETURNING mcp_tokens.id INTO v_id;

  RETURN QUERY SELECT v_id, v_token, v_expires;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_mcp_token(TEXT, INTEGER) TO authenticated;

-- ============================================
-- RPC: revoke_mcp_token(id)
-- ============================================
CREATE OR REPLACE FUNCTION public.revoke_mcp_token(p_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.mcp_tokens
  SET revoked_at = now()
  WHERE id = p_id AND user_id = auth.uid() AND revoked_at IS NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public.revoke_mcp_token(UUID) TO authenticated;

-- ============================================
-- RPC: resolve_mcp_token(token) -> user_id
-- Appelée par le serveur MCP avec la clé service-role.
-- Met à jour last_used_at, retourne le user_id si valide.
-- ============================================
CREATE OR REPLACE FUNCTION public.resolve_mcp_token(p_token TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hash TEXT;
  v_user_id UUID;
  v_token_id UUID;
BEGIN
  v_hash := encode(digest(p_token, 'sha256'), 'hex');

  SELECT id, user_id INTO v_token_id, v_user_id
  FROM public.mcp_tokens
  WHERE token_hash = v_hash
    AND revoked_at IS NULL
    AND (expires_at IS NULL OR expires_at > now())
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  UPDATE public.mcp_tokens SET last_used_at = now() WHERE id = v_token_id;
  RETURN v_user_id;
END;
$$;

-- pgcrypto est nécessaire pour digest() et gen_random_bytes()
CREATE EXTENSION IF NOT EXISTS pgcrypto;
