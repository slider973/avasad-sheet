import { useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'

export function useAuth() {
  const { session, profile, isLoading, role, isManager, setSession, setProfile, setLoading, reset } =
    useAuthStore()

  const fetchProfile = useCallback(
    async (userId: string) => {
      const { data } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single()
      if (data) setProfile(data)
    },
    [setProfile]
  )

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      if (session?.user) {
        fetchProfile(session.user.id)
      }
      setLoading(false)
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
      if (session?.user) {
        fetchProfile(session.user.id)
      } else {
        reset()
      }
    })

    return () => subscription.unsubscribe()
  }, [setSession, setLoading, fetchProfile, reset])

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    return { error }
  }

  const signOut = async () => {
    await supabase.auth.signOut()
    reset()
  }

  return { session, profile, isLoading, role, isManager, signIn, signOut }
}

export function useRequireAuth() {
  const { session, isLoading } = useAuthStore()
  const navigate = useNavigate()

  useEffect(() => {
    if (!isLoading && !session) {
      navigate('/login', { replace: true })
    }
  }, [session, isLoading, navigate])

  return { session, isLoading }
}
