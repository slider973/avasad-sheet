import { useRef, useEffect, useCallback } from 'react'
import SignaturePad from 'signature_pad'
import { Button } from '@/components/ui/button'

interface SignatureCanvasProps {
  onSignatureChange: (data: string | null) => void
  height?: number
  disabled?: boolean
}

export function SignatureCanvas({
  onSignatureChange,
  height = 200,
  disabled = false,
}: SignatureCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const padRef = useRef<SignaturePad | null>(null)

  useEffect(() => {
    if (!canvasRef.current) return

    const canvas = canvasRef.current
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    canvas.width = canvas.offsetWidth * ratio
    canvas.height = canvas.offsetHeight * ratio
    canvas.getContext('2d')?.scale(ratio, ratio)

    const pad = new SignaturePad(canvas, {
      backgroundColor: 'rgb(255, 255, 255)',
      penColor: 'rgb(0, 0, 0)',
    })

    if (disabled) {
      pad.off()
    }

    pad.addEventListener('endStroke', () => {
      if (!pad.isEmpty()) {
        const dataUrl = pad.toDataURL('image/png')
        // Strip the data:image/png;base64, prefix
        const base64 = dataUrl.split(',')[1]
        onSignatureChange(base64)
      }
    })

    padRef.current = pad

    return () => {
      pad.off()
    }
  }, [disabled, onSignatureChange])

  const handleClear = useCallback(() => {
    padRef.current?.clear()
    onSignatureChange(null)
  }, [onSignatureChange])

  return (
    <div className="space-y-2">
      <div className="border rounded-lg overflow-hidden bg-white">
        <canvas
          ref={canvasRef}
          style={{ width: '100%', height: `${height}px`, touchAction: 'none' }}
        />
      </div>
      {!disabled && (
        <div className="flex justify-end">
          <Button variant="outline" size="sm" type="button" onClick={handleClear}>
            Effacer
          </Button>
        </div>
      )}
    </div>
  )
}
