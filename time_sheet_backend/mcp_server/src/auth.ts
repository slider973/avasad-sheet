import { supabase } from './supabase.js';

export interface AuthContext {
  userId: string;
}

// Valide un Personal Access Token via la RPC resolve_mcp_token.
// Renvoie null si le token est absent, révoqué, expiré, ou inexistant.
export async function resolveToken(token: string): Promise<AuthContext | null> {
  if (!token || !token.startsWith('tsmcp_')) return null;
  const { data, error } = await supabase().rpc('resolve_mcp_token', {
    p_token: token,
  });
  if (error || !data) return null;
  return { userId: data as string };
}

export function extractBearer(header: string | undefined): string | null {
  if (!header) return null;
  const m = /^Bearer\s+(.+)$/i.exec(header.trim());
  return m ? m[1].trim() : null;
}
