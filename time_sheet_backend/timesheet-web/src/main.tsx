import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'

// Redirect recovery/invite hash tokens to /set-password before React renders
const hash = window.location.hash.substring(1)
let redirecting = false
if (hash) {
  const params = new URLSearchParams(hash)
  const type = params.get('type')
  if ((type === 'recovery' || type === 'invite') && window.location.pathname !== '/set-password') {
    redirecting = true
    window.location.replace('/set-password' + window.location.hash)
  }
}

if (!redirecting) {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <App />
    </StrictMode>,
  )
}
