import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

/**
 * Rend affichable dans une balise `<img>` une URL du Storage.
 *
 * ⚠️ La passerelle Kong protège tout `/storage/v1/` par le plugin `key-auth`,
 * y compris la route `/object/public/` : sans clé, la réponse est un 401.
 * Une balise `<img>` ne peut pas porter d'en-tête, on passe donc la clé en
 * paramètre d'URL (Kong l'accepte aussi bien qu'en en-tête). La clé anon est
 * déjà publique — elle est embarquée dans le bundle.
 *
 * Retourne `undefined` pour une URL absente, afin de pouvoir la passer
 * directement à `src`.
 */
export function storageImageSrc(url: string | null | undefined): string | undefined {
  if (!url) return undefined
  if (url.includes('apikey=')) return url
  return `${url}${url.includes('?') ? '&' : '?'}apikey=${supabaseAnonKey}`
}
